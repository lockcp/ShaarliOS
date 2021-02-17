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

    let miss = tadi.filter{ !txke.contains($0.0) }.values.sorted().reduce("") {
        let hashpre = "" == isTag(word:Substring($1))
        ? tpf
        : ""
        let tg = "\(hashpre)\($1)"
        return "" == $0
        ? tg
        : "\($0) \(tg)"
    }
    func trim(_ s:String) -> String { return s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
    return (
        description:trim(ds),
        extended:trim("\(ex)\n\(miss)"),
        tags:tags
    )
}

let URLEmpty = URLComponents().url!

let HTTP_HTTP = "http"
let HTTP_HTTPS = "https"
let HTTP_POST = "POST"
let HTTP_GET = "GET"
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

internal let LOGIN_FORM = "loginform"
internal let KEY_FORM_LOGIN = "login"
internal let KEY_FORM_PASSWORD = "password"

internal let PAT_WRONG_LOGIN = "^<script>alert\\((?:\".*?\"|'.*?')\\);"
private let PAT_BANNED = ">\\s*(\\S.*ou have been banned from logi.*\\S)\\s*<"
private let STR_BANNED = "I said: NO. You are banned for the moment. Go away."

private let LINK_FORM = "linkform"
private let KEY_FORM_TITLE = "title"

private let CFG_FORM = "configform"
private let KEY_FORM_PRIDE = "privateLinkByDefault"
private let KEY_FORM_CONT = "continent"
private let KEY_FORM_CITY = "city"

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

internal func check(_ data: Data?, _ rep: URLResponse?, _ err: Error?) -> (HtmlFormDictDict, String) {
    let fail : HtmlFormDictDict = [:]
    if let err = err {
        return (fail, err.localizedDescription)
    }
    guard let http = rep as? HTTPURLResponse else {
        return (fail, String(format:NSLocalizedString("Not a HTTP response, but %@", comment:"ShaarliHtmlClient"), rep ?? "<nil>"))
    }
    guard (200...299).contains(http.statusCode) else {
        let msg = HTTPURLResponse.localizedString(forStatusCode:http.statusCode)
        // here we loose the knowledge of the http status code.
        return (fail, String(format:NSLocalizedString("Expected response HTTP status '%d %@' but got '%d %@'", comment:"ShaarliHtmlClient"), 200, "Ok", http.statusCode, msg))
    }
    guard let data = data, data.count > 0 else {
        return (fail, NSLocalizedString("Got no data. That's not enough.", comment:"ShaarliHtmlClient"))
    }
    let enco = http.textEncodingName
    let fo = findHtmlForms(data, enco)
    if fo.count == 0 {
        // check several typical error scenarios why there may be no form:
        guard let str = String(bytes: data, encoding: encoding(name:enco)), str.count > 0 else {
            return (fo, NSLocalizedString("Got no data. That's not enough.", comment:"ShaarliHtmlClient"))
        }
        guard STR_BANNED != str else {
            return (fo, STR_BANNED)
        }
        if let ra = str.range(of:PAT_WRONG_LOGIN, options:.regularExpression) {
            let err = String(str[ra]).dropFirst(15).dropLast(3)
            return (fo, String(err))
        }
        if let ra = str.range(of:PAT_BANNED, options:.regularExpression) {
            let err = String(str[ra]).dropFirst(1).dropLast(1).trimmingCharacters(in: .whitespacesAndNewlines)
            return (fo, err)
        }
    }
    return (fo, "")
}

private func createReq(endpoint: URL, params:[URLQueryItem]) -> URLRequest {
    var uc = URLComponents(url:endpoint, resolvingAgainstBaseURL:true)!
    uc.user = nil
    uc.password = nil
    uc.queryItems = params.count == 0
        ? nil
        : params
    return URLRequest(url:uc.url!)
}

class ShaarliHtmlClient {

    static func isOk(_ err: String) -> Bool {
        return err.isEmpty
    }

    let semver : String!

    init(_ semver : String) {
        self.semver = semver
    }

    // prepare the login and be ready for payload - both retrieval and publication.
    // todo https://youtu.be/vDe-4o8Uwl8?t=3090
    internal func loginAndGet(_ ses: URLSession, _ endpoint: URL, _ url: URL, _ callback: @escaping (
        _ action: URL,
        _ lifo: HtmlFormDict,
        _ error: String) -> ()
    ) {
        let req0 = createReq(endpoint: endpoint, params: [URLQueryItem(name: KEY_PAR_POST, value: url.absoluteString)])
        debugPrint("loginAndGet \(req0.httpMethod ?? HTTP_GET)) -> \(req0)")
        // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
        let tsk0 = ses.dataTask(with: req0) { data, response, erro in

            func do_finish(_ lifobase:URL?, _ lifo:HtmlFormDict) {
                guard nil != lifo[LF_URL] else {
                    callback(URLEmpty, [:], String(format:NSLocalizedString("%@ not found.", comment: "ShaarliHtmlClient"), LF_URL))
                    return
                }
                // assume link form action == link form html base url
                callback(lifobase ?? URLEmpty, lifo, "")
            }

            let d = check(data, response, erro)
            debugPrint("loginAndGet \(HTTP_GET) <- \(response?.url ?? URLEmpty) data:'\(d)'")
            guard "" == d.1 else {
                callback(URLEmpty, [:], d.1)
                return
            }

            guard let lifo = d.0[LINK_FORM] else {
                // actually that's what we normally expect: not logged in yet.
                guard var lofo = d.0[LOGIN_FORM] else {
                    callback(URLEmpty, [:], String(format:NSLocalizedString("%@ not found.", comment: "ShaarliHtmlClient"), LOGIN_FORM))
                    return
                }
                if let uc0 = URLComponents(url:endpoint, resolvingAgainstBaseURL:true) {
                    lofo[KEY_FORM_LOGIN] = uc0.user
                    lofo[KEY_FORM_PASSWORD] = uc0.password
                } else {
                    callback(URLEmpty, [:], String(format:NSLocalizedString("Cannot parse endpoint '%@'", comment: "ShaarliHtmlClient"), endpoint.absoluteString))
                    return
                }
                guard let u0 = response?.url else {
                    callback(URLEmpty, [:], String(format:NSLocalizedString("Response not usable.", comment: "")))
                    return
                }
                var req1 = URLRequest(url:u0)
                req1.setValue(VAL_HEAD_CONTENT_TYPE, forHTTPHeaderField:KEY_HEAD_CONTENT_TYPE)
                req1.httpMethod = HTTP_POST
                let formDat = formData(lofo)
                debugPrint("loginAndGet \(req1.httpMethod ?? HTTP_POST) \(req1)")
                let tsk1 = ses.uploadTask(with: req1, from: formDat) { data, response, erro in
                    let d = check(data, response, erro)
                    debugPrint("loginAndGet \(HTTP_POST) <- \(response?.url ?? URLEmpty) data:'\(d)'")
                    guard "" == d.1 else {
                        callback(URLEmpty, [:], d.1)
                        return
                    }
                    guard let lifo = d.0[LINK_FORM] else {
                        callback(URLEmpty, [:], String(format:NSLocalizedString("%@ not found.", comment: "ShaarliHtmlClient"), LINK_FORM))
                        return
                    }
                    do_finish(response?.url, lifo)
                }
                tsk1.resume()
                // print("HTTP \(tsk1.originalRequest?.httpMethod) \(tsk1.originalRequest?.url)")
                return
            }

            do_finish(response?.url, lifo)
            return
        }
        tsk0.resume()
        // print("HTTP \(tsk0.originalRequest?.httpMethod) \(tsk0.originalRequest?.url)")
    }

    private func cfg(_ cfg:URLSessionConfiguration, _ cre: URLCredential?, _ to: TimeInterval) -> URLSessionConfiguration {
        var ret : [String:String] = [:] //"User-Agent":"\(SHAARLI_COMPANION_APP_URL)/\(semver!)"]
        ret["Authorization"] = httpBasic(cre)
        ret["X-Authorization"] = httpBasic(cre)
        cfg.httpAdditionalHeaders = ret
        cfg.allowsCellularAccess = true
        cfg.httpMaximumConnectionsPerHost = 1
        cfg.httpShouldSetCookies = true
        cfg.httpShouldUsePipelining = true
        cfg.timeoutIntervalForRequest = to
        cfg.timeoutIntervalForResource = to
        // cfg.waitsForConnectivity = true
        cfg.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return cfg
    }

    // We need the name of the server. Reliably. So we have to look at ?do=configure.
    // That's where it's in a HTML form.
    // so we pretend to ?post= in order to get past the login and then ?do=configure.
    //
    // The URLCredential are for an optional additional HTTP Basic Auth.
    func probe(_ endpoint: URL, _ cre: URLCredential?,_ to: TimeInterval, _ completion: @escaping (
        _ url:URL,
        _ title:String,
        _ pride:Bool,
        _ tizo:TimeZone?,
        _ error:String) -> Void
    ) {
        debugPrint("probe \(endpoint)")
        let ses = URLSession(configuration:cfg(URLSessionConfiguration.ephemeral, cre, to))

        loginAndGet(ses, endpoint, URLEmpty) { lurl, lifo, err in
            let base = endpoint
            guard ShaarliHtmlClient.isOk(err) else {
                completion(URLEmpty, "", false, nil, err)
                return
            }
            // do not call back yet, but rather call ?do=configure and report the title.
            // do we need the evtl. rewritten endpoint url?
            let req = createReq(endpoint:endpoint, params:[URLQueryItem(name: KEY_PAR_DO, value: CMD_DO_CFG)])
            let tsk = ses.dataTask(with: req) { data, response, err in
                let res = check(data, response, err)
                guard "" == res.1 else {
                    completion(URLEmpty, "", false, nil, res.1)
                    return
                }
                guard let cffo = res.0[CFG_FORM] else {
                    completion(URLEmpty, "", false, nil, String(format:NSLocalizedString("%@ not found.", comment: "ShaarliHtmlClient"), CFG_FORM))
                    return
                }
                let tizo = TimeZone(identifier:"\(cffo[KEY_FORM_CONT] ?? "")/\(cffo[KEY_FORM_CITY] ?? "")")
                completion(base, cffo[KEY_FORM_TITLE] ?? "", cffo[KEY_FORM_PRIDE] != nil, tizo, "")
            }
            tsk.resume()
        }
    }

    func get(_ endpoint: URL, _ cre: URLCredential?, _ to: TimeInterval, _ url: URL, _ completion: @escaping (
        _ ses: URLSession,
        _ action:URL,
        _ ctx: HtmlFormDict,
        _ url:URL,
        _ description: String,
        _ extended: String,
        _ tags: Set<String>,
        _ privat: Bool,
        _ error: String)->()
    ) {
        let ses = URLSession(configuration:cfg(URLSessionConfiguration.ephemeral, cre, to))

        loginAndGet(ses, endpoint, url) { action, lifo, err in
            let tags = (lifo[LF_TGS] ?? "").replacingOccurrences(of: ",", with: " ").split(separator:" ").map { String($0) }
            completion(
                ses,
                action,
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
    func add(_ ses: URLSession,
         _ action: URL,
         _ ctx: HtmlFormDict,
         _ url:URL,
         _ description: String,
         _ extended: String,
         _ tags: Set<String>,
         _ privat: Bool,
         _ completion: @escaping (_ error: String) -> ()
    ) {
        var lifo = ctx
        lifo[LF_URL] = url.absoluteString
        lifo[LF_TIT] = description
        lifo[LF_DSC] = extended
        lifo[LF_TGS] = tags.joined(separator: " ")
        lifo[LF_PRI] = privat
            ? VAL_ON
            : nil
        lifo["save_edit"] = "Save"
        lifo["cancel_edit"] = nil
        lifo["delete_link"] = nil
        var req = createReq(endpoint:action, params:[])
        req.setValue(VAL_HEAD_CONTENT_TYPE, forHTTPHeaderField:KEY_HEAD_CONTENT_TYPE)
        req.httpMethod = HTTP_POST
        let foda = formData(lifo)
        debugPrint("-> \(req.httpMethod ?? "?") \(req.url ?? URLEmpty) data:\(String(data:foda, encoding:.utf8) ?? "-")")
        let tsk = ses.uploadTask(with: req, from: foda) { data, response, err in
            debugPrint("<- \(HTTP_POST) \(response?.url ?? URLEmpty) data:\(data == nil ? "-" : String(data:data!, encoding:.utf8) ?? ""))")
            let res = check(data, response, err)
            completion(res.1)
        }
        tsk.resume()
        // print("HTTP", tsk.originalRequest?.httpMethod, tsk.originalRequest?.url)
    }
}

/*
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
*/
