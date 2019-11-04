//
//  AppDelegate.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import UIKit

let BUNDLE_ID = "name.mro.ShaarliOS"
let SELF_URL_PREFIX = "name-mro-shaarlios"
let SHAARLI_COMPANION_APP_URL = "http://mro.name/ShaarliOS"

let green = UIColor.init(hue: 87/360.0, saturation: 0.58, brightness: 0.68, alpha:1)
let green60_64_66 = UIColor.init(hue: 60/360.0, saturation: 0.64, brightness: 0.66, alpha:1)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

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
