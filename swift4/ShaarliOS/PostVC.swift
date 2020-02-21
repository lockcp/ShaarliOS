//
//  PostVC.swift
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

// keyboard https://stackoverflow.com/a/48106215/349514
// https://useyourloaf.com/blog/safe-area-layout-guide/
class PostVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var btSettings: UIButton!
    @IBOutlet weak var btShare: UIButton!
    
    @IBOutlet weak var viStep0: UIView!
    @IBOutlet weak var tfPost0: UITextField!

    @IBOutlet weak var viStep1: UIView!
    @IBOutlet weak var tfURL: UITextField!
    @IBOutlet weak var tfTit: UITextField!
    @IBOutlet weak var tvDsc: UITextView!
    @IBOutlet weak var aiTit: UIActivityIndicatorView!
    @IBOutlet weak var btAudience: UIButton!

    func setup(_ tc:ServerTVC?) {
        guard let tc = tc else {
            title = "?"
            return
        }
        title = tc.server?.key ?? "-"
    }

    override func viewDidLoad() {
        print("viewDidLoad \(type(of: self))")
        super.viewDidLoad()
        tfTit.leftViewMode = .always
        tfTit.leftView = aiTit

        // https://belkadigital.com/articles/modal-uiviewcontroller-blur-background-swift
        // https://stackoverflow.com/a/44400909
        let effect = UIBlurEffect(style:.light)
        let blurView = UIVisualEffectView(effect: effect)
        blurView.frame = self.view.bounds

        btSettings.setTitleColor(green, for:.normal)
        btShare.setTitleColor(green, for:.normal)
        view.insertSubview(blurView, at:0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lblTitle.text = title
        // iOS 11+ view.safeAreaLayoutGuide
        // iOS 11+ view.safeAreaInsets
    }
    
    @IBAction func actionCancel(_ sender: Any) {
        print("actionCancel \(type(of: self))")
        dismiss(animated:true) { }
    }

    @IBAction func acAudience(_ sender: AnyObject) {
        guard sender === btAudience else {return}
        print("sender \(String(describing: btAudience.titleLabel?.text))")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case tfURL:
            tfTit.becomeFirstResponder()
        case tfTit:
            tvDsc.becomeFirstResponder()
        case tvDsc:
            print("Let's go!")
        default:
            print("Uhu")
        }
        return true
    }
}
