//
//  SettingsVCTest.swift
//  SettingsVCTest
//
//  Created by Marcus Rohrmoser on 23.04.20.
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

import XCTest
@testable import ShaarliOS

class SettingsVCTest: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testEndpoints() {
        for txt in [
            "https://demo.0x4c.de/shaarli-v0.41b",
            "http://demo.0x4c.de/shaarli-v0.41b",
            "//demo.0x4c.de/shaarli-v0.41b",
            "demo.0x4c.de/shaarli-v0.41b",
            "demo.0x4c.de/shaarli-v0.41b",
            ] {
                let ep = endpoints(txt, "demo", "demodemodemo")
                XCTAssertEqual(6, ep.count)
                XCTAssertEqual([
                    "https://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b",
                    "http://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b",
                    "https://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/index.php",
                    "http://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/index.php",
                    "https://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/shaarli.cgi",
                    "http://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/shaarli.cgi"
                    ], ep.map({ $0.absoluteString }))
        }
        for txt in [
            "https://demo.0x4c.de/shaarli-v0.41b/",
            "http://demo.0x4c.de/shaarli-v0.41b/",
            "//demo.0x4c.de/shaarli-v0.41b/",
            "demo.0x4c.de/shaarli-v0.41b/",
            "demo.0x4c.de/shaarli-v0.41b/",
            ] {
                let ep = endpoints(txt, "demo", "demodemodemo")
                XCTAssertEqual(6, ep.count)
                XCTAssertEqual([
                    "https://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/",
                    "http://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/",
                    "https://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/index.php",
                    "http://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/index.php",
                    "https://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/shaarli.cgi",
                    "http://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/shaarli.cgi"
                    ], ep.map({ $0.absoluteString }))
        }
    }
}
