//
//  ServerVC.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 02.11.19.
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

func dequeue(_ tableView:UITableView, _ indexPath: IndexPath) -> ServerTVC? {
    return tableView.dequeueReusableCell(withIdentifier:SubtitleCell, for:indexPath) as? ServerTVC
}

let S_HTTP = "http"
let S_HTTPS = S_HTTP + "s"

internal let SubtitleCell = "ServerTVC"
internal let colErr = #colorLiteral(red: 1, green: 0.6743582589, blue: 0.6743582589, alpha: 1)
internal let colOk = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

typealias ServerM = KeyValuePairs<String,URL>.Element

class ServerTVC: UITableViewCell {
    var server: ServerM?
    
    func setup(_ srvr: ServerM) -> () {
        server = srvr
        textLabel?.text = srvr.key

        detailTextLabel?.text = ""
        guard var uc = URLComponents(url: srvr.value, resolvingAgainstBaseURL: true) else { return }
        uc.password = nil
        detailTextLabel?.text = uc.string ?? ""
    }
}

internal func url(_ base : String?, _ uid : String?, _ pwd: String?) -> URL? {
    guard let base = base else {return nil}
    guard var uc = URLComponents(string: base) else {return nil}
    uc.user = uid
    uc.password = pwd
    return uc.url
}

class ServerVC: UIViewController, UITextFieldDelegate {

    var endpoint: ServerM?
    var shaarli: ShaarliHtmlClient = ShaarliHtmlClient()
    var result: (ServerM) -> () = { (sr) in }

    @IBOutlet weak var tfURL: UITextField!
    @IBOutlet weak var tfUid: UITextField!
    @IBOutlet weak var tfPwd: UITextField!
    @IBOutlet weak var lbInfo: UILabel!
    @IBOutlet weak var btTest: UIButton!
    @IBOutlet var aiURL: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        print("viewDidLoad \(type(of: self))")
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear \(type(of: self)) endpoint \(endpoint?.value.absoluteString ?? "-")")
        super.viewWillAppear(animated)

        tfURL.becomeFirstResponder()
        guard let endpoint = endpoint else { return }
        guard var uc = URLComponents(url: endpoint.value, resolvingAgainstBaseURL: true) else {return}
        tfUid.text = uc.user
        tfPwd.text = uc.password
        uc.user = nil
        uc.password = nil
        tfURL.text = uc.string
        lbInfo.text = ""
    }

    // convenience
    func setup(_ tc:ServerTVC?) {
        guard let tc = tc else {
            setup(nil) { (a) in }
            return
        }
        setup(tc.server, tc.setup)
    }
    
    func setup(_ endp:ServerM?, _ res: @escaping (ServerM) -> ()) {
        result = res
        endpoint = endp
        title = endp?.key ?? "-"
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn \(textField.text ?? "-")")
        switch textField {
        case tfURL:
            
            guard tfURL.text != ""
                , let uc = URL(string: tfURL.text ?? "")
            else {
                tfURL.backgroundColor = colErr
                return false
            }
            if(uc.scheme == nil) {
                tfURL.text = S_HTTPS + "://" + (tfURL.text ?? "")
            }
            tfUid.becomeFirstResponder()
            return true
        case tfUid:
            tfPwd.becomeFirstResponder()
            return true
        case tfPwd:
            // TODO: erst erlauben, wenn die URL Sinn ergibt, uid und pwd nicht leer sind
            tfPwd.resignFirstResponder()
            test()
            return true
        default:
            print("Uhu")
        }
        return false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        print("textFieldDidEndEditing \(textField.text ?? "-")")
    }
    
    func test() {
        guard let u = url(tfURL.text, tfUid.text, tfPwd.text) else {
            tfURL.backgroundColor = colErr
            return
        }
        guard let tfu = tfURL else {return}
        guard let lbl = lbInfo else {return}
        guard let nav = navigationController else {return}
        guard let ai = aiURL else {return}
        let res = result

        ai.startAnimating()
        tfu.backgroundColor = colOk
        lbl.text = ""

        shaarli.probe(u) { (ur, ti, er) in            
            print("url \(ur)")
            print("tit \(ti)")
            print("err \(er)")
            ai.stopAnimating()
            lbl.text = er
            switch er {
            case "":
                res(ServerM(ti, url(ur.absoluteString, u.user, u.password) ?? u))
                nav.popViewController(animated: true)
            default:
                tfu.backgroundColor = colErr
                tfu.becomeFirstResponder()
            }
            return false
        }
    }
}
