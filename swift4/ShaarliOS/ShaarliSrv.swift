//
//  ShaarliSrv.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import Foundation

class ShaarliSrv {
    // check credentials
    
    func findForms(html:String?) -> [String : [String : String]] {
        var ret : [String : [String : String]] = [:]
        guard let da = html
            else { return ret }
        
        return ret
    }
}
