//
//  HtmlFormParser.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import Foundation

typealias HtmlFormDict = [String:String]

// internal helper uses libxml2 graceful html parsing
func findHtmlForms(_ body:Data?, _ encoding:String?) -> [String:HtmlFormDict] {
    guard let da = body else {
        return [:]
    }
    return HtmlFormParser().parse(da)
}

// turn a nil-terminated list of unwrapped name,value pairs into a dictionary.
// expand abbreviated (html5) attribute values.
internal func atts2dict(_ atts: (Int) -> String?) -> HtmlFormDict {
    var ret:HtmlFormDict = [:]
    var idx = 0
    while let name = atts(idx) {
        ret[name] = atts(idx+1) ?? name
        idx += 2
    }
    return ret
}

// https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/XMLParser.swift#L33
private func decode(_ bytes:UnsafePointer<xmlChar>?) -> String? {
    guard let bytes = bytes else { return nil }
    guard let (str, _) = String.decodeCString(bytes, as:UTF8.self, repairingInvalidCodeUnits:false) else { return nil }
    return str
}

private func me(_ ptr : UnsafeRawPointer?) -> HtmlFormParser {
    return Unmanaged<HtmlFormParser>.fromOpaque(ptr!).takeUnretainedValue()
}

private class HtmlFormParser {
    private var forms : [String:HtmlFormDict] = [:]
    private var form : HtmlFormDict = [:]
    private var formName = ""
    private var textName = ""
    private var text = ""

    func parse(_ data:Data) -> [String:HtmlFormDict] {
        var sax = htmlSAXHandler()
        sax.initialized = XML_SAX2_MAGIC
        sax.startElement = { me($0).startElement($1, $2) }
        sax.endElement = { me($0).endElement($1) }
        sax.characters = { me($0).charactersFound($1, $2) }
        // handler.error = errorEncounteredSAX

        // https://curl.haxx.se/libcurl/c/htmltitle.html
        // http://xmlsoft.org/html/libxml-HTMLparser.html#htmlParseChunk
        // https://stackoverflow.com/questions/41140050/parsing-large-xml-from-server-while-downloading-with-libxml2-in-swift-3
        // https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/XMLParser.swift#L524
        // http://redqueencoder.com/wrapping-libxml2-for-swift/ bzw. https://github.com/SonoPlot/Swift-libxml
        let ctxt = htmlCreatePushParserCtxt(&sax, Unmanaged.passUnretained(self).toOpaque(), "", 0, "", XML_CHAR_ENCODING_NONE)
        defer { xmlFreeParserCtxt(ctxt) }
        let _ = data.withUnsafeBytes { htmlParseChunk(ctxt, $0, Int32(data.count), 0) }
        htmlParseChunk(ctxt, "", 0, 1)

        return forms
    }

    private func startElement(_ name: UnsafePointer<xmlChar>? , _ atts:UnsafePointer<UnsafePointer<xmlChar>?>?) {
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
                ? ("off" == att["checked"] ? nil : att["checked"])
                : att["value"]
        default:
            break
        }
    }

    private func endElement(_ name:UnsafePointer<xmlChar>?) {
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

    private func charactersFound(_ ch: UnsafePointer<xmlChar>?, _ len: CInt) {
        if (textName.isEmpty) {
            return
        }
        let d = Data(bytes: ch!, count:Int(len)) // clamp
        let s = String(data: d, encoding: .utf8) ?? "<utf8 decoding issue>"
        text.append(s)
    }
}
