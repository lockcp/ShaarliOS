//
//  urlencoding.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 29.06.19.
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

import Foundation


/* https://gist.github.com/winkelsdorf/f95b194eb1c2e9db0856
 Returns full RFC 3986 compliant percent-encoded URL
 [StackOverflow Thread 1](http://stackoverflow.com/questions/25786226/why-doesnt-cfstringencodings-have-utf8-in-swift)
 [StackOverflow Thread 2](http://stackoverflow.com/questions/8086584/objective-c-url-encoding/8086845#8086845)
 */
func percentEncode(in input: String?) -> String? {
    let charset = CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]" + "\n\r \"\\%-.<>^_`{|}~").inverted
    let escaped = input?.addingPercentEncoding(withAllowedCharacters: charset)
    
    return escaped
}
