//
//  ShaarliHtmlClient.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019-2020 Marcus Rohrmoser mobile Software http://mro.name/me. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

internal func isEmoji(character: Character?) -> Bool {
    guard let character = character else { return false }
    return isEmoji(rune:character.unicodeScalars.first!)
}

// https://code.mro.name/mro/ShaarliGo/src/c65e142dda32bac7cec02deedc345b8f32a2cf8e/atom.go#L467
// https://stackoverflow.com/a/39425959
internal func isEmoji(rune: UnicodeScalar) -> Bool {
    switch rune.value {
    case
    0x2b50...0x2b50, // star
    0x1F600...0x1F64F, // Emoticons
    0x1F300...0x1F5FF, // Misc Symbols and Pictographs
    0x1F680...0x1F6FF, // Transport and Map
    0x1F1E6...0x1F1FF, // Regional country flags
    0x2600...0x26FF, // Misc symbols
    0x2700...0x27BF, // Dingbats
    0xFE00...0xFE0F, // Variation Selectors
    0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
    0x1f018...0x1f270, // Various asian characters
    0xfe00...0xfe0f, // Variation selector
    0x238c...0x2454, // Misc items
    0x20d0...0x20ff: // Combining Diacritical Marks for Symbols
        return true
    default:
        return false
    }
}

private let tpf = "#"

private let myPunct:CharacterSet = {
    var cs = CharacterSet.punctuationCharacters
    cs.remove(charactersIn:"§†\(tpf)")
    return cs
}()

// https://code.mro.name/mro/ShaarliGo/src/c65e142dda32bac7cec02deedc345b8f32a2cf8e/atom.go#L485
internal func isTag(word: Substring?) -> String {
    guard let word = word else { return "" }
    let tag = word.hasPrefix(tpf)
        ? word.dropFirst()
        : isEmoji(character:word.first)
        ? word
        : ""
    return tag.trimmingCharacters(in: myPunct)
}

internal func tagsFrom(string: String) -> Set<String> {
    let sca = Scanner(string:string)
    var ret = Set<String>()
    // https://news.ycombinator.com/item?id=8822835
    // not https://medium.com/@sorenlind/three-ways-to-enumerate-the-words-in-a-string-using-swift-7da5504f0062
    var word: NSString?
    while sca.scanUpToCharacters(from:CharacterSet.whitespacesAndNewlines, into:&word) {
        ret.insert(isTag(word:word as Substring?))
    }
    ret.remove("")
    return ret
}

internal func fold(lbl:String) -> String {
    let trm = lbl.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    return trm.folding(options: [.diacriticInsensitive, .caseInsensitive], locale:nil)
}

func tagsNormalise(description ds: String, extended ex: String, tags ta: Set<String>, known:Set<String>) -> (description: String, extended: String, tags: Set<String>) {
    func foldr(_ di: inout [String:String], _ tag:String) { di[fold(lbl:tag)] = tag }
    
    let tadi = ta.reduce(into:[:], foldr) // previously declared tags
    let take = tadi.keys

    let txdi = tagsFrom(string:ds).union(tagsFrom(string:ex)).reduce(into:[:], foldr) // factual used tags
    let txke = txdi.keys
    
    let nedi = txdi.filter { !take.contains($0.0) } // used, but undeclared: new
    let tags = ta.union(nedi.values)
    // let kndi = known.reduce(into:[:], foldr) // may be large
    // should we replace values from tags with corresponding from kndi now?

    let miss = tadi.filter{ !txke.contains($0.0) }.values.sorted().reduce("") { "\($0) \(tpf)\($1)" }
    func trim(_ s:String) -> String { return s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
    return (
        description:trim(ds),
        extended:"\(trim(ex))\(miss)",
        tags:tags
    )
}

let URLEmpty = URLComponents().url!

let HTTP_POST = "POST"
let HTTP_GET = "GET"
let KEY_HEAD_USER_AGENT = "User-Agent"
let VAL_HEAD_USER_AGENT = "http://mro.name/ShaarliOS"
let KEY_HEAD_CONTENT_TYPE = "Content-Type"
let VAL_HEAD_CONTENT_TYPE = "application/x-www-form-urlencoded"

let LF_URL = "lf_url"
let LF_TIT = "lf_title"
let LF_DSC = "lf_description"
let LF_TGS = "lf_tags"
let LF_PRI = "lf_private"
//let LF_TIM = "lf_linkdate"
internal let VAL_ON = "on"
internal let VAL_OFF = "off"


private let KEY_PAR_DO = "do"
private let KEY_PAR_POST = "post"
private let KEY_PAR_DESC = "description"
private let CMD_DO_CFG = "configure"

private let LOGIN_FORM = "loginform"
private let KEY_FORM_LOGIN = "login"
private let KEY_FORM_PASSWORD = "password"

internal let PAT_WRONG_LOGIN = "^<script>alert\\((?:\".*?\"|'.*?')\\);"
private let STR_BANNED = "I said: NO. You are banned for the moment. Go away."

private let LINK_FORM = "linkform"
private let KEY_FORM_TITLE = "title"

private let CFG_FORM = "configform"

// Not fully compliant https://useyourloaf.com/blog/how-to-percent-encode-a-url-string/
// https://stackoverflow.com/a/50116064
func formString(_ form: [URLQueryItem]) -> String {
    var uc = URLComponents()
    uc.queryItems = form
    return uc.percentEncodedQuery!
}

func formData(_ form:HtmlFormDict) -> Data {
    let qi = form.map { URLQueryItem(name:$0, value:$1) }
    let str = formString(qi)
    return str.data(using: .ascii)!
}

func encoding(name:String?) -> String.Encoding {
    switch name {
    case "latin1": return .isoLatin1
    case "latin2": return .isoLatin2
    case "cp1250": return .windowsCP1250
    case "cp1251": return .windowsCP1251
    case "cp1252": return .windowsCP1252
    case "cp1253": return .windowsCP1253
    case "cp1254": return .windowsCP1254
    case "ascii": return .ascii
    default: return .utf8
    }
}

internal func check(_ data: Data?, _ rep: URLResponse?, _ err: Error?) -> String {
    if let error = err {
        return error.localizedDescription
    }
    guard let http = rep as? HTTPURLResponse else {
        return String(format:"Not a http reponse, but %@", rep ?? "<nil>")
    }
    if !(200...299).contains(http.statusCode) {
        return String(format:"Expected status 200, got %d", http.statusCode)
    }
    if data?.count == 0 {
        return "Got no data. That's not enough."
    }

    return ""
}

internal func createReq(endpoint: URL, params:[URLQueryItem]) -> URLRequest {
    var uc = URLComponents(url:endpoint, resolvingAgainstBaseURL:true)!
    uc.user = nil
    uc.password = nil
    uc.queryItems = params.count == 0 ? nil : params
    var req = URLRequest(url:uc.url!)
    req.setValue(VAL_HEAD_USER_AGENT, forHTTPHeaderField:KEY_HEAD_USER_AGENT)
    return req
}

class ShaarliHtmlClient {

    // prepare the login and be ready for payload - both retrieval and publication.
    // todo https://youtu.be/vDe-4o8Uwl8?t=3090
    internal func loginAndGet(_ ses: URLSession, _ endpoint: URL, _ url: URL, _ callback: @escaping (
        _ lurl: URL,
        _ lifo: HtmlFormDict,
        _ error: String) -> ()
    ) {
        let req0 = createReq(endpoint: endpoint, params: [URLQueryItem(name: KEY_PAR_POST, value: url.absoluteString)])
        // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
        let tsk0 = ses.dataTask(with: req0) { data, response, erro in
            let err = check(data, response, erro)
            if err != "" {
                callback(URLEmpty, [:], err)
                return
            }
            let http = response as! HTTPURLResponse
            let frms = findHtmlForms(data, http.textEncodingName)
            guard let lifo = frms[LINK_FORM] else {
                // actually that's what we normally expect: not logged in yet.
                guard var lofo = frms[LOGIN_FORM] else {
                    callback(URLEmpty, [:], "\(LOGIN_FORM) not found")
                    return
                }
                lofo[KEY_FORM_LOGIN] = endpoint.user
                lofo[KEY_FORM_PASSWORD] = endpoint.password

                var req1 = URLRequest(url:http.url!)
                req1.setValue(VAL_HEAD_USER_AGENT, forHTTPHeaderField:KEY_HEAD_USER_AGENT)
                req1.setValue(VAL_HEAD_CONTENT_TYPE, forHTTPHeaderField:KEY_HEAD_CONTENT_TYPE)
                req1.httpMethod = HTTP_POST
                let formDat = formData(lofo)
                let tsk1 = ses.uploadTask(with: req1, from: formDat) { data, response, erro in
                    let err = check(data, response, erro)
                    if err != "" {
                        callback(URLEmpty, [:], err)
                        return
                    }
                    let http = response as! HTTPURLResponse
                    let _ = http.mimeType ?? ""
                    // print(String(bytes:data!, encoding:encoding(name:http.textEncodingName)))
                    guard let lifo = findHtmlForms(data, http.textEncodingName)[LINK_FORM] else {
                        let enco = encoding(name:http.textEncodingName)
                        let str = String(bytes: data!, encoding:enco) ?? ""
                        if let ra = str.range(of: PAT_WRONG_LOGIN, options:.regularExpression) {
                            let err = String(str[ra]).dropFirst(15).dropLast(3)
                            callback(URLEmpty, [:], String(err))
                            return
                        }
                        if STR_BANNED == str {
                            callback(URLEmpty, [:], STR_BANNED)
                            return
                        }

                        callback(URLEmpty, [:], "\(LINK_FORM) not found.")
                        return
                    }

                    if nil == lifo[LF_URL] {
                        callback(URLEmpty, lifo, "\(LF_URL) not found.")
                        return
                    }

                    guard var uc = URLComponents(url:response?.url ?? URLEmpty, resolvingAgainstBaseURL:true) else {
                        callback(URLEmpty, lifo, "strange url")
                        return
                    }
                    uc.queryItems = nil
                    uc.user = endpoint.user
                    uc.password = endpoint.password
                    callback(uc.url ?? URLEmpty, lifo, "")
                }
                tsk1.resume()
                // print("HTTP \(tsk1.originalRequest?.httpMethod) \(tsk1.originalRequest?.url)")
                return
            }

            guard var uc = URLComponents(url:response?.url ?? URLEmpty, resolvingAgainstBaseURL:true) else {
                callback(URLEmpty, lifo, "strange url")
                return
            }
            uc.queryItems = nil
            uc.user = endpoint.user
            uc.password = endpoint.password
            callback(uc.url ?? URLEmpty, lifo, "")
            return
        }
        tsk0.resume()
        // print("HTTP \(tsk0.originalRequest?.httpMethod) \(tsk0.originalRequest?.url)")
    }

    // We need the name of the server. Reliably. So we have to look at ?do=configure.
    // That's where it's in a HTML form.
    // so we pretend to ?post= in order to get past the login and then ?do=configure.
    func probe(_ endpoint: URL?, _ completion: @escaping (
        _ url:URL,
        _ title:String,
        _ error:String) -> Bool
    ) {
        guard let endpoint = endpoint else { return }
        let ses = URLSession(configuration: URLSession.shared.configuration)
        ses.reset { }

        func callback(_ url :URL, _ title: String, _ error: String) -> () {
            DispatchQueue.main.async(execute: { let _ = completion(url, title, error) })
            ses.invalidateAndCancel()
        }

        loginAndGet(ses, endpoint, URLEmpty) { lurl, lifo, err in
            if err != "" {
                callback(lurl, "", err)
                return
            }
            // do not call back yet, but rather call ?do=configure and report the title.
            // do we need the evtl. rewritten endpoint url?
            let req = createReq(endpoint:endpoint, params:[URLQueryItem(name: KEY_PAR_DO, value: CMD_DO_CFG)])
            let tsk = ses.dataTask(with: req) { data, response, err in
                let erro = check(data, response, err)
                if erro != "" {
                    callback(lurl, "", erro)
                    return
                }
                let http = response as! HTTPURLResponse
                guard let cffo = findHtmlForms(data, http.textEncodingName)[CFG_FORM] else {
                    callback(lurl, "", "\(CFG_FORM) not found.")
                    return
                }
                callback(
                    lurl,
                    cffo[KEY_FORM_TITLE] ?? "",
                    ""
                )
            }
            tsk.resume()
        }
    }

    func get(_ endpoint: URL, _ url: URL, _ completion: @escaping (
        _ ctx: HtmlFormDict,
        _ url:URL,
        _ description: String,
        _ extended: String,
        _ tags: Set<String>,
        _ privat: Bool,
        _ error: String)->()
    ) {
        let ses = URLSession(configuration: URLSession.shared.configuration)
        ses.reset { }

        loginAndGet(ses, endpoint, url) { _, lifo, err in
            let tags = (lifo[LF_TGS] ?? "").replacingOccurrences(of: ",", with: " ").split(separator:" ").map { String($0) }
            completion(
                lifo,
                URL(string:lifo[LF_URL] ?? "") ?? URLEmpty,
                lifo[LF_TIT] ?? "",
                lifo[LF_DSC] ?? "",
                Set(tags),
                (lifo[LF_PRI] ?? VAL_OFF) != VAL_OFF,
                err
            )
        }
    }

    // Requires a logged-in session as left over by get().
    func add(_ action: URL,
         _ ctx: HtmlFormDict,
         _ url:URL,
         _ description: String,
         _ extended: String,
         _ tags: Set<String>,
         _ privat: Bool,
         _ completion: @escaping (_ error: String) -> ()
    ) {
        let ses = URLSession(configuration: URLSession.shared.configuration)
        ses.reset { }
        
        var lifo = ctx
        lifo[LF_URL] = url.absoluteString
        lifo[LF_TIT] = description
        lifo[LF_DSC] = extended
        lifo[LF_TGS] = tags.joined(separator: " ")
        lifo[LF_PRI] = privat ? VAL_ON : nil

        var req = createReq(endpoint:action, params:[])
        req.setValue(VAL_HEAD_CONTENT_TYPE, forHTTPHeaderField:KEY_HEAD_CONTENT_TYPE)
        req.httpMethod = HTTP_POST
        let foda = formData(lifo)
        debugPrint("\(req.httpMethod ?? "?") \(req.url ?? URLEmpty) data:\(String(data:foda, encoding:.utf8) ?? "-")")
        let tsk = ses.uploadTask(with: req, from: foda) { data, response, err in
            guard let data = data
                else { return completion("Got no response body") }
            debugPrint("response: \(response?.url ?? URLEmpty) data:\(String(data:data, encoding:.utf8) ?? "-")")
            let erro = check(data, response, err)
            completion(erro)
        }
        tsk.resume()
        // print("HTTP", tsk.originalRequest?.httpMethod, tsk.originalRequest?.url)
    }
}

// https://oleb.net/2018/sequence-head-tail/#preserving-the-subsequence-type
extension Sequence {
    var headAndTail: (head: Element, tail: SubSequence)? {
        var first: Element? = nil
        let tail = drop(while: { element in
            if first == nil {
                first = element
                return true
            } else {
                return false
            }
        })
        guard let head = first else {
            return nil
        }
        return (head, tail)
    }
}
