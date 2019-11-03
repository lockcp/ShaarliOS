//
//  ServerVC.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 02.11.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import UIKit

func dequeue(_ tableView:UITableView, _ indexPath: IndexPath) -> ServerTVC? {
    return tableView.dequeueReusableCell(withIdentifier:SubtitleCell, for:indexPath) as? ServerTVC
}

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
    guard let uid = uid else {return nil}
    guard let pwd = pwd else {return nil}
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

    func setup(_ tc:ServerTVC?) {
        guard let tc = tc else {
            result = { (a) in }
            endpoint = nil
            title = "?"
            return
        }
        result = tc.setup
        endpoint = tc.server
        title = endpoint?.key ?? "-"
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func clkTest(_ sender: Any) {
        print("clkTest \(type(of: sender))")
        test()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn \(textField.text ?? "-")")
        switch textField {
        case tfURL:
            guard tfURL.text != ""
                , let _ = url(tfURL.text, tfUid.text, tfPwd.text)
            else {
                tfURL.backgroundColor = colErr
                return false
            }
            tfUid.becomeFirstResponder()
            return true
        case tfUid:
            tfPwd.becomeFirstResponder()
            return true
        case tfPwd:
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
            ai.stopAnimating()
            print("url \(ur)")
            print("tit \(ti)")
            print("err \(er)")
            lbl.text = er
            switch er {
            case "":
                res(ServerM(ti, url(ur.absoluteString, u.user, u.password) ?? u))
                nav.popViewController(animated: true)
            default:
                tfu.backgroundColor = colErr
                tfu.becomeFirstResponder()
            }
        }
    }
}
