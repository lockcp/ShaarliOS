//
//  AppDelegate.swift
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

import UIKit

let BUNDLE_ID = "name.mro.ShaarliOS"
let SELF_URL_PREFIX = "name-mro-shaarlios"
let SHAARLI_COMPANION_APP_URL = "https://mro.name/ShaarliOS"

let green = UIColor.init(hue: 87/360.0, saturation: 0.58, brightness: 0.68, alpha:1)
let green60_64_66 = UIColor.init(hue: 60/360.0, saturation: 0.64, brightness: 0.66, alpha:1)

fileprivate func _version(_ info : [String:Any?]?) -> String {
    guard let info = info else { return "v?.?" }
    guard let version = info["CFBundleShortVersionString"] as! String? else { return "v?.?" } // Marketing
    // guard let version = info["CFBundleVersion"] as! String? else { return "v?.?" }
    guard let gitsha = info["CFBundleVersionGitSHA"] as! String? else { return "v\(version)+?" }
    return "v\(version)+\(gitsha)"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    static let shared = UIApplication.shared.delegate as! AppDelegate

    let semver = _version(Bundle.main.infoDictionary)
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
    private let KEY_endpointURL     = "endpointURL"
    private let KEY_userName        = "userName"
    private let KEY_passWord        = "passWord"
    private let KEY_privateDefault  = "privateDefault"
    private let KEY_tagsActive      = "tagsActive"
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
        let title = prefs.string(forKey:KEY_title)
            ?? NSLocalizedString("My Shaarli", comment:String(describing:type(of:self)))
        let pd = prefs.bool(forKey:KEY_privateDefault)
        let ta = prefs.object(forKey:KEY_tagsActive) != nil
            ? prefs.bool(forKey:KEY_tagsActive)
            : true
        let td = prefs.string(forKey:KEY_tagsDefault)
            ?? "#Shaarli💫"
        return BlogM(endpoint:url, title:title, privateDefault:pd, tagsActive:ta, tagsDefault:td)
    }

    func saveBlog(_ prefs : UserDefaults, _ blog: BlogM) {
        let url = blog.endpoint
        set(url.absoluteString, forKey:KEY_endpointURL) // incl. uid+pwd
        // redundant, legacy:
        set(url.user!, forKey:KEY_userName)
        set(url.password!, forKey:KEY_passWord)

        prefs.set(blog.title, forKey:KEY_title)
        prefs.set(blog.privateDefault, forKey:KEY_privateDefault)
        prefs.set(blog.tagsActive, forKey:KEY_tagsActive)
        prefs.set(blog.tagsDefault, forKey:KEY_tagsDefault)
    }

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        UINavigationBar.appearance().barTintColor = .darkGray
        UINavigationBar.appearance().tintColor = green
        // UIBarButtonItem.appearance().tintColor = green
        UIButton.appearance().tintColor = green

        let info = Bundle.main.infoDictionary ?? [:]
        assert(BUNDLE_ID == info["CFBundleIdentifier"] as? String, "CFBundleIdentifier")
        let urlt = info["CFBundleURLTypes"] as? [[String:Any]]
        let urls = urlt?[0]["CFBundleURLSchemes"] as? [String]
        assert(SELF_URL_PREFIX == urls?[0], "CFBundleURLTypes"+"/"+"CFBundleURLSchemes")

        UIView.setAnimationsEnabled(false) // nil != launchOptions[UIApplicationLaunchOptionsURLKey]];

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
