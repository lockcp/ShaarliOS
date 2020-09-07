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

internal func endpoints(_ base : String?, _ uid : String?, _ pwd : String?) -> ArraySlice<URL> {
    var urls = ArraySlice<URL>()
    guard let base = base?.trimmingCharacters(in:.whitespacesAndNewlines)
        else { return urls }
    let base_ = base.hasPrefix(HTTP_HTTPS + "://")
    ? String(base.dropFirst(HTTP_HTTPS.count+"://".count))
    : base.hasPrefix(HTTP_HTTP + "://")
    ? String(base.dropFirst(HTTP_HTTP.count+"://".count))
    : base.hasPrefix("//")
    ? String(base.dropFirst("//".count))
    : base

    guard var ep = URLComponents(string:"//\(base_)")
        else { return urls }
    ep.user = uid
    ep.password = pwd

    ep.scheme = HTTP_HTTPS; urls.append(ep.url!)
    ep.scheme = HTTP_HTTP;  urls.append(ep.url!)

    let php = "/index.php"
    let pa = ep.path.dropLast(ep.path.hasSuffix(php)
        ? php.count
        : ep.path.hasSuffix("/")
        ? 1
        : 0)

    ep.path = pa + php
    ep.scheme = HTTP_HTTPS; urls.append(ep.url!)
    ep.scheme = HTTP_HTTP;  urls.append(ep.url!)

    return urls
}


class SettingsVC: UITableViewController, UITextFieldDelegate, WKNavigationDelegate {
    @IBOutlet private var txtEndpoint       : UITextField!
    @IBOutlet private var sldTimeout        : UISlider!
    @IBOutlet private var txtTimeout        : UITextField!
    @IBOutlet private var swiSecure         : UISwitch!
    @IBOutlet private var txtUserName       : UITextField!
    @IBOutlet private var txtPassWord       : UITextField!
    @IBOutlet private var lblDefaultPrivate : UILabel!
    @IBOutlet private var swiPrivateDefault : UISwitch!
    @IBOutlet private var lblTitle          : UILabel!
    @IBOutlet private var txtTags           : UITextField!
    @IBOutlet private var spiLogin          : UIActivityIndicatorView!
    @IBOutlet private var cellAbout         : UITableViewCell!

    private let wwwAbout                    = WKWebView()
    var current                             : BlogM?

    // MARK: - Lifecycle

    // https://www.objc.io/blog/2018/04/24/bindings-with-kvo-and-keypaths/
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Settings", comment:"SettingsVC")
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target:self, action:#selector(SettingsVC.actionCancel(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target:self, action:#selector(SettingsVC.actionSignIn(_:)))

        view.addSubview(spiLogin)
        spiLogin.backgroundColor = .clear
        txtTimeout.placeholder = NSLocalizedString("sec", comment:"SettingsVC")
        sldTimeout.minimumValue = Float(timeoutMinimumValue)
        sldTimeout.maximumValue = Float(timeoutMaximumValue)
        sldTimeout.value = Float(timeoutDefaultValue)

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        spiLogin.stopAnimating()
        navigationItem.rightBarButtonItem?.isEnabled = true
        txtEndpoint.becomeFirstResponder()
        togui(current)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        spiLogin.translatesAutoresizingMaskIntoConstraints = false
        let horizontalConstraint = spiLogin.centerXAnchor.constraint(equalTo: lblTitle.centerXAnchor)
        let verticalConstraint = spiLogin.centerYAnchor.constraint(equalTo: lblTitle.centerYAnchor)
        NSLayoutConstraint.activate([horizontalConstraint, verticalConstraint])

        guard let url = UIPasteboard.general.url else {
            return
        }
        let alert = UIAlertController(
            title:NSLocalizedString("Use URL form Clipboard", comment: "SettingsVC"),
            message:String(format:NSLocalizedString("do you want to use the URL\n'%@'\nas shaarli endpoint?", comment:"SettingsVC"), url.description),
            preferredStyle:.alert
        )
        alert.addAction(UIAlertAction(
            title:NSLocalizedString("Cancel", comment:"SettingsVC"),
            style:.cancel,
            handler:nil))
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("Yes", comment:"SettingsVC"),
            style:.default,
            handler:{(_) in self.togui(url)}))
        present(alert, animated:true, completion:nil)
    }

    private func togui(_ ur : URL?) {
        txtUserName.text        = nil
        txtPassWord.text        = nil
        txtEndpoint.text        = nil
        swiSecure.isOn          = false
        guard let ur = ur else { return }
        guard var uc = URLComponents(url:ur, resolvingAgainstBaseURL:true) else { return }
        txtUserName.text        = uc.user
        txtPassWord.text        = uc.password
        swiSecure.isOn          = HTTP_HTTPS == uc.scheme
        uc.password             = nil
        uc.user                 = nil
        uc.scheme               = nil
        guard let su = uc.url?.absoluteString.suffix(from: .init(encodedOffset:2)) else { return }
        txtEndpoint.text        = String(su)
    }

    private func togui(_ b : BlogM?) {
        guard let b = b else {
            lblTitle.text = NSLocalizedString("No Shaarli yet.", comment:"SettingsVC")
            lblTitle.textColor = .red
            return
        }

        lblTitle.text = b.title;
        lblTitle.textColor = txtUserName.textColor

        togui(b.endpoint)

        sldTimeout.value        = Float(b.timeout)
        sldTimeoutChanged(self)
        swiPrivateDefault.isOn  = b.privateDefault
        txtTags.text            = b.tagsDefault
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? MainVC else {return}
        vc.current = current
    }

    // MARK: - Actions

    @IBAction func sldTimeoutChanged(_ sender: Any) {
        txtTimeout.text = String(format:"%.1f", sldTimeout.value)
    }

    @IBAction func actionCancel(_ sender: Any) {
        print("actionCancel \(type(of: self))")
        guard let navigationController = navigationController else { return }
        navigationController.popViewController(animated:true)
    }

    @IBAction func actionSignIn(_ sender: Any) {
        print("actionSignIn \(type(of: self))")

        lblTitle.textColor = txtUserName.textColor
        lblTitle.text = NSLocalizedString("", comment:"SettingsVC")// … probing server …
        spiLogin.startAnimating()

        let cli = ShaarliHtmlClient(AppDelegate.shared.semver)
        let tim = TimeInterval(sldTimeout.value)

        func recurse(_ urls:ArraySlice<URL>) {
            guard let cur = urls.first else {
                self.failure("Oops, something went utterly wrong.")
                return
            }
            cli.probe(cur, tim) { (ur, ti, er) in
                guard !ShaarliHtmlClient.isOk(er) else {
                    self.success(ur, ti, tim)
                    return
                }
                let res = urls.dropFirst()
                let tryNext = !res.isEmpty // todo: and not banned
                guard tryNext else {
                    self.failure(er)
                    return
                }
                recurse(res)
            }
        }

        let urls = endpoints(txtEndpoint.text, txtUserName.text, txtPassWord.text)
        spiLogin.startAnimating()
        navigationItem.rightBarButtonItem?.isEnabled = false
        recurse(urls)
    }

    // MARK: - Controller Logic

    private func success(_ ur:URL, _ ti:String, _ tim:TimeInterval) {
        let ad = ShaarliM.shared
        DispatchQueue.main.sync {
            ad.saveBlog(ad.defaults, BlogM(
                endpoint:ur,
                title:ti,
                timeout:tim,
                privateDefault:swiPrivateDefault.isOn,
                tagsDefault:txtTags.text ?? ""
            ))
            navigationController?.popViewController(animated:true)
        }
    }

    private func failure(_ er:String) {
        DispatchQueue.main.sync {
            spiLogin.stopAnimating()
            navigationItem.rightBarButtonItem?.isEnabled = true
            self.lblTitle.textColor = .red
            self.lblTitle.text = er
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn \(type(of: self))")
        switch textField {
        case txtEndpoint,
             txtTimeout:  txtUserName.becomeFirstResponder()
        case txtUserName: txtPassWord.becomeFirstResponder()
        case txtPassWord: txtTags.becomeFirstResponder()
        case txtTags: actionSignIn(textField) // keyboard doesn't show 'Done', but just in case... dispatch async?
        default: return false
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        print("textFieldShouldReturn \(type(of: self))")
        switch textField {
        case txtTimeout:
                        guard let va = Float(txtTimeout.text ?? "") else {
                            sldTimeout.value = Float(timeoutDefaultValue)
                            sldTimeoutChanged(self)
                            return
                        }
                        sldTimeout.value = Float(timeoutFromDouble(Double(va)))
                        sldTimeoutChanged(self)
        default: break
        }
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
