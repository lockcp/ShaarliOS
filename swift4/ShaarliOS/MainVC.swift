//
//  MainVC.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 15.08.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import UIKit

class MainVC: UITableViewController {

    @IBOutlet var btnEdit: UIBarButtonItem!
    @IBOutlet var btnSave: UIBarButtonItem!
    @IBOutlet var btnCancel: UIBarButtonItem!
    @IBOutlet var btnLegal: UIBarButtonItem!
    
    override func viewDidLoad() {
        print("viewDidLoad \(type(of: self))")
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear \(type(of: self))")
        super.viewWillAppear(animated)

        // navigationController!.view.backgroundColor = .orange
        // navigationController!.viewControllers.forEach { $0.view.backgroundColor = .orange }
        // UIApplication.shared.windows.first!.backgroundColor = .orange
        // UIApplication.shared.windows.first!.rootViewController!.view.backgroundColor = .orange
        // parent!.view.backgroundColor = .orange
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare \(type(of: self))-> \(String(describing: type(of:segue.destination)))")
        super.prepare(for:segue, sender:sender)
        // segue.destination.view.backgroundColor = .orange
    }

    override func performSegue(withIdentifier identifier: String, sender: Any?) {
        print("performSegue \(type(of: self))")
        super.performSegue(withIdentifier: identifier, sender:sender)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellForRowAt \(type(of: self))")
        let id = "SubtitleCell"
        let cell = tableView.dequeueReusableCell(withIdentifier:id, for:indexPath)
        cell.textLabel!.text = "Uhu 🐳"
        cell.detailTextLabel!.text = "https://demo.mro.name/shaarligo/shaarligo.cgi"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAt \(type(of: self))")
        tableView.deselectRow(at:indexPath, animated:true)
        if tableView.isEditing {
            self.performSegue(withIdentifier: "EditSegue", sender: self)
            return
        }
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        print("moveRowAt \(type(of: self)) \(sourceIndexPath) -> \(destinationIndexPath)")
    }

    @IBAction func actionEdit(_ sender: Any) {
        print("actionEdit \(type(of: self))")
        tableView.setEditing(true, animated: true)
        navigationItem.setLeftBarButton(btnSave, animated:true)
        navigationItem.setRightBarButton(btnCancel, animated:true)
    }

    @IBAction func actionCancel(_ sender: Any) {
        print("actionCancel \(type(of: self))")
        tableView.setEditing(false, animated: true)
        navigationItem.setLeftBarButton(btnEdit, animated:true)
        navigationItem.setRightBarButton(btnLegal, animated:true)
    }

    @IBAction func actionSave(_ sender: Any) {
        print("actionSave \(type(of: self))")
        tableView.setEditing(false, animated: true)
        navigationItem.setLeftBarButton(btnEdit, animated:true)
        navigationItem.setRightBarButton(btnLegal, animated:true)

    }
}
