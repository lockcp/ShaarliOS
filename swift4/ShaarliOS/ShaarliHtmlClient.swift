//
//  ShaarliHtmlClient.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import Foundation

let BUNDLE_ID = "name.mro.ShaarliOS"
let URLEmpty = URLComponents().url!

let HTTP_POST = "POST"
let KEY_HEAD_USER_AGENT = "User-Agent"
let VAL_HEAD_USER_AGENT = "http://app.mro.name/ShaarliOS"
let KEY_HEAD_CONTENT_TYPE = "Content-Type"
let VAL_HEAD_CONTENT_TYPE = "application/x-www-form-urlencoded"

let LF_URL = "lf_url"
let LF_TIT = "lf_title"
let LF_DSC = "lf_description"
let LF_TGS = "lf_tags"
let LF_PRI = "lf_private"
//let LF_TIM = "lf_linkdate"

// Not fully compliant https://useyourloaf.com/blog/how-to-percent-encode-a-url-string/
// https://stackoverflow.com/a/50116064
func formString(_ form: [URLQueryItem]) -> String {
    var uc = URLComponents()
    uc.queryItems = form
    return uc.percentEncodedQuery!
}

func formData(_ form:FormDict) -> Data {
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

class ShaarliHtmlClient {
    static let KEY_PAR_POST = "post"
    static let KEY_PAR_DESC = "description"

    static let LOGIN_FORM = "loginform"
    static let KEY_FORM_LOGIN = "login"
    static let KEY_FORM_PASSWORD = "password"

    static let PAT_WRONG_LOGIN = "^<script>alert\\((?:\".*?\"|'.*?')\\);"
    static let STR_BANNED = "I said: NO. You are banned for the moment. Go away."

    static let LINK_FORM = "linkform"

    // prepare the login and be ready for payload - both retrieval and publication.
    internal func loginAndGet(_ ses: URLSession, _ endpoint: URL, _ url: URL, _ callback: @escaping (
        _ lifo: FormDict,
        _ error: String) -> ()
    ) {
        // remove uid+pwd from endpoint url
        var uc = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)!
        uc.user = nil
        uc.password = nil
        // add payload query items, at least the url
        var qi = uc.queryItems ?? []
        qi.append(URLQueryItem(name: ShaarliHtmlClient.KEY_PAR_POST, value: url.absoluteString))
        uc.queryItems = qi

        var req0 = URLRequest(url:uc.url!)
        req0.setValue(VAL_HEAD_USER_AGENT, forHTTPHeaderField:KEY_HEAD_USER_AGENT)
        
        // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
        let tsk0 = ses.dataTask(with: req0) { data, response, erro in
            let err = check(data, response, erro)
            if err != "" {
                callback([:], err)
                return
            }
            let http = response as! HTTPURLResponse

            let frms = findForms(data, http.textEncodingName)
            guard let lifo = frms[ShaarliHtmlClient.LINK_FORM] else {
                guard var lofo = frms[ShaarliHtmlClient.LOGIN_FORM] else {
                    callback([:], ShaarliHtmlClient.LOGIN_FORM + " not found")
                    return
                }
                lofo[ShaarliHtmlClient.KEY_FORM_LOGIN] = endpoint.user
                lofo[ShaarliHtmlClient.KEY_FORM_PASSWORD] = endpoint.password

                var req1 = URLRequest(url:http.url!)
                req1.httpMethod = HTTP_POST
                req1.setValue(VAL_HEAD_USER_AGENT, forHTTPHeaderField:KEY_HEAD_USER_AGENT)
                req1.setValue(VAL_HEAD_CONTENT_TYPE, forHTTPHeaderField:KEY_HEAD_CONTENT_TYPE)
                let formDat = formData(lofo)
                let tsk1 = ses.uploadTask(with: req1, from: formDat) { data, response, erro in
                    let err = check(data, response, erro)
                    if err != "" {
                        callback([:], err)
                        return
                    }
                    let http = response as! HTTPURLResponse
                    let _ = http.mimeType ?? ""
                    // print(String(bytes:data!, encoding:encoding(name:http.textEncodingName)))
                    guard let lifo = findForms(data, http.textEncodingName)[ShaarliHtmlClient.LINK_FORM] else {
                        let enco = encoding(name:http.textEncodingName)
                        let str = String(bytes: data!, encoding:enco) ?? ""
                        if let ra = str.range(of: ShaarliHtmlClient.PAT_WRONG_LOGIN, options:.regularExpression) {
                            let err = String(str[ra]).dropFirst(15).dropLast(3)
                            callback([:], String(err))
                            return
                        }
                        if ShaarliHtmlClient.STR_BANNED == str {
                            callback([:], ShaarliHtmlClient.STR_BANNED)
                            return
                        }

                        callback([:], ShaarliHtmlClient.LINK_FORM + " not found.")
                        return
                    }

                    if nil == lifo[LF_URL] {
                        callback(lifo, LF_URL + " not found.")
                        return
                    }

                    callback(lifo, "")
                }
                tsk1.resume()
                return
            }
            callback(lifo, "")
            return
        }
        tsk0.resume()
    }

    func probe(_ endpoint: URL, _ ping: String, _ completion: @escaping (
        _ url:URL,
        _ pong:String,
        _ error:String)->()
    ) {
        let ses = URLSession.shared
        let url = URLEmpty // URL(string: percentEncode(in: ping)!)!
        loginAndGet(ses, endpoint, url) { lifo, err in
            completion(
                URL(string:lifo[LF_URL] ?? "") ?? URLEmpty,
                lifo[LF_TIT] ?? "",
                err
            )
        }
    }

    func get(_ endpoint: URL, _ url: URL, _ completion: @escaping (
        _ ctx: FormDict,
        _ url:URL,
        _ description: String,
        _ extended: String,
        _ tags: [String],
        _ privat: Bool,
        _ error: String)->()
    ) {
        let ses = URLSession.shared
        loginAndGet(ses, endpoint, url) { lifo, err in
            completion(
                lifo,
                URL(string:lifo[LF_URL] ?? "") ?? URLEmpty,
                lifo[LF_TIT] ?? "",
                lifo[LF_DSC] ?? "",
                (lifo[LF_TGS] ?? "").replacingOccurrences(of: ",", with: " ").split(separator:" ").map { String($0) },
                (lifo[LF_PRI] ?? "off") != "off",
                err
            )
        }
    }

    func add(_ endpoint: URL,
         _ ctx: FormDict,
         _ url:URL,
         _ description: String,
         _ extended: String,
         _ tags: [String],
         _ privat: Bool,
         _ completion: @escaping (_ error: String) -> ()
    ) {
        let ses = URLSession.shared
        var lifo = ctx
        lifo[LF_URL] = url.absoluteString
        lifo[LF_TIT] = description
        lifo[LF_DSC] = extended
        lifo[LF_TGS] = tags.joined(separator: " ")
        lifo[LF_PRI] = privat ? "on" : nil

        var req = URLRequest(url:endpoint)
        req.httpMethod = HTTP_POST
        req.setValue(VAL_HEAD_USER_AGENT, forHTTPHeaderField:KEY_HEAD_USER_AGENT)
        req.setValue(VAL_HEAD_CONTENT_TYPE, forHTTPHeaderField:KEY_HEAD_CONTENT_TYPE)
        let foda = formData(lifo)
        // debugPrint(String(data: foda, encoding: .utf8))
        let tsk = ses.uploadTask(with: req, from: foda) { data, response, err in
            let erro = check(data, response, err)
            completion(erro)
        }
        tsk.resume()
    }
}
