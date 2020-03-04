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

// Reading from private effective user settings. https://stackoverflow.com/a/45280879/349514
class MainVC: UIViewController {

    // visual form center http://stackoverflow.com/a/13148012/349514
    private func constraintWithMultiplier(_ elf: NSLayoutConstraint!, multiplier: CGFloat) -> NSLayoutConstraint!
    {
        return NSLayoutConstraint(
            item:elf.firstItem!,
            attribute:elf.firstAttribute,
            relatedBy:elf.relation,
            toItem:elf.secondItem,
            attribute:elf.secondAttribute,
            multiplier:multiplier,
            constant:elf.constant)
    }

    @IBOutlet var centerY: NSLayoutConstraint!
    @IBOutlet var lblVersion: UILabel!
    @IBOutlet var vContainer: UIView!
    @IBOutlet var btnPetal: UIButton!
    @IBOutlet var btnSafari: UIBarButtonItem!
    
    @IBOutlet var viewShaare: UIView!
    @IBOutlet var btnShaare: UIButton!
    @IBOutlet var txtDescr: UITextView!
    @IBOutlet var txtTitle: UITextField!
    @IBOutlet var btnAudience: UIButton!
    
    // http://spin.atomicobject.com/2014/03/05/uiscrollview-autolayout-ios/
    @IBOutlet var activeField: UIView!
    @IBOutlet var scrollView: UIScrollView!

    @IBOutlet var spiPost          : UIActivityIndicatorView?

    @IBAction func actionCancel(_ sender: Any) {
        debugPrint("actionCancel \(type(of: self))")

        viewShaare.alpha = 1
        spiPost?.stopAnimating()
        btnShaare.isEnabled = current != nil
        btnSafari.isEnabled = btnShaare.isEnabled
        guard let b = current else { return }
        title = b.title
        btnAudience.isSelected = current?.privateDefault ?? false
        txtTitle.text = ""
        txtDescr.text = b.tagsActive
            ? "\(b.tagsDefault) "
            : ""
        txtDescr.becomeFirstResponder()
    }

    @IBAction func actionPost(_ sender: Any) {
        debugPrint("actionPost \(type(of: self))")
        guard let btnShaare = btnShaare else { return }
        guard let btnAudience = btnAudience else { return }
        guard let txtDescr = txtDescr else { return }
        guard let txtTitle = txtTitle else { return }
        guard let spiPost = spiPost else { return }

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
        let c = ShaarliHtmlClient()
        c.get(srv, URLEmpty) { ctx, ur_, ti_, de_, ta_, pr_, err in
            guard "" == err else {
                DispatchQueue.main.async {
                    self.reportPostingError(err)
                }
                return
            }
            var ctx = ctx
            ctx.removeValue(forKey: "cancel_edit")
            let r = tagsNormalise(description:tit, extended:dsc, tags:ta_, known:[])
            c.add(srv, ctx, ur_, r.description, r.extended, r.tags, pri) { err in
                DispatchQueue.main.async {
                    guard "" == err else {
                        self.reportPostingError(err)
                        return
                    }
                    print("set result: '\(ur_)'")
                    self.actionCancel(self)
                }
            }
        }
    }

    fileprivate func reportPostingError(_ err:String) {
        guard let spiPost = spiPost else { return }
        spiPost.stopAnimating()
        btnShaare.isEnabled = !spiPost.isAnimating
        UIAlertView(title:"Sorry, couldn't post", message:err, delegate:nil, cancelButtonTitle:"OK").show()
    }

    @IBAction func actionSafari(_ sender: Any) {
        debugPrint("actionSafari \(type(of: self))")
        guard let current = current else { return }
        UIApplication.shared.openURL(current.endpointAnon)
    }

    @IBAction func btnAudience(_ sender: Any) {
        debugPrint("btnAudience \(type(of: self))")
        guard let btnAudience = btnAudience else { return }
        btnAudience.isSelected = !btnAudience.isSelected
        btnAudience.isHighlighted = false
    }

    var current : BlogM?

    override func viewDidLoad() {
        debugPrint("viewDidLoad \(type(of: self))")
        super.viewDidLoad()
        assert(nil != spiPost)

        guard let spiPost = spiPost else { return }
        view.addSubview(spiPost)
        spiPost.frame = view.bounds
        // view.addConstraint(NSLayoutConstraint(item:view, attribute:.centerX, relatedBy:.equal, toItem:spiPost, attribute:.centerX, multiplier:1.0, constant:0))
        // view.addConstraint(NSLayoutConstraint(item:view, attribute:.centerY, relatedBy:.equal, toItem:spiPost, attribute:.centerY, multiplier:1.0, constant:0))
    }

    override func viewWillAppear(_ animated: Bool) {
        debugPrint("viewWillAppear \(type(of: self))")
        super.viewWillAppear(animated)

        let ad = AppDelegate.shared
        lblVersion.text = ad.semver

        let sm = ShaarliM.shared
        current = sm.loadBlog(sm.defaults)
        btnSafari.isEnabled = current?.endpoint != nil
        btnAudience.isSelected = current?.privateDefault ?? false
        if nil == current {
            title = NSLocalizedString("-", comment:String(describing:type(of:self)))
            viewShaare.alpha = 0
        }
        actionCancel(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        debugPrint("viewDidAppear \(type(of: self))")
        super.viewDidAppear(animated)
        UIView.setAnimationsEnabled(true)

        UIView.animate(withDuration:0.5) {
            self.vContainer.alpha = 0.5;
            self.lblVersion.alpha = 1.0;

            // logo to bottom
            self.view.removeConstraint(self.centerY)
            self.centerY = self.constraintWithMultiplier(self.centerY, multiplier:0.75)!
            self.view.addConstraint(self.centerY)
            // self.view.layoutIfNeeded()
        }

        guard let b = current else {
            performSegue(withIdentifier:String(describing:SettingsVC.self), sender:self)
            return
        }

        // start with note form ready..
        // [self actionShowShaare:nil];
        actionCancel(self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? SettingsVC else { return }
        vc.current = current
    }
}
