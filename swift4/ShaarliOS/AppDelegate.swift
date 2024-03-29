//
//  AppDelegate.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 09.06.19.
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

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    static let shared = UIApplication.shared.delegate as! AppDelegate

    let semver = info_to_semver(Bundle.main.infoDictionary)

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        UINavigationBar.appearance().barTintColor = .darkGray
        UINavigationBar.appearance().tintColor = ShaarliM.buttonColor
        // UIBarButtonItem.appearance().tintColor = ShaarliM.buttonColor
        UIButton.appearance().tintColor = ShaarliM.buttonColor
        UILabel.appearance(whenContainedInInstancesOf: [SettingsVC.self]).textColor = ShaarliM.labelColor

        let info = Bundle.main.infoDictionary ?? [:]
        assert(BUNDLE_ID == info["CFBundleIdentifier"] as? String, "CFBundleIdentifier")
        let urlt = info["CFBundleURLTypes"] as? [[String:Any]]
        let urls = urlt?[0]["CFBundleURLSchemes"] as? [String]
        assert(SELF_URL_PREFIX == urls?[0], "CFBundleURLTypes"+"/"+"CFBundleURLSchemes")

        // UIView.setAnimationsEnabled(false) // nil != launchOptions[UIApplicationLaunchOptionsURLKey]];

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
