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

let KEY_PAR_POST = "post"

let NAME_LOGIN_FORM = "loginform"
let KEY_FORM_LOGIN = "login"
let KEY_FORM_PASSWORD = "password"

// Not fully compliant https://useyourloaf.com/blog/how-to-percent-encode-a-url-string/
// https://stackoverflow.com/a/50116064
func formString(_ form: [URLQueryItem]) -> String {
    var uc = URLComponents()
    uc.queryItems = form
    return uc.percentEncodedQuery!
}

func formQueryItems(_ form: [String:String]) -> [URLQueryItem] {
    var qi :[URLQueryItem] = []
    for (k, v) in form {
        qi.append(URLQueryItem(name: k, value: v))
    }
    return qi
}

func formData(_ form:[String:String]) -> Data {
    return formString(formQueryItems(form)).data(using: .ascii)!
}

class ShaarliHtmlClient {

    func probe(_ endpoint: URL, _ ping: String, _ completion: @escaping (_ url:URL, _ pong:String, _ error:String)->()) {
        let ses = URLSession.shared
        // remove uid+pwd from endpoint url
        var uc = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)!
        uc.user = nil
        uc.password = nil
        var qi = uc.queryItems ?? []
        qi.append(URLQueryItem(name: KEY_PAR_POST, value: ping))
        uc.queryItems = qi

        var req0 = URLRequest(url:uc.url!)
        req0.addValue(VAL_HEAD_USER_AGENT, forHTTPHeaderField:KEY_HEAD_USER_AGENT)

        // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
        let t0 = ses.dataTask(with: req0) { data, response, erro in
            if let erro = erro {
                completion(URLEmpty, "", erro.localizedDescription)
                return
            }
            guard let http = response as? HTTPURLResponse,
                (200...299).contains(http.statusCode) else {
                    completion(URLEmpty, "", String(format:"Expected status 200, got %@", response ?? "<nil>"))
                    return
            }
            guard var lofo = findForms(data, "utf-8")[NAME_LOGIN_FORM] else {
                completion(http.url!, "", NAME_LOGIN_FORM + " not found")
                return
            }
            lofo[KEY_FORM_LOGIN] = endpoint.user
            lofo[KEY_FORM_PASSWORD] = endpoint.password

            var req1 = URLRequest(url:http.url!)
            req1.httpMethod = HTTP_POST
            req1.setValue(VAL_HEAD_CONTENT_TYPE, forHTTPHeaderField:KEY_HEAD_CONTENT_TYPE)
            let formDat = formData(lofo)
            let t1 = ses.uploadTask(with: req1, from: formDat) { data, response, erro in
                if let erro = erro {
                    completion(URLEmpty, "", erro.localizedDescription)
                    return
                }
                guard let http = response as? HTTPURLResponse,
                    (200...299).contains(http.statusCode) else {
                        completion(URLEmpty, "", String(format:"Expected status 200, got %@", response ?? "<nil>"))
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
