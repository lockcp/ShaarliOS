//
//  BlogM.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 21.02.20.
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

import Foundation

/** Contact to a Microblog Server
 */
struct BlogM {
    let endpoint        : URL
    let credential      : URLCredential? // optional additional HTTP Basic
    let title           : String
    let timeout         : TimeInterval
    let privateDefault  : Bool
    let timezone        : TimeZone?
    let tagsDefault     : String

    var endpointAnon : URL {
        guard var uc = URLComponents(url:endpoint, resolvingAgainstBaseURL:true)
            else {return URLEmpty}
        uc.password = nil
        uc.user = nil
        return uc.url ?? URLEmpty
    }
}

internal let timeoutMinimumValue : TimeInterval = 0.2
internal let timeoutMaximumValue : TimeInterval = 15.0
internal let timeoutDefaultValue : TimeInterval = 4.0

internal func timeoutFromDouble(_ raw : Double) -> TimeInterval {
    return raw <= 0.0
        ? timeoutDefaultValue
        : raw <= timeoutMinimumValue
        ? timeoutMinimumValue
        : raw >= timeoutMaximumValue
        ? timeoutMaximumValue
        : raw
}
