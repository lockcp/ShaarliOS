//
//  SettingsVC.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 21.02.20.
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

class SettingsVC: UITableViewController, UIWebViewDelegate {
    @IBOutlet var txtEndpoint : UITextField?
    @IBOutlet var swiSecure : UISwitch?
    @IBOutlet var txtUserName : UITextField?
    @IBOutlet var txtPassWord : UITextField?
    @IBOutlet var lblDefaultPrivate : UILabel?
    @IBOutlet var swiPrivateDefault : UISwitch?
    @IBOutlet var lblTitle : UILabel?
    @IBOutlet var swiTags : UISwitch?
    @IBOutlet var txtTags : UITextField?
    @IBOutlet var spiLogin : UIActivityIndicatorView?
    
    // https://github.com/AgileBits/onepassword-app-extension#use-case-1-native-app-login
    @IBOutlet var btn1Password : UIButton?
    
    @IBOutlet var cellAbout : UITableViewCell?
    @IBOutlet var wwwAbout : UIWebView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let spiLogin = spiLogin else { return }
        guard let wwwAbout = wwwAbout else { return }
        guard let btn1Password = btn1Password else { return }
        guard let url = Bundle(for: type(of:self)).url(forResource:"about", withExtension:"html") else { return }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        tableView.addSubview(spiLogin)

        wwwAbout.scrollView.isScrollEnabled = false
        wwwAbout.scrollView.bounces = false
        wwwAbout.loadRequest(URLRequest.init(url: url))
        
        btn1Password.isEnabled = false // [[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
        btn1Password.alpha = btn1Password.isEnabled ? 1.0 : 0.5;
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let spiLogin = spiLogin else { return }

        spiLogin.stopAnimating()
        
        title = NSLocalizedString("Settings", comment:"SettingsVC")
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target:self, action:#selector(SettingsVC.actionCancel(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target:self, action:#selector(SettingsVC.actionSignIn(_:)))
        /*
        self.lblTitle.text = self.shaarli.title;
        self.lblTitle.textColor = self.lblTitle.text ? self.txtUserName.textColor : [UIColor redColor];
        self.lblTitle.text = self.lblTitle.text ? self.lblTitle.text : NSLocalizedString(@"Not connected yət.", @"SettingsVC");
        
        self.txtEndpoint.text = self.shaarli.endpointStr;
        self.swiSecure.on = self.shaarli.endpointSecure;
        self.swiSecure.enabled = NO;
        self.txtUserName.text = self.shaarli.userName;
        self.txtPassWord.text = self.shaarli.passWord;
        self.swiPrivateDefault.on = self.shaarli.privateDefault;
        self.swiTags.on = self.shaarli.tagsActive;
        self.txtTags.text = self.shaarli.tagsDefault;
        
        [self.spiLogin stopAnimating];
        
        self.title = NSLocalizedString(@"Settings", @"SettingsVC");
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionCancel:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionSignIn:)];
*/
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func actionCancel(_ sender: Any) {
        print("actionCancel \(type(of: self))")
        guard let navigationController = navigationController else { return }
        navigationController.popViewController(animated:true)
    }

    @IBAction func actionSignIn(_ sender: Any) {
        print("actionSignIn \(type(of: self))")
        guard let navigationController = navigationController else { return }
        navigationController.popViewController(animated:true)
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        let ver = AppDelegate.shared.semver
        let ret = webView.stringByEvaluatingJavaScript(from: "injectVersion('\(ver)');")
        print(ret as Any)
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        guard let url = request.url else { return false }
        guard let scheme = url.scheme, scheme == "file" else { return false }
        // let sha = UIApplication.shared
        // if sha.canOpenURL(url) { return sha.openURL(url) }
        return true
    }
}
