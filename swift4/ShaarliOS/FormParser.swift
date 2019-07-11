//
//  FormParser.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import Foundation

// internal helper uses libxml2 graceful html parsing
internal func findForms(_ body:Data?, _ encoding:String?) -> [String:FormDict] {
    guard let da = body
        else { return [:] }
    return FormParser().parse(da)
}

// https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/XMLParser.swift#L33
private func decode(_ bytes:UnsafePointer<xmlChar>?) -> String? {
    guard let bytes = bytes
        else { return nil }
    if let (str, _) = String.decodeCString(bytes, as: UTF8.self, repairingInvalidCodeUnits: false) {
        return str
    }
    return nil
}

private struct AttrIterator: IteratorProtocol {
    let atts: UnsafePointer<UnsafePointer<xmlChar>?>?
    let decoder: ((UnsafePointer<xmlChar>?) -> String?)
    var idx = 0

    init(_ atts: UnsafePointer<UnsafePointer<xmlChar>?>?, _ decoder: @escaping ((UnsafePointer<xmlChar>?) -> String?)) {
        self.atts = atts
        self.decoder = decoder
    }

    mutating func next() -> (String?)? {
        guard let atts = atts else { return nil }
        let ret = decoder(atts[idx])
        if ret == nil && 0 == (idx % 2) {
            return nil
        }
        idx += 1
        return (ret)
    }
}

// iterate over attributes and pull out name and value attribute values
internal func nameAndValue(_ next: (()->(String?)?)) -> (name: String, value: String?) {
    var name = ""
    var valu:String? = nil
    while let n = next() {
        guard let v = next() else {
            return ("","") // or throw an error?
        }

        // print("attribute", n, "=", v)
        switch n {
        case "id":
            if name.isEmpty {
                name = v!
            }
        case "name":
            name = v!
        case "value":
            valu = v
/*        case "data-list":
            // workaround for 'modern' shaarli not bothering to fill the "value" attribute, but rather rely on javascript to do so.
            // sigh.
            if valu.isEmpty {
                valu = v
            }
 */
        default:
            break
        }
    }

    // print("nameAndValue", name, "=", valu)
    return (name, valu)
}

private class FormParser {
    private var forms : [String:FormDict] = [:]
    private var form : FormDict = [:]
    private var formName = ""
    private var textName = ""
    private var text = ""

    func parse(_ data:Data) -> [String:FormDict] {
        var sax = htmlSAXHandler()
        sax.initialized = XML_SAX2_MAGIC
        sax.startElement = startElementSAX // could this be closures?
        sax.endElement = endElementSAX
        sax.characters = charactersFoundSAX
        // handler.error = errorEncounteredSAX

        // https://curl.haxx.se/libcurl/c/htmltitle.html
        // http://xmlsoft.org/html/libxml-HTMLparser.html#htmlParseChunk
        // https://stackoverflow.com/questions/41140050/parsing-large-xml-from-server-while-downloading-with-libxml2-in-swift-3
        // https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/XMLParser.swift#L524
        // http://redqueencoder.com/wrapping-libxml2-for-swift/ bzw. https://github.com/SonoPlot/Swift-libxml
        let ctxt = htmlCreatePushParserCtxt(&sax, Unmanaged.passUnretained(self).toOpaque(), "", 0, "", XML_CHAR_ENCODING_NONE)
        defer { xmlFreeParserCtxt(ctxt) }

        let _ = data.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> Int32 in
            return htmlParseChunk(ctxt, bytes, Int32(data.count), 0)
        }
        htmlParseChunk(ctxt, "", 0, 1)

        return forms
    }

    func startElement(_ name: UnsafePointer<xmlChar>? , _ atts:UnsafePointer<UnsafePointer<xmlChar>?>?) {
        let n = decode(name)
        var it = AttrIterator(atts, decode)
        let next = { it.next() }
        switch n {
        case "form":
            formName = nameAndValue(next).0
            form = [:]
        case "textarea":
            textName = nameAndValue(next).0
            text = ""
        case "input":
            let nv = nameAndValue(next)
            form[nv.0] = nv.1
        default:
            break
        }
    }

    func endElement(_ name:UnsafePointer<xmlChar>?) {
        let n = decode(name)
        switch n {
        case "form":
            forms[formName] = form
            formName = ""
        case "textarea":
            form[textName] = text
            textName = ""
        default:
            break
        }
    }

    func charactersFound(_ ch: UnsafePointer<xmlChar>?, _ len: CInt) {
        if (textName.isEmpty) {
            return
        }
        let d = Data(bytes: ch!, count:Int(len))
        let s = String(data: d, encoding: .utf8) ?? "<utf8 decoding issue>"
        text.append(s)
    }
}

private func startElementSAX(_ ctx: UnsafeMutableRawPointer?,
                             _ name: UnsafePointer<xmlChar>?,
                             _ attributes: UnsafeMutablePointer<UnsafePointer<xmlChar>?>?) {
    let parser = Unmanaged<FormParser>.fromOpaque(ctx!).takeUnretainedValue()
    parser.startElement(name, attributes)
}

private func endElementSAX(_ ctx: UnsafeMutableRawPointer?, name: UnsafePointer<xmlChar>?) {
    let parser = Unmanaged<FormParser>.fromOpaque(ctx!).takeUnretainedValue()
    parser.endElement(name)
}

private func charactersFoundSAX(_ ctx: UnsafeMutableRawPointer?, ch: UnsafePointer<xmlChar>?, len: CInt) {
    let parser = Unmanaged<FormParser>.fromOpaque(ctx!).takeUnretainedValue()
    parser.charactersFound(ch, len)
}
