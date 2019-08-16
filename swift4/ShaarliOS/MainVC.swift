//
//  MainVC.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 15.08.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import UIKit

internal let EditSegue = "EditSegue"
internal let PostSegue = "PostSegue"

internal let SubtitleCell = "SubtitleCell"

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
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case EditSegue: return tableView.isEditing
        case PostSegue: return !tableView.isEditing
        default: return true
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare \(segue.identifier ?? "?") \(type(of: self)) -> \(String(describing: type(of:segue.destination)))")
        super.prepare(for:segue, sender:sender)
        switch segue.identifier {
        case EditSegue:
            guard let tc = sender as? UITableViewCell else {return}
            segue.destination.title = tc.textLabel?.text ?? "?" // just hand on the title
            segue.destination.view.backgroundColor = segue.source.view.backgroundColor
        case PostSegue:
            guard let tc = sender as? UITableViewCell else {return}
            segue.destination.title = tc.textLabel?.text ?? "?" // just hand on the title
        default: break
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellForRowAt \(type(of: self))")
        let cell = tableView.dequeueReusableCell(withIdentifier:SubtitleCell, for:indexPath)

        cell.textLabel!.text = "Uhu 🐳"
        cell.detailTextLabel!.text = "https://demo.mro.name/shaarligo/shaarligo.cgi"

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAt \(type(of: self))")
        tableView.deselectRow(at:indexPath, animated:true)
        // PostSegue is anchored on the cell, so no need to trigger it manually.
        // EditSegue is anchored on the table itself, so we need to trigger it manually
        if tableView.isEditing {
            performSegue(withIdentifier: EditSegue, sender:tableView.cellForRow(at: indexPath))
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
