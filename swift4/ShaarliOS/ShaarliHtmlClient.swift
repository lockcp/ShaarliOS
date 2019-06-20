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

// Not fully compliant https://useyourloaf.com/blog/how-to-percent-encode-a-url-string/
// https://stackoverflow.com/a/50116064
func formString(_ form: [URLQueryItem]) -> String {
    var uc = URLComponents()
    uc.queryItems = form
    return uc.percentEncodedQuery!
}

func formData(_ form:[String:String]) -> Data {
    let qi = form.map { k,v in URLQueryItem(name:k, value:v) }
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

    static let LOGIN_FORM = "loginform"
    static let KEY_FORM_LOGIN = "login"
    static let KEY_FORM_PASSWORD = "password"

    static let PAT_WRONG_LOGIN = "^<script>alert\\((?:\".*?\"|'.*?')\\);"
    static let STR_BANNED = "I said: NO. You are banned for the moment. Go away."

    static let LINK_FORM = "linkform"
    static let LF_URL = "lf_url"

    func probe(_ endpoint: URL, _ ping: String, _ completion: @escaping (_ url:URL, _ pong:String, _ error:String)->()) {
        let ses = URLSession.shared
        // remove uid+pwd from endpoint url
        var uc = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)!
        uc.user = nil
        uc.password = nil
        var qi = uc.queryItems ?? []
        qi.append(URLQueryItem(name: ShaarliHtmlClient.KEY_PAR_POST, value: ping))
        uc.queryItems = qi

        var req0 = URLRequest(url:uc.url!)
        req0.setValue(VAL_HEAD_USER_AGENT, forHTTPHeaderField:KEY_HEAD_USER_AGENT)

        let check: (Data?, URLResponse?, Error?, String) -> ([String:String],String) = {
            if let error = $2 {
                return ([:], error.localizedDescription)
            }
            guard let http = $1 as? HTTPURLResponse else {
                return ([:], String(format:"Not a http reponse, but %@", $1 ?? "<nil>"))
            }
            if !(200...299).contains(http.statusCode) {
                return ([:], String(format:"Expected status 200, got %d", http.statusCode))
            }
            guard let fo = findForms($0, http.textEncodingName)[$3] else {
                return ([:], $3 + " not found")
            }

            return (fo, "")
        }
        
        // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
        let t0 = ses.dataTask(with: req0) { data, response, erro in
            let ret = check(data, response, erro, ShaarliHtmlClient.LOGIN_FORM)
            if ret.1 != "" {
                completion(URLEmpty, "", ret.1)
                return
            }
            let http = response as! HTTPURLResponse
            var lofo = ret.0
            lofo[ShaarliHtmlClient.KEY_FORM_LOGIN] = endpoint.user
            lofo[ShaarliHtmlClient.KEY_FORM_PASSWORD] = endpoint.password

            var req1 = URLRequest(url:http.url!)
            req1.httpMethod = HTTP_POST
            req1.setValue(VAL_HEAD_USER_AGENT, forHTTPHeaderField:KEY_HEAD_USER_AGENT)
            req1.setValue(VAL_HEAD_CONTENT_TYPE, forHTTPHeaderField:KEY_HEAD_CONTENT_TYPE)
            let formDat = formData(lofo)
            let t1 = ses.uploadTask(with: req1, from: formDat) { data, response, erro in
                let ret = check(data, response, erro, ShaarliHtmlClient.LINK_FORM)
                if ret.1 != "" {
                    completion(URLEmpty, "", ret.1)
                    return
                }
                let http = response as! HTTPURLResponse
                let lifo = ret.0
                if lifo == [:] {
                    let enco = encoding(name:http.textEncodingName)
                    let str = String(bytes: data!, encoding:enco) ?? ""
                    if let ra = str.range(of: ShaarliHtmlClient.PAT_WRONG_LOGIN, options:.regularExpression) {
                        let err = String(str[ra]).dropFirst(15).dropLast(3)
                        completion(URLEmpty, "", String(err))
                        return
                    }
                    if ShaarliHtmlClient.STR_BANNED == str {
                        completion(URLEmpty, "", ShaarliHtmlClient.STR_BANNED)
                        return
                    }

                    completion(URLEmpty, "", ShaarliHtmlClient.LINK_FORM + " not found.")
                    return
                }
                let _ = http.mimeType ?? ""

                if nil == lifo[ShaarliHtmlClient.LF_URL] {
                    completion(URLEmpty, "", ShaarliHtmlClient.LF_URL + " not found.")
                    return
                }

                // strip post=... query parameter
                var uc = URLComponents(url: http.url!, resolvingAgainstBaseURL: true)!
                var qi = uc.queryItems!
                let li = qi.popLast()!
                uc.queryItems = qi.count == 0 ? nil : qi
                completion(uc.url!, li.value!, "")
            }
            t1.resume()
        }
        t0.resume()
    }

    func get(_ endpoint: URL, _ url: URL, _ completion: (
        _ url:URL,
        _ description: String,
        _ extended: String,
        _ ctx: [String:String],
        _ error: String)->()
        ) {

    }

    func add(_ endpoint: URL,
             _ url: URL,
             _ description: String,
             _ extended: String,
             _ ctx: [String:String],
             _ completion: (_ url:URL, _ error: String)->()) {

    }
}
