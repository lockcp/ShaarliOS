//
//  FormParser.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import Foundation

// internal helper uses libxml2 graceful html parsing
func findForms(_ body:Data?, _ encoding:String?) -> [String:FormDict] {
    guard let da = body else {
        return [:]
    }
    return FormParser().parse(da)
}

// turn a nil-terminated list of name=value pairs into a dictionary
// expand abbreviated (html5) attribute values.
func atts2dict(_ atts: ((Int) -> String?)) -> FormDict {
    var ret:FormDict = [:]
    var idx = 0
    while let name = atts(idx) {
        ret[name] = atts(idx+1) ?? name
        idx += 2
    }
    return ret
}

// https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/XMLParser.swift#L33
private func decode(_ bytes:UnsafePointer<xmlChar>?) -> String? {
    guard let bytes = bytes else {
        return nil
    }
    if let (str, _) = String.decodeCString(bytes, as: UTF8.self, repairingInvalidCodeUnits: false) {
        return str
    }
    return nil
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
        guard let atts = atts else { return }
        guard let elm = decode(name), elm == "form" || elm == "textarea" || elm == "input" else { return }
        let att = atts2dict({ decode(atts[$0]) })
        let nam = att["name"] ?? att["id"] ?? ""
        switch elm {
        case "form":
            formName = nam
            form = [:]
        case "textarea":
            textName = nam
            text = ""
        case "input":
            form[nam] = "checkbox" == att["type"]
                ? (att["checked"] == "off" ? nil : att["checked"])
                : att["value"]
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
