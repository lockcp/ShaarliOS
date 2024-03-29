//
//  ShaarliM.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 21.02.20.
//  Copyright © 2019-2021 Marcus Rohrmoser mobile Software http://mro.name/me. All rights reserved.
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
import UIKit

let BUNDLE_ID = "name.mro.ShaarliOS"
let BUNDLE_NAME = "#Shaarli💫"
let SELF_URL_PREFIX = BUNDLE_ID
let SHAARLI_COMPANION_APP_URL = "https://mro.name/ShaarliOS"

func info_to_semver(_ info : [String:Any?]?) -> String {
    guard let info = info else { return "v?.?" }
    guard let version = info["CFBundleShortVersionString"] as? String else { return "v?.?" } // Marketing
    // guard let version = info["CFBundleVersion"] as? String else { return "v?.?" }
    guard let gitsha = info["CFBundleVersionGitSHA"] as? String else { return "v\(version)" }
    return "v\(version)+\(gitsha)"
}

// HTTP Basic Auth https://tools.ietf.org/html/rfc7617
//
// Apple URL Loading system is jealous and purges the Authorization header
// on iOS 10 and 12 devices. So we have to resort to use a URLSessionTaskDelegate 
func httpBasic(_ cre: URLCredential?) -> String? {
    guard let cre = cre else { return nil }
    guard cre.user?.count != 0 else { return nil }
    guard cre.hasPassword else { return nil }
    // pre-authenticate HTTP Basic Auth https://tools.ietf.org/html/rfc7617
    // https://gist.github.com/maximbilan/444db1e05babf5b08abae220102fdb8a
    let uidPwd = "\(cre.user ?? ""):\(cre.password ?? "")"
    let b64 = uidPwd.data(using:.utf8)!.base64EncodedString()
    return "Basic \(b64)"
}

// HTTP Basic Auth https://tools.ietf.org/html/rfc7617
//
// empty password is allowed, empty user not.
func httpBasic(_ str: String?) -> URLCredential? {
    // https://gist.github.com/maximbilan/444db1e05babf5b08abae220102fdb8a
    guard let str = str else { return nil }
    guard str.hasPrefix("Basic ") else { return nil }
    let sub = str.suffix(from:.init(utf16Offset:6, in:str))
    guard let dat = Data(base64Encoded:String(sub)) else { return nil }
    guard let up = String(data:dat, encoding:.utf8) else { return nil }
    let arr = up.split(separator:":", maxSplits:1, omittingEmptySubsequences:false)
    return URLCredential(user:String(arr[0]), password:String(arr[1]), persistence:.forSession)
}

struct ShaarliM {

    static let buttonColor  = UIColor.init(hue: 87/360.0, saturation: 0.58, brightness: 0.68, alpha:1)
    static let labelColor   = UIColor.lightText

    static let shared = ShaarliM()

    // how can we ever purge these settings? removePersistentDomain
    let defaults = UserDefaults(suiteName:"group.\(BUNDLE_ID)")!

    /** https://code.mro.name/mro/ShaarliOS/src/e9009ef466582e806b97d723e5acea885eaa4c7d/ios/ShaarliOS/ShaarliM.m#L133
     *
     * # Keychain
     *
     * https://l.mro.name/o/p/a8b2sa5/
     * https://developer.apple.com/library/archive/samplecode/GenericKeychain/Introduction/Intro.html#//apple_ref/doc/uid/DTS40007797
     * https://developer.apple.com/library/archive/samplecode/GenericKeychain/Listings/GenericKeychain_KeychainPasswordItem_swift.html#//apple_ref/doc/uid/DTS40007797-GenericKeychain_KeychainPasswordItem_swift-DontLinkElementID_7
     */
    private func string(forKey:String) -> String? {
        do {
            return try KeychainPasswordItem(service:BUNDLE_ID, account:forKey, accessGroup:nil).readPassword()
        } catch {
            return nil
        }
    }

    private func set(_ val:String, forKey:String) {
        do {
            try KeychainPasswordItem(service:BUNDLE_ID, account:forKey, accessGroup:nil).savePassword(val)
        } catch {
            print("ouch")
        }
    }

    private let KEY_title           = "title"
    private let KEY_auth            = "httpAuth"
    private let KEY_endpointURL     = "endpointURL"
    private let KEY_userName        = "userName"
    private let KEY_passWord        = "passWord"
    private let KEY_timeout         = "timeout"
    private let KEY_privateDefault  = "privateDefault"
    private let KEY_timezone        = "timezone"
    private let KEY_tagsDefault     = "tagsDefault"

    func loadEndpointURL() -> URL? {
        guard let url = string(forKey:KEY_endpointURL)
            ?? string(forKey:"endpointUrl")
            else { return nil }

        guard var uc = URLComponents(string: url)
            else { return nil }
        if uc.user == nil || uc.user == "" {
            uc.user = string(forKey:KEY_userName)
        }
        if uc.password == nil || uc.password == ""  {
            uc.password = string(forKey:KEY_passWord)
        }
        return uc.url
    }

    func loadBlog(_ prefs :UserDefaults) -> BlogM? {
        guard let url = loadEndpointURL() else { return nil }
        let cre = httpBasic(prefs.string(forKey:KEY_auth))
        let title = prefs.string(forKey:KEY_title)
            ?? NSLocalizedString("My Shaarli", comment:String(describing:type(of:self)))
        let to = timeoutFromDouble(prefs.double(forKey:KEY_timeout))
        let pd = prefs.bool(forKey:KEY_privateDefault)
        let tizo = TimeZone(identifier:prefs.string(forKey:KEY_timezone) ?? "")
        let blank = " "
        let td = (prefs.string(forKey:KEY_tagsDefault) ?? "").trimmingCharacters(in:.whitespacesAndNewlines) + blank
        return BlogM(endpoint:url, credential:cre, title:title, timeout:to, privateDefault:pd, timezone:tizo, tagsDefault:blank == td
            ? ""
            : td)
    }

    func saveBlog(_ prefs : UserDefaults, _ blog: BlogM) {
        let url = blog.endpoint
        set(url.absoluteString, forKey:KEY_endpointURL) // incl. uid+pwd
        // redundant, legacy:
        if let uc = URLComponents(url:url, resolvingAgainstBaseURL:true) {
          set(uc.user!, forKey:KEY_userName)
          set(uc.password!, forKey:KEY_passWord)
        }
        prefs.set(httpBasic(blog.credential), forKey:KEY_auth)
        prefs.set(blog.title, forKey:KEY_title)
        prefs.set(blog.timeout, forKey:KEY_timeout)
        prefs.set(blog.privateDefault, forKey:KEY_privateDefault)
        prefs.set(blog.timezone?.identifier, forKey:KEY_timezone)
        prefs.set(blog.tagsDefault.trimmingCharacters(in:.whitespacesAndNewlines), forKey:KEY_tagsDefault)
        prefs.removeObject(forKey:"tagsActive")
    }
}
