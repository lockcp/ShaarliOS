//
//  ShareVC.swift
//  Share
//
//  Created by Marcus Rohrmoser on 02.03.20.
//  Copyright © 2020-2021 Marcus Rohrmoser mobile Software http://mro.name/me. All rights reserved.
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
import Social
import MobileCoreServices
import AudioToolbox

private func stringFromPrivacy(_ priv : Bool) -> String {
    return priv
        ? NSLocalizedString("Private 🔐", comment:"ShareVC")
        : NSLocalizedString("Public 🔓", comment:"ShareVC")
}

private func privacyFromString(_ s : String) -> Bool {
    return s != stringFromPrivacy(false)
}

private func play_sound_ok() {
    // https://github.com/irccloud/ios/blob/6e3255eab82be047be141ced6e482ead5ac413f4/ShareExtension/ShareViewController.m#L155
    AudioServicesPlaySystemSound(1001)
}

private func play_sound_err() {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
}

@objc (ShareVC) // https://blog.hellocode.co/post/share-extension/
class ShareVC: SLComposeServiceViewController {

    private let semver          =  info_to_semver(Bundle.main.infoDictionary)

    private var current         : BlogM? // may become local if not for missing cfg error
    private var wasTouched      = false
    private var itemTitle       : SLComposeSheetConfigurationItem?
    private var itemAudience    : SLComposeSheetConfigurationItem?
    private var session         : URLSession?
    private var action          : URL = URLEmpty
    private var ctx             : HtmlFormDict = [:]
    private var url             : URL = URLEmpty

    override func viewDidLoad() {
        debugPrint("viewDidLoad")
        super.viewDidLoad()
    }

    override func configurationItems() -> [Any]! {
        debugPrint("configurationItems")
        guard let iTi = SLComposeSheetConfigurationItem() else {return []}
        iTi.title = NSLocalizedString("Title", comment:"ShareVC")
        iTi.value = self.contentText

        guard let iAu = SLComposeSheetConfigurationItem() else {return []}
        iAu.title = NSLocalizedString("Audience", comment:"ShareVC")
        iAu.value = stringFromPrivacy(false)
        weak var wself = self
        iAu.tapHandler = {
            guard let sf = wself else {return}
            guard let iAu = sf.itemAudience else {return}
            iAu.value = stringFromPrivacy( !privacyFromString(iAu.value) )
            sf.wasTouched = true
        }

        itemTitle = iTi
        itemAudience = iAu
        return [iTi, iAu]
    }

    override func viewWillAppear(_ animated: Bool) {
        debugPrint("viewWillAppear")
        super.viewWillAppear(animated)
        view.tintColor = UIColor(red:128 / 255.0, green:173 / 255.0, blue:72 / 255.0, alpha:1.0)
        assert(itemTitle != nil)
        assert(itemAudience != nil)

        let sha = ShaarliM.shared
        // sha.defaults.removePersistentDomain(forName:"group.\(BUNDLE_ID)") // doesn't do it.
        current = sha.loadBlog(sha.defaults)
        guard let current = current else {
            // do nothing here and let viewDidAppear display a error popup
            return
        }
        let cli = ShaarliHtmlClient(semver)

        textView.keyboardType = .twitter
        view.subviews.forEach({ (v) in
            // dark mode?
            v.backgroundColor = UIColor.white.withAlphaComponent(0.89)
        })

        guard let itemTitle = itemTitle else {return}
        guard let itemAudience = itemAudience else {return}
        guard let textView = textView else {return}

        title = current.title
        itemTitle.value = contentText
        let preset = tagsNormalise(description:itemTitle.value, extended:current.tagsDefault, tags:[], known:[])
        textView.text = "\(preset.extended) \(NSLocalizedString("🔄", comment:"ShareVC"))"
        itemAudience.value = stringFromPrivacy(current.privateDefault)

        let tPli = kUTTypePropertyList as String
        let tUrl = kUTTypeURL as String
        let tTxt = kUTTypeText as String
        let RK = NSExtensionJavaScriptPreprocessingResultsKey as String
        weak var ws = self
        for _item in (extensionContext?.inputItems)! {
            let item = _item as! NSExtensionItem
            for ip in (item.attachments!) {
                guard let ws = ws else {return}
                // let ip = _ip as! NSItemProvider // required for Xcode <10
                if( ip.hasItemConformingToTypeIdentifier(tPli)) {
                    ip.loadItem(forTypeIdentifier:tPli, options:nil) { (_dic, err) in
                        guard let _dic = (_dic as? NSDictionary)?[RK] as? [String:String] else {
                            play_sound_err()
                            ws.showError(
                                title:NSLocalizedString("URL Share Sheet failed", comment: "ShareVC"),
                                message:NSLocalizedString("I got no dictionary to share.", comment: "ShareVC"),
                                showsettings:false
                            )
                            return
                        }
                        let kUrl = "url"
                        let kTit = "title"
                        let kDsc = "description"
                        let kTgs = "keywords"
                        let kImg = "image"
                        guard let _url = URL(string:_dic[kUrl] ?? "") else {
                            play_sound_err()
                            ws.showError(
                                title:NSLocalizedString("URL Share Sheet failed", comment: "ShareVC"),
                                message:NSLocalizedString("I got no url to share.", comment: "ShareVC"),
                                showsettings:false
                            )
                            return
                        }
                        guard let err = err else {
                            let t0 = Date()
                            cli.get(current.endpoint, current.credential, current.timeout, _url, { (ses, act, ctx, _url, tit, dsc, tgs, pri, tim, seti, err) in
                                guard "" == err else {
                                    play_sound_err()
                                    ws.showError(
                                        title:NSLocalizedString("Can't reach Shaarli", comment: "ShareVC"),
                                        message:err,
                                        showsettings:true
                                    )
                                    return
                                }
                                guard URLEmpty != act else {
                                    play_sound_err()
                                    ws.showError(
                                        title:NSLocalizedString("Can't post to Shaarli", comment: "ShareVC"),
                                        message:NSLocalizedString("the Shaarli responded an empty linkform action, I don't know where to post to.", comment: "ShareVC"),
                                        showsettings:true
                                    )
                                    return
                                }
                                self.session = ses
                                // should 'old' come out of get( callback(... old) )?
                                let old = isOld(t0, seti, cli.timeShaarli(current.timezone, tim))
                                let dti = _dic[kTit] ?? ""
                                let dde = _dic[kDsc] ?? ""
                                // let dim = URL(string:_dic[kImg] ?? "", relativeTo:_url)
                                let v = old || ("" != tit || "" != dsc)
                                    ? (tit, dsc, tgs)
                                    : (dti == "" && dde == ""
                                        ? (itemTitle.value ?? "", preset.extended, [])
                                        : (dti, dde, tagsSplit(_dic[kTgs])) )
                                let r = tagsNormalise(description:v.0, extended:v.1, tags:v.2.union(preset.tags), known:[])
                                DispatchQueue.main.async {
                                    ws.action = act
                                    ws.ctx = ctx
                                    ws.url = _url
                                    itemTitle.value = r.description
                                    textView.text = "\(r.extended) "
                                    itemAudience.value = stringFromPrivacy(pri)
                                }
                            })
                            return
                        }
                        ws.showError(
                            title:NSLocalizedString("URL Share Sheet failed", comment: "ShareVC"),
                            message:err.localizedDescription,
                            showsettings:false
                        )
                    }
                }
                // see predicate from http://stackoverflow.com/a/27932776
                else if( ip.hasItemConformingToTypeIdentifier(tUrl) ) {
                    // maybe this whole block can go away
                    ip.loadItem(forTypeIdentifier:tUrl, options:nil) { (_url, err) in
                        guard let _url = _url as? URL else {
                            play_sound_err()
                            ws.showError(
                                title:NSLocalizedString("URL Share Sheet failed", comment: "ShareVC"),
                                message:NSLocalizedString("I got no url to share.", comment: "ShareVC"),
                                showsettings:false
                            )
                            return
                        }
                        guard let err = err else {
                            cli.get(current.endpoint, current.credential, current.timeout, _url, { (ses, act, ctx, _url, tit, dsc, tgs, pri, tim, seti, err) in
                                guard "" == err else {
                                    play_sound_err()
                                    ws.showError(
                                        title:NSLocalizedString("Can't reach Shaarli", comment: "ShareVC"),
                                        message:err,
                                        showsettings:true
                                    )
                                    return
                                }
                                guard URLEmpty != act else {
                                    play_sound_err()
                                    ws.showError(
                                        title:NSLocalizedString("Can't post to Shaarli", comment: "ShareVC"),
                                        message:NSLocalizedString("the Shaarli responded an empty linkform action, I don't know where to post to.", comment: "ShareVC"),
                                        showsettings:true
                                    )
                                    return
                                }
                                self.session = ses
                                let v = "" == tit && "" == dsc
                                    ? (itemTitle.value, preset.extended)
                                    : (tit, dsc)
                                let r = tagsNormalise(description:v.0, extended:v.1, tags:tgs.union(preset.tags), known:[])
                                DispatchQueue.main.async {
                                    ws.action = act
                                    ws.ctx = ctx
                                    ws.url = _url
                                    itemTitle.value = r.description
                                    textView.text = "\(r.extended) "
                                    itemAudience.value = stringFromPrivacy(pri)
                                }
                            })
                            return
                        }
                        ws.showError(
                            title:NSLocalizedString("URL Share Sheet failed", comment: "ShareVC"),
                            message:err.localizedDescription,
                            showsettings:false
                        )
                    }
                }
                else if( ip.hasItemConformingToTypeIdentifier(tTxt) ) {
                    ip.loadItem(forTypeIdentifier:tTxt, options:nil) { (_txt, err) in
                        guard let err = err else {
                            debugPrint("done. title:\(itemTitle.value ?? "-") txt:\(String(describing: _txt))")
                            return
                        }
                        ws.showError(
                            title:NSLocalizedString("TXT Share Sheet failed", comment: "ShareVC"),
                            message:err.localizedDescription,
                            showsettings:false
                        )
                    }
                }
            }
        }
    }

    override func didSelectPost() {
        debugPrint("didSelectPost")
        let c = ShaarliHtmlClient(semver)
        guard let tit = itemTitle?.value else {return}
        guard let dsc = textView.text else {return}
        let pri = privacyFromString((itemAudience?.value)!)
        let r = tagsNormalise(description:tit, extended:dsc, tags:[], known:[])
        c.add(session!, action, ctx, url, r.description, r.extended, r.tags, pri) { err in
            guard "" == err else {
                play_sound_err()
                self.showError(
                    title:NSLocalizedString("Share failed", comment: "ShareVC"),
                    message:err,
                    showsettings:false
                )
                usleep(750 * 1000)
                return
            }

            play_sound_ok()
            // wait until the sound finished
            usleep(750 * 1000)
            super.didSelectPost()
        }
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        // self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard nil != current else {
            showError(
                title:NSLocalizedString("No Shaarli found", comment:"ShareVC"),
                message:NSLocalizedString("Please add one in the Settings.", comment:"ShareVC"),
                showsettings:true)
            return
        }

        wasTouched = false
    }

    private func showError(title:String, message:String, showsettings:Bool) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title:title,
                message:message,
                preferredStyle:.alert
            )

            alert.addAction(UIAlertAction(
                title: NSLocalizedString("Cancel", comment:"ShareVC"),
                style:.cancel,
                handler:{ (_) in
                    self.cancel()
            }))

            if showsettings {
                alert.addAction(UIAlertAction(
                    title: NSLocalizedString("Settings", comment:"ShareVC"),
                    style:.default,
                    handler:{ (_) in
                        // https://stackoverflow.com/a/44499222/349514
                        DispatchGroup().notify(queue: DispatchQueue.main) {
                            let _ = self.openURL(URL(string:"\(SELF_URL_PREFIX):///settings")!)
                        }
                        self.cancel()
                }))
            }

            self.present(alert, animated:true, completion:nil)
        }
    }

    override func presentationAnimationDidFinish() {
        debugPrint("presentationAnimationDidFinish")
    }

    override func isContentValid() -> Bool {
        debugPrint("isContentValid")
        // Do validation of contentText and/or NSExtensionContext attachments here
        wasTouched = true
        return true
    }

    // No preview image right upper inside the share dialog.
    override func loadPreviewView() -> UIView! {
        return nil
    }

    override func didSelectCancel() {
        debugPrint("didSelectCancel")
        super.didSelectCancel()
    }

    // https://stackoverflow.com/a/44499222/349514
    // Function must be named exactly like this so a selector can be found by the compiler!
    // Anyway - it's another selector in another instance that would be "performed" instead.
    @objc private func openURL(_ url: URL) -> Bool {
        var rep: UIResponder? = self
        while rep != nil {
            if let app = rep as? UIApplication {
                return app.perform(#selector(openURL(_:)), with: url) != nil
            }
            rep = rep?.next
        }
        return false
    }
}
