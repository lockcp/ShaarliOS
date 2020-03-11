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
        assert(nil != lblTitle)
        assert(nil != txtEndpoint)
        assert(nil != swiSecure)
        assert(nil != txtUserName)
        assert(nil != txtPassWord)
        assert(nil != swiPrivateDefault)
        assert(nil != lblDefaultPrivate)
        assert(nil != swiTags)
        assert(nil != txtTags)
        assert(nil != wwwAbout?.scrollView)
        assert(nil != cellAbout)
        assert(nil != spiLogin)

        title = NSLocalizedString("Settings", comment:String(describing:type(of:self)))
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target:self, action:#selector(SettingsVC.actionCancel(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target:self, action:#selector(SettingsVC.actionSignIn(_:)))

        swiSecure!.isEnabled     = false

        guard let spiLogin = spiLogin else { return }
        view.addSubview(spiLogin)
        spiLogin.frame = view.bounds
        // view.addConstraint(NSLayoutConstraint(item:view, attribute:.centerX, relatedBy:.equal, toItem:spiLogin, attribute:.centerX, multiplier:1.0, constant:0))
        // view.addConstraint(NSLayoutConstraint(item:view, attribute:.centerY, relatedBy:.equal, toItem:spiLogin, attribute:.centerY, multiplier:1.0, constant:0))

        guard let url = Bundle(for:type(of:self)).url(forResource:"about", withExtension:"html") else { return }
        guard let wwwAbout = wwwAbout else { return }
        wwwAbout.scrollView.isScrollEnabled = false
        wwwAbout.scrollView.bounces = false
        wwwAbout.backgroundColor = view.backgroundColor
        wwwAbout.isOpaque = false // avoid white flash https://stackoverflow.com/a/15670274
        //view.backgroundColor = .black
        wwwAbout.loadRequest(URLRequest.init(url: url))

        guard let btn1Password = btn1Password else { return }
        btn1Password.isEnabled = false // [[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
        btn1Password.alpha = btn1Password.isEnabled
            ? 1.0
            : 0.5
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        spiLogin?.stopAnimating()

        togui(current)
    }

    fileprivate func togui(_ b : BlogM?) {
        guard let lblTitle = lblTitle else { return }
        guard let txtEndpoint = txtEndpoint else { return }
        guard let swiSecure = swiSecure else { return }
        guard let txtUserName = txtUserName else { return }
        guard let txtPassWord = txtPassWord else { return }
        guard let swiPrivateDefault = swiPrivateDefault else { return }
        guard let swiTags = swiTags else { return }
        guard let txtTags = txtTags else { return }

        guard let b = b else {
            lblTitle.text = NSLocalizedString("Not connected yet.", comment:String(describing:type(of:self)))
            lblTitle.textColor = .red
            return
        }

        lblTitle.text = b.title;
        lblTitle.textColor = txtUserName.textColor

        txtEndpoint.text        = b.endpointStrNoScheme
        swiSecure.isOn          = b.isEndpointSecure
        txtUserName.text        = b.endpoint.user
        txtPassWord.text        = b.endpoint.password
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

    @IBAction func actionCancel(_ sender: Any) {
        print("actionCancel \(type(of: self))")
        guard let navigationController = navigationController else { return }
        navigationController.popViewController(animated:true)
    }

    @IBAction func actionSignIn(_ sender: Any) {
        print("actionSignIn \(type(of: self))")
        guard let lblTitle = lblTitle else { return }
        guard let txtEndpoint = txtEndpoint else { return }
        guard let txtUserName = txtUserName else { return }
        guard let txtPassWord = txtPassWord else { return }
        guard let spiLogin = spiLogin else { return }

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
        guard var ep = URLComponents(string:"//\(base ?? "")")
            else { return urls }
        ep.user = uid
        ep.password = pwd
        if !ep.path.hasSuffix("/") {
            ep.path = "\(ep.path)/"
        }

        ep.scheme = "https"; urls.append(ep.url!)
        ep.scheme = "http";  urls.append(ep.url!)

        return urls
    }

    private func handleCallback(_ c:ShaarliHtmlClient, _ urls:ArraySlice<URL>, _ ur: URL, _ ti: String, _ er: String) -> Bool {
        guard let spiLogin = spiLogin else {return false}
        guard let lblTitle = lblTitle else {return false}
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
        guard let swiPrivateDefault = swiPrivateDefault else { return }
        guard let swiTags = swiTags else { return }
        guard let txtTags = txtTags else { return }
        guard let spiLogin = spiLogin else { return }

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

    func webViewDidFinishLoad(_ webView: UIWebView) {
        webView.alpha = 1 // avoid white flash
        let ver = AppDelegate.shared.semver
        let _ = webView.stringByEvaluatingJavaScript(from: "injectVersion('\(ver)');")
        // print(ret as Any)
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        guard let url = request.url else { return false }
        guard let scheme = url.scheme else { return false }
        if scheme == "file" { return true }
        let sha = UIApplication.shared
        if sha.canOpenURL(url) {
           return sha.openURL(url)
        }
        return true
    }
}
