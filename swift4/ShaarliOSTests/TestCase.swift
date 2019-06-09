//
//  TestCase.swift
//  ShaarliOSTests
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import XCTest

class TestCase: XCTestCase {
    func dataWithContentsOfFixture(fileName: String, extensio:String) -> NSData {
        let b = Bundle(for: type(of: self))
        let sub = "testdata" + "/" + String(describing: self.classForCoder)
        guard let u = b.url(forResource: fileName, withExtension: extensio, subdirectory:sub)
            else { return NSData() }
        guard let d = NSData(contentsOf: u)
            else { return NSData() }
        return d
    }
}
