//
//  CreditsVC.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 15.08.19.
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
import WebKit

// https://www.hackingwithswift.com/articles/112/the-ultimate-guide-to-wkwebview
class CreditsVC: UIViewController, WKNavigationDelegate {

    // https://mro.name/blog/2013/06/git-version-sha-in-ios-apps/
    internal func semver(info:[String:Any]?) -> String {
        let info = info ?? [:]
        let v0 = info["CFBundleShortVersionString"] as? String ?? "?.?"
        let v1 = info["CFBundleVersionGitSHA"] as? String ?? "?"
        return "\(v0)+\(v1)"
    }

    let wv = WKWebView()

    override func viewDidLoad() {
        super.viewDidLoad()
        wv.navigationDelegate = self
        let back = view.backgroundColor
        view = wv
        view.backgroundColor = back
        view.isOpaque = false // avoid white flash https://stackoverflow.com/a/15670274
        //view.backgroundColor = .black
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let url = Bundle.main.url(forResource:"about", withExtension:"html") else {return}
        wv.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {return}
        if "file" == url.scheme {
            decisionHandler(.allow)
            return
        }

        let app = UIApplication.shared
        if #available(iOS 10.0, *) {
            app.open(url)
        } else {
            app.openURL(url)
        }
        decisionHandler(.cancel)
    }

    func webView(_ sender:WKWebView, didFinish:WKNavigation!) {
        // even this late gives a flash sometimes: view.isOpaque = true
        let semv = semver(info:Bundle.main.infoDictionary)
        let js = "injectVersion('\(semv)');"
        wv.evaluateJavaScript(js) { res,err in print(err as Any) }
    }
}
