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

typealias FormDict = [String:String]

let HTTP_POST = "POST"
let KEY_HEAD_USER_AGENT = "User-Agent"
let VAL_HEAD_USER_AGENT = "http://app.mro.name/ShaarliOS"
let KEY_HEAD_CONTENT_TYPE = "Content-Type"
let VAL_HEAD_CONTENT_TYPE = "application/x-www-form-urlencoded"

let LF_URL = "lf_url"
let LF_TIT = "lf_title"
let LF_DSC = "lf_description"
let LF_TGS = "lf_tags"
let LF_TIM = "lf_linkdate"
let LF_PRI = "lf_private"

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
    internal func loginAndGet(_ endpoint: URL, _ url: URL, _ callback: @escaping (_ lifo: FormDict, _ error: String) -> FormDict) {
        let ses = URLSession.shared
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

        let check: (Data?, URLResponse?, Error?) -> String = {
            if let error = $2 {
                return error.localizedDescription
            }
            guard let http = $1 as? HTTPURLResponse else {
                return String(format:"Not a http reponse, but %@", $1 ?? "<nil>")
            }
            if !(200...299).contains(http.statusCode) {
                return String(format:"Expected status 200, got %d", http.statusCode)
            }

            return ""
        }
        
        // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
        let t0 = ses.dataTask(with: req0) { data, response, erro in
            let err = check(data, response, erro)
            if err != "" {
                let _ = callback([:], err)
                return
            }
            let http = response as! HTTPURLResponse

            guard var lofo = findForms(data, http.textEncodingName)[ShaarliHtmlClient.LOGIN_FORM]
                else {
                    let _ = callback([:], ShaarliHtmlClient.LOGIN_FORM + " not found")
                    // completion(http.url!, "", ShaarliHtmlClient.LOGIN_FORM + " not found")
                    return
            }
            lofo[ShaarliHtmlClient.KEY_FORM_LOGIN] = endpoint.user
            lofo[ShaarliHtmlClient.KEY_FORM_PASSWORD] = endpoint.password

            var req1 = URLRequest(url:http.url!)
            req1.httpMethod = HTTP_POST
            req1.setValue(VAL_HEAD_USER_AGENT, forHTTPHeaderField:KEY_HEAD_USER_AGENT)
            req1.setValue(VAL_HEAD_CONTENT_TYPE, forHTTPHeaderField:KEY_HEAD_CONTENT_TYPE)
            let formDat = formData(lofo)
            let t1 = ses.uploadTask(with: req1, from: formDat) { data, response, erro in
                let err = check(data, response, erro)
                if err != "" {
                    let _ = callback([:], err)
                    return
                }
                let http = response as! HTTPURLResponse
                let _ = http.mimeType ?? ""
                // print(String(bytes:data!, encoding:encoding(name:http.textEncodingName)))
                guard let lifo = findForms(data, http.textEncodingName)[ShaarliHtmlClient.LINK_FORM]
                    else {
                        let enco = encoding(name:http.textEncodingName)
                        let str = String(bytes: data!, encoding:enco) ?? ""
                        if let ra = str.range(of: ShaarliHtmlClient.PAT_WRONG_LOGIN, options:.regularExpression) {
                            let err = String(str[ra]).dropFirst(15).dropLast(3)
                            let _ = callback([:], String(err))
                            return
                        }
                        if ShaarliHtmlClient.STR_BANNED == str {
                            let _ = callback([:], ShaarliHtmlClient.STR_BANNED)
                            return
                        }

                        let _ = callback([:], ShaarliHtmlClient.LINK_FORM + " not found.")
                        return
                }

                if nil == lifo[LF_URL] {
                    let _ = callback(lifo, LF_URL + " not found.")
                    return
                }

                // here we have them all for a get. And the post, too.

                // strip post=... query parameter
                var uc = URLComponents(url: http.url!, resolvingAgainstBaseURL: true)!
                var qi = uc.queryItems!
                let li = qi.popLast()!
                uc.queryItems = qi.count == 0 ? nil : qi
                let _ = callback(lifo, "")
            }
            t1.resume()
        }
        t0.resume()
    }

    func probe(_ endpoint: URL, _ ping: String, _ completion: @escaping (_ url:URL, _ pong:String, _ error:String)->()) {
        let url = URLEmpty // URL(string: percentEncode(in: ping)!)!
        loginAndGet(endpoint, url) { lifo, err in
            completion(
                URL(string:lifo[LF_URL] ?? "") ?? URLEmpty,
                lifo[LF_TIT] ?? "",
                err
            )
            return [:]
        }
    }

    func get(_ endpoint: URL, _ url: URL, _ completion: @escaping (
        _ url:URL,
        _ description: String,
        _ extended: String,
        _ tags: [String],
        _ ctx: FormDict,
        _ error: String)->()
        ) {
        loginAndGet(endpoint, url) { lifo, err in
            completion(
                URL(string:lifo[LF_URL] ?? "") ?? URLEmpty,
                lifo[LF_TIT] ?? "",
                lifo[LF_DSC] ?? "",
                (lifo[LF_TGS] ?? "").replacingOccurrences(of: ",", with: " ").split(separator:" ").map { String($0) },
                lifo,
                err
            )
            return [:]
        }
    }

    func add(_ endpoint: URL,
             _ url: URL,
             _ description: String,
             _ extended: String,
             _ ctx: FormDict,
             _ completion: @escaping (_ url:URL, _ error: String)->()) {

    }
}
