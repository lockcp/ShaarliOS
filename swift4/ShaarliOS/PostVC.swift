//
//  PostVC.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 15.08.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import UIKit

class PostVC: UIViewController {

    @IBOutlet var lblTitle: UILabel!

    override func viewDidLoad() {
        print("viewDidLoad \(type(of: self))")
        super.viewDidLoad()

        // https://belkadigital.com/articles/modal-uiviewcontroller-blur-background-swift
        // https://stackoverflow.com/a/44400909
        let effect = UIBlurEffect(style:.light)
        let blurView = UIVisualEffectView(effect: effect)
        blurView.frame = self.view.bounds

        view.insertSubview(blurView, at:0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lblTitle.text = title
    }
    
    @IBAction func actionCancel(_ sender: Any) {
        print("actionCancel \(type(of: self))")
        dismiss(animated:true) { }
    }
}
