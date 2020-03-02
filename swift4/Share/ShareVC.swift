//
//  ShareVC.swift
//  Share
//
//  Created by Marcus Rohrmoser on 02.03.20.
//  Copyright © 2020-2020 Marcus Rohrmoser mobile Software http://mro.name/me. All rights reserved.
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

fileprivate func stringFromPrivacy(_ priv : Bool) -> String
{
    return priv
        ? NSLocalizedString("Private 🔐", comment:"ShaareVC")
        : NSLocalizedString("Public 🔓", comment:"ShareVC")
}

fileprivate func privacyFromString(_ s : String) -> Bool
{
    return s != stringFromPrivacy(false)
}

@objc (ShareVC) // https://blog.hellocode.co/post/share-extension/
class ShareVC: SLComposeServiceViewController {

    var wasTouched      = false
    var itemTitle       : SLComposeSheetConfigurationItem?
    var itemAudience    : SLComposeSheetConfigurationItem?

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
        iAu.tapHandler = {
            // weak self ref?
            guard let iAu = self.itemAudience else {return}
            iAu.value = stringFromPrivacy( !privacyFromString(iAu.value) )
            self.wasTouched = true
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

        wasTouched = false
        textView.keyboardType = .twitter

        guard let itemTitle = itemTitle else {return}
        guard let itemAudience = itemAudience else {return}

        title = "Uhu"
        itemTitle.value = contentText
        let tagsDefault = true
            ? "#a #b"
            : ""

        var txt = "🔄"
        if( "" != tagsDefault ) {
            txt = "\(tagsDefault) \(txt)"
        }
        textView.text = txt
        itemAudience.value = stringFromPrivacy(false)

        for _item in (extensionContext?.inputItems)! {
            let item = _item as! NSExtensionItem
            for _itemProvider in (item.attachments!) {
                let itemProvider = _itemProvider
                // see predicate from http://stackoverflow.com/a/27932776
                let t = kUTTypeURL as String
                if( itemProvider.hasItemConformingToTypeIdentifier(t) ) {
                    itemProvider.loadItem(forTypeIdentifier:t, options:nil) { (_url, err) in
                        debugPrint("done. title:\(itemTitle.value) url:\(_url) \(err)")
                        guard let err = err else {
                            // post!
                            return
                        }
                        debugPrint("Error: \(err)")
                    }
                }
                
            }
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

    override func didSelectPost() {
        debugPrint("didSelectPost")
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.

        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        // self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func didSelectCancel() {
        debugPrint("didSelectCancel")
    }
}
