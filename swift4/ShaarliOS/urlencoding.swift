//
//  urlencoding.swift
//  ShaarliOS
//
//  Created by Marcus Rohrmoser on 29.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
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
