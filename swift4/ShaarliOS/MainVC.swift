//
//  MainVC.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 15.08.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import UIKit

// Reading from private effective user settings. https://stackoverflow.com/a/45280879/349514
class MainVC: UIViewController {

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

    override func viewDidLoad() {
        print("viewDidLoad \(type(of: self))")
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear \(type(of: self))")
        super.viewWillAppear(animated)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare \(segue.identifier ?? "?") \(type(of: self)) -> \(String(describing: type(of:segue.destination)))")
        super.prepare(for:segue, sender:sender)
    }
}
