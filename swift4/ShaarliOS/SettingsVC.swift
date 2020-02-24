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

class SettingsVC: UITableViewController, UIWebViewDelegate {
    @IBOutlet var txtEndpoint       : UITextField?
    @IBOutlet var swiSecure         : UISwitch?
    @IBOutlet var txtUserName       : UITextField?
    @IBOutlet var txtPassWord       : UITextField?
    @IBOutlet var lblDefaultPrivate : UILabel?
    @IBOutlet var swiPrivateDefault : UISwitch?
    @IBOutlet var lblTitle          : UILabel?
    @IBOutlet var swiTags           : UISwitch?
    @IBOutlet var txtTags           : UITextField?
    @IBOutlet var spiLogin          : UIActivityIndicatorView?
    
    // https://github.com/AgileBits/onepassword-app-extension#use-case-1-native-app-login
    @IBOutlet var btn1Password      : UIButton?
    
    @IBOutlet var cellAbout         : UITableViewCell?
    @IBOutlet var wwwAbout          : UIWebView?
    
    var current : BlogM?

    // https://www.objc.io/blog/2018/04/24/bindings-with-kvo-and-keypaths/
    override func viewDidLoad() {
        super.viewDidLoad()

        addObserver(self, forKeyPath: "current", options:.new , context:nil)
        
        title = NSLocalizedString("Settings", comment:String(describing:type(of:self)))
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target:self, action:#selector(SettingsVC.actionCancel(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target:self, action:#selector(SettingsVC.actionSignIn(_:)))

        guard let spiLogin = spiLogin else { return }
        tableView.addSubview(spiLogin)

        guard let url = Bundle(for:type(of:self)).url(forResource:"about", withExtension:"html") else { return }
        guard let wwwAbout = wwwAbout else { return }
        wwwAbout.scrollView.isScrollEnabled = false
        wwwAbout.scrollView.bounces = false
        wwwAbout.loadRequest(URLRequest.init(url: url))
        
        guard let btn1Password = btn1Password else { return }
        btn1Password.isEnabled = false // [[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
        btn1Password.alpha = btn1Password.isEnabled ? 1.0 : 0.5;

        // wire KVO?
    }

    deinit {
        removeObserver(self, forKeyPath: "current")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print("observeValue \(keyPath)")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        spiLogin?.stopAnimating()

        togui(current)
    }

    private func togui(_ b : BlogM?) {
        guard let lblTitle = lblTitle else { return }
        guard let txtEndpoint = txtEndpoint else { return }
        guard let swiSecure = swiSecure else { return }
        guard let txtUserName = txtUserName else { return }
        guard let txtPassWord = txtPassWord else { return }
        guard let swiPrivateDefault = swiPrivateDefault else { return }
        guard let swiTags = swiTags else { return }
        guard let txtTags = txtTags else { return }

        guard let b = b else {
            lblTitle.textColor = UIColor.red
            lblTitle.text = NSLocalizedString("Not connected yet.", comment:String(describing:type(of:self)))
            return
        }
        
        lblTitle.text = b.title;
        lblTitle.textColor = txtUserName.textColor
        
        txtEndpoint.text = b.endpointStr
        swiSecure.isOn = b.isEndpointSecure
        swiSecure.isEnabled = false
        txtUserName.text = b.endpoint.user
        txtPassWord.text = b.endpoint.password
        swiPrivateDefault.isOn = b.privateDefault
        swiTags.isOn = b.tagsActive
        txtTags.text = b.tagsDefault
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? MainVC else {return}
        vc.current = current
    }

    @IBAction func actionCancel(_ sender: Any) {
        print("actionCancel \(type(of: self))")
        guard let navigationController = navigationController else { return }
        navigationController.popViewController(animated:true)
    }

    @IBAction func actionSignIn(_ sender: Any) {
        print("actionSignIn \(type(of: self))")
        guard let lblTitle = lblTitle else { return }
        guard let txtEndpoint = txtEndpoint else { return }
        guard let swiSecure = swiSecure else { return }
        guard let txtUserName = txtUserName else { return }
        guard let txtPassWord = txtPassWord else { return }
        guard let swiPrivateDefault = swiPrivateDefault else { return }
        guard let swiTags = swiTags else { return }
        guard let txtTags = txtTags else { return }

        // gui -> BlogM -> probe -> display err -> save -> pop

        guard var ep = URLComponents(string:"//" + (txtEndpoint.text ?? "")) else {return}
        ep.scheme = swiSecure.isOn
            ? "https"
            : "http"
        ep.user = txtUserName.text
        ep.password = txtPassWord.text
        if !ep.path.hasSuffix("/") {
            ep.path = ep.path + "/"
        }
        guard let url = ep.url else {return}

        let ad = AppDelegate.shared
        let c = ShaarliHtmlClient()
        guard let nav = navigationController else { return }
        c.probe(url) { (ur, ti, er) in
            print("probed '\(url)' -> (\(ur), \(ti), \(er))")

            if er != "" {
                lblTitle.text = er
                lblTitle.textColor = UIColor.red
                return
            }

            let b = BlogM(
                endpoint:ur,
                title:ti,
                privateDefault:swiPrivateDefault.isOn,
                tagsActive:swiTags.isOn,
                tagsDefault:txtTags.text ?? ""
            )
            ad.saveBlog(ad.defaults, ad.keychain, b)
            self.current = b
            nav.popViewController(animated:true)
        }
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        webView.alpha = 1 // avoid white flash
        let ver = AppDelegate.shared.semver
        let _ = webView.stringByEvaluatingJavaScript(from: "injectVersion('\(ver)');")
        // print(ret as Any)
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        guard let url = request.url else { return false }
        guard let scheme = url.scheme, scheme == "file" else { return false }
        // let sha = UIApplication.shared
        // if sha.canOpenURL(url) { return sha.openURL(url) }
        return true
    }
}
