//
//  MainVC.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 15.08.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import UIKit

internal let ServerSegue = "ServerSegue"
internal let PostSegue = "PostSegue"

class MainVC: UITableViewController {

    @IBOutlet var btnEdit: UIBarButtonItem!
    @IBOutlet var btnSave: UIBarButtonItem!
    @IBOutlet var btnCancel: UIBarButtonItem!
    @IBOutlet var btnLegal: UIBarButtonItem!

    var servers: [ServerM] = [
        ServerM("Shaarli demö", URL(string:"https://demo:demo@demo.shaarli.org")!),
        ServerM("ShaarliGo", URL(string:"https://demo:demodemodemo@demo.mro.name/shaarligo/shaarligo.cgi")!),
        ServerM("Shaarli v0.41", URL(string:"https://demo:demodemodemo@demo.mro.name/shaarli-v0.41b")!),
        ServerM("Shaarli v0.10.2", URL(string:"https://demo:demodemodemo@demo.mro.name/shaarli-v0.10.2")!)
    ]

    override func viewDidLoad() {
        print("viewDidLoad \(type(of: self))")
        super.viewDidLoad()
        view.backgroundColor = green60_64_66
        view.isOpaque = true
    }

    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear \(type(of: self))")
        super.viewWillAppear(animated)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case ServerSegue:
            return tableView.isEditing
        case PostSegue:
            return !tableView.isEditing
        default:
            return true
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare \(segue.identifier ?? "?") \(type(of: self)) -> \(String(describing: type(of:segue.destination)))")
        super.prepare(for:segue, sender:sender)
        switch segue.identifier {
        case ServerSegue:
            guard let vc = segue.destination as? ServerVC else {return}
            vc.setup(sender as? ServerTVC)
            vc.view.backgroundColor = segue.source.view.backgroundColor
            break
        case PostSegue:
            guard let vc = segue.destination as? PostVC else {return}
            vc.setup(sender as? ServerTVC)
            break
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("\(type(of: self)) cellForRowAt \(indexPath.row))")
        guard let cell = dequeue(tableView, indexPath) else { return UITableViewCell() }
        cell.setup(servers[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("\(type(of: self)) didSelectRowAt \(indexPath.row))")
        tableView.deselectRow(at:indexPath, animated:true)
        // PostSegue is anchored on the cell, so no need to trigger it manually.
        // ServerSegue is anchored on the table itself, so we need to trigger it manually
        if tableView.isEditing {
            performSegue(withIdentifier: ServerSegue, sender:tableView.cellForRow(at: indexPath))
        }
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        print("moveRowAt \(type(of: self)) \(sourceIndexPath) -> \(destinationIndexPath)")
        // swap(&servers[sourceIndexPath.row], &servers[destinationIndexPath.row])
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
