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
    
    @IBAction func actionCancel(_ sender: Any) {
        print("actionCancel \(type(of: self))")
    }

    @IBAction func actionPost(_ sender: Any) {
        print("actionPost \(type(of: self))")
    }

    @IBAction func btnAudience(_ sender: Any) {
        print("btnAudience \(type(of: self))")
    }

    var current : BlogM?

    override func viewDidLoad() {
        print("viewDidLoad \(type(of: self))")
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear \(type(of: self))")
        super.viewWillAppear(animated)

        let ad = AppDelegate.shared
        lblVersion.text = ad.semver
        current = ad.loadBlog(ad.defaults, ad.keychain)
        if nil == current {
            title = NSLocalizedString("-", comment:String(describing:type(of:self)))
            viewShaare.alpha = 0
            btnSafari.isEnabled = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear \(type(of: self))")
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

        title = b.title
        viewShaare.alpha = 1
        btnSafari.isEnabled = true
        // start with note form ready..
        // [self actionShowShaare:nil];
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? SettingsVC else {return}
        vc.current = current
    }
}
