//
//  MainVC.swift
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
import AudioToolbox

private func play_sound_ok() {
    // https://github.com/irccloud/ios/blob/6e3255eab82be047be141ced6e482ead5ac413f4/ShareExtension/ShareViewController.m#L155
    AudioServicesPlaySystemSound(1001)
}

private func play_sound_err() {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
}

// Reading from private effective user settings. https://stackoverflow.com/a/45280879/349514
class MainVC: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet private var lblVersion    : UILabel!
    @IBOutlet private var lblName       : UILabel!
    @IBOutlet private var centerY       : NSLayoutConstraint!
    @IBOutlet private var vContainer    : UIView!
    @IBOutlet private var btnPetal      : UIButton!
    @IBOutlet private var btnSafari     : UIBarButtonItem!

    @IBOutlet private var viewShaare    : UIView!
    @IBOutlet private var btnShaare     : UIButton!
    @IBOutlet private var txtDescr      : UITextView!
    @IBOutlet private var txtTitle      : UITextField!
    @IBOutlet private var btnAudience   : UIButton!

    // http://spin.atomicobject.com/2014/03/05/uiscrollview-autolayout-ios/
    @IBOutlet private var activeField   : UIView!
    @IBOutlet private var scrollView    : UIScrollView!

    @IBOutlet private var spiPost       : UIActivityIndicatorView!

    var current                 : BlogM?

    @IBAction func actionCancel(_ sender: Any) {
        debugPrint("actionCancel \(type(of: self))")
        guard let b = current else {
            btnShaare.isEnabled = false
            btnSafari.isEnabled = btnShaare.isEnabled
            return
        }

        title = b.title
        spiPost.stopAnimating()
        btnShaare.isEnabled = true // b != nil
        btnSafari.isEnabled = btnShaare.isEnabled
        btnAudience.isSelected = b.privateDefault
        txtTitle.text = ""
        txtDescr.text = b.descPrefix
        // viewShaare.alpha = 1
        txtTitle.becomeFirstResponder()
    }

    @IBAction func actionPost(_ sender: Any) {
        debugPrint("actionPost \(type(of: self))")

        view.bringSubviewToFront(spiPost)
        spiPost.startAnimating()
        btnShaare.isEnabled = !spiPost.isAnimating
        txtDescr.resignFirstResponder()
        txtTitle.resignFirstResponder()

        guard let current = current else { return }
        let srv = current.endpoint
        let tit = txtTitle.text ?? "-"
        let dsc = txtDescr.text ?? "-"
        let pri = btnAudience.isSelected
        let c = ShaarliHtmlClient(AppDelegate.shared.semver)
        c.get(srv, URLEmpty) { ses, ctx, ur_, ti_, de_, ta_, pr_, err in
            guard "" == err else {
                DispatchQueue.main.async {
                    self.reportPostingError(err)
                }
                return
            }
            var ctx = ctx
            ctx.removeValue(forKey: "cancel_edit")
            let r = tagsNormalise(description:tit, extended:dsc, tags:ta_, known:[])
            c.add(ses, srv, ctx, ur_, r.description, r.extended, r.tags, pri) { err in
                DispatchQueue.main.async {
                    guard "" == err else {
                        play_sound_err()
                        self.reportPostingError(err)
                        return
                    }
                    print("set result: '\(ur_)'")
                    play_sound_ok()
                    self.actionCancel(self)
                }
            }
        }
    }

    private func reportPostingError(_ err:String) {
        spiPost.stopAnimating()
        btnShaare.isEnabled = !spiPost.isAnimating
        UIAlertView(title:NSLocalizedString("Sorry, couldn't post", comment:"MainVC"), message:err, delegate:nil, cancelButtonTitle:"OK").show()
    }

    @IBAction func actionSafari(_ sender: Any) {
        debugPrint("actionSafari \(type(of: self))")
        guard let current = current else { return }
        UIApplication.shared.openURL(current.endpointAnon)
    }

    @IBAction func btnAudience(_ sender: Any) {
        debugPrint("btnAudience \(type(of: self))")
        btnAudience.isSelected = !btnAudience.isSelected
        btnAudience.isHighlighted = false
    }

    override func viewDidLoad() {
        debugPrint("viewDidLoad \(type(of: self))")
        super.viewDidLoad()
        assert(txtTitle.delegate != nil)
        assert(txtDescr.delegate != nil)

        let ad = AppDelegate.shared
        lblVersion.text = ad.semver
        lblName.text = BUNDLE_NAME

        view.addSubview(spiPost)
        spiPost.frame = view.bounds
        // view.addConstraint(NSLayoutConstraint(item:view, attribute:.centerX, relatedBy:.equal, toItem:spiPost, attribute:.centerX, multiplier:1.0, constant:0))
        // view.addConstraint(NSLayoutConstraint(item:view, attribute:.centerY, relatedBy:.equal, toItem:spiPost, attribute:.centerY, multiplier:1.0, constant:0))
    }

    override func viewWillAppear(_ animated: Bool) {
        debugPrint("viewWillAppear \(type(of: self))")
        super.viewWillAppear(animated)

        let sm = ShaarliM.shared
        current = sm.loadBlog(sm.defaults)
        btnSafari.isEnabled = current?.endpoint != nil
        btnAudience.isSelected = current?.privateDefault ?? false
        if nil == current {
            title = NSLocalizedString("-", comment:"MainVC")
        }

        actionCancel(self)
        viewShaare!.alpha = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        debugPrint("viewDidAppear \(type(of: self))")
        super.viewDidAppear(animated)
        UIView.setAnimationsEnabled(true)

        let dt = 0.75
        UIView.animate(withDuration:dt) {
            self.vContainer.alpha = 0.5;

            // logo to bottom
            self.view.removeConstraint(self.centerY)
            self.centerY = self.centerY.withMultiplier(0.75)
            self.view.addConstraint(self.centerY)
            // self.view.layoutIfNeeded()
            self.viewShaare.alpha = 1
        }

        if current == nil {
            performSegue(withIdentifier:String(describing:SettingsVC.self), sender:self)
            return
        }

        // start with note form ready..
        // [self actionShowShaare:nil];
       // actionCancel(self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? SettingsVC else { return }
        vc.current = current
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn \(type(of: self))")
        switch textField {
        case txtTitle: txtDescr.becomeFirstResponder()
        default: return false
        }
        return true
    }
}

// visual form center http://stackoverflow.com/a/13148012/349514
extension NSLayoutConstraint {
    func withMultiplier(_ mu : CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(
            item:firstItem!,
            attribute:firstAttribute,
            relatedBy:relation,
            toItem:secondItem,
            attribute:secondAttribute,
            multiplier:mu,
            constant:constant)
    }
}
