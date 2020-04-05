//
//  SettingsVC.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 21.02.20.
//  Copyright © 2020-2020 Marcus Rohrmoser mobile Software http://mro.name/me. All rights reserved.
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

class SettingsVC: UITableViewController, UITextFieldDelegate, WKNavigationDelegate {
    @IBOutlet var txtEndpoint       : UITextField!
    @IBOutlet var swiSecure         : UISwitch!
    @IBOutlet var txtUserName       : UITextField!
    @IBOutlet var txtPassWord       : UITextField!
    @IBOutlet var lblDefaultPrivate : UILabel!
    @IBOutlet var swiPrivateDefault : UISwitch!
    @IBOutlet var lblTitle          : UILabel!
    @IBOutlet var swiTags           : UISwitch!
    @IBOutlet var txtTags           : UITextField!
    @IBOutlet var spiLogin          : UIActivityIndicatorView!
    @IBOutlet var cellAbout         : UITableViewCell!
    // https://github.com/AgileBits/onepassword-app-extension#use-case-1-native-app-login
    @IBOutlet var btn1Password      : UIButton!

    let wwwAbout                    = WKWebView()
    var current                     : BlogM?

    // MARK: - Lifecycle

    // https://www.objc.io/blog/2018/04/24/bindings-with-kvo-and-keypaths/
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Settings", comment:String(describing:type(of:self)))
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target:self, action:#selector(SettingsVC.actionCancel(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target:self, action:#selector(SettingsVC.actionSignIn(_:)))

        swiSecure.isEnabled     = false

        view.addSubview(spiLogin)
        spiLogin.frame = view.bounds

        // view.addConstraint(NSLayoutConstraint(item:view, attribute:.centerX, relatedBy:.equal, toItem:spiLogin, attribute:.centerX, multiplier:1.0, constant:0))
        // view.addConstraint(NSLayoutConstraint(item:view, attribute:.centerY, relatedBy:.equal, toItem:spiLogin, attribute:.centerY, multiplier:1.0, constant:0))

        guard let url = Bundle(for:type(of:self)).url(forResource:"about", withExtension:"html") else { return }
        cellAbout.contentView.addSubview(wwwAbout)
        wwwAbout.navigationDelegate = self
        wwwAbout.frame = cellAbout!.contentView.bounds.insetBy(dx: 8, dy: 8)
        wwwAbout.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wwwAbout.contentScaleFactor = 1.0
        wwwAbout.scrollView.isScrollEnabled = false
        wwwAbout.scrollView.bounces = false
        wwwAbout.isOpaque = false // avoid white flash https://stackoverflow.com/a/15670274
        wwwAbout.backgroundColor = .black
        wwwAbout.customUserAgent = SHAARLI_COMPANION_APP_URL
        wwwAbout.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())

        btn1Password.isEnabled = false // [[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
        btn1Password.alpha = btn1Password.isEnabled
            ? 1.0
            : 0.5
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        spiLogin.stopAnimating()
        txtEndpoint.becomeFirstResponder()
        togui(current)
    }

    private func togui(_ b : BlogM?) {
        guard let b = b else {
            lblTitle.text = NSLocalizedString("No Shaarli yet.", comment:String(describing:type(of:self)))
            lblTitle.textColor = .red
            return
        }

        lblTitle.text = b.title;
        lblTitle.textColor = txtUserName.textColor

        let uc = URLComponents(url:b.endpoint, resolvingAgainstBaseURL:true)
        txtUserName.text        = uc?.user
        txtPassWord.text        = uc?.password
        txtEndpoint.text        = b.endpointStrNoScheme
        swiSecure.isOn          = b.isEndpointSecure

        swiPrivateDefault.isOn  = b.privateDefault
        swiTags.isOn            = b.tagsActive
        txtTags.text            = "" == b.tagsDefault
            ? b.tagsDefault
            : "\(b.tagsDefault) "
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? MainVC else {return}
        vc.current = current
    }

    // MARK: - Actions

    @IBAction func actionCancel(_ sender: Any) {
        print("actionCancel \(type(of: self))")
        guard let navigationController = navigationController else { return }
        navigationController.popViewController(animated:true)
    }

    @IBAction func actionSignIn(_ sender: Any) {
        print("actionSignIn \(type(of: self))")

        spiLogin.startAnimating()
        lblTitle.text = NSLocalizedString("…", comment:String(describing:type(of:self)))
        lblTitle.textColor = txtUserName.textColor

        let urls = endpoints(txtEndpoint.text, txtUserName.text, txtPassWord.text)
        let c = ShaarliHtmlClient()
        c.probe(urls.first!) {
            return self.handleCallback(c, urls, $0, $1, $2)
        }
    }

    private func endpoints(_ base : String?, _ uid : String?, _ pwd : String?) -> ArraySlice<URL> {
        var urls = ArraySlice<URL>()
        guard let base = base
            else { return urls }
        guard var ep = URLComponents(string:"//\(base)")
            else { return urls }
        ep.user = uid
        ep.password = pwd
        if !ep.path.hasSuffix("/") {
            ep.path = "\(ep.path)/"
        }

        ep.scheme = HTTP_HTTPS; urls.append(ep.url!)
        ep.scheme = HTTP_HTTP;  urls.append(ep.url!)

        return urls
    }

    // MARK: - Controller Logic

    private func handleCallback(_ c:ShaarliHtmlClient, _ urls:ArraySlice<URL>, _ ur: URL, _ ti: String, _ er: String) -> Bool {
        guard let head = urls.first else {return false}
        print("probed '\(head)' -> (\(ur), \(ti), \(er))")

        if er != "" {
            lblTitle.text = er
            lblTitle.textColor = .red
            let tail = urls.dropFirst()
            guard let first = tail.first else {
                spiLogin.stopAnimating()
                return false
            }
            c.probe(first) {
                return self.handleCallback(c, tail, $0, $1, $2)
            }
            return true
        }

        self.success(ur, ti, er)
        return false
    }

    private func success(_ ur:URL, _ ti:String, _ er:String) {
        spiLogin.stopAnimating()
        let b = BlogM(
            endpoint:ur,
            title:ti,
            privateDefault:swiPrivateDefault.isOn,
            tagsActive:swiTags.isOn,
            tagsDefault:txtTags.text ?? ""
        )
        let ad = ShaarliM.shared
        ad.saveBlog(ad.defaults, b)
        current = b
        guard let nav = navigationController else { return }
        nav.popViewController(animated:true)
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn \(type(of: self))")
        switch textField {
        case txtEndpoint: txtUserName.becomeFirstResponder()
        case txtUserName: txtPassWord.becomeFirstResponder()
        case txtPassWord: txtTags.becomeFirstResponder()
        case txtTags: actionSignIn(textField) // keyboard doesn't show 'Done', but just in case... dispatch async?
        default: return false
        }
        return true
    }

    // MARK: - WKWebViewDelegate

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
        let semv = AppDelegate.shared.semver
        let js = "injectVersion('\(semv)');"
        wwwAbout.evaluateJavaScript(js) { res,err in print(err as Any) }
        let s = wwwAbout.scrollView.contentSize
        cellAbout.contentView.bounds = CGRect(origin: .zero, size: s)
    }
}
