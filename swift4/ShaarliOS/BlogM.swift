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
    let title           : String
    let privateDefault  : Bool
    let tagsDefault     : String

    var endpointAnon : URL {
        guard var uc = URLComponents(url:endpoint, resolvingAgainstBaseURL:true)
            else {return URLEmpty}
        uc.password = nil
        uc.user = nil
        return uc.url ?? URLEmpty
    }
}
