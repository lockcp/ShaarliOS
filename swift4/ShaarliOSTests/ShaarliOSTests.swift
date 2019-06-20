//
//  ShaarliOSTests.swift
//  ShaarliOSTests
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import XCTest
@testable import ShaarliOS

class ShaarliOSTests: XCTestCase {

    private let df1123 = DateFormatter()

    internal func RFC1123(_ date:Date) -> String {
        return df1123.string(from: date)
    }

    override func setUp() {
        // https://mro.name/blog/2009/08/nsdateformatter-http-header/
        df1123.locale = Locale(identifier: "en_US")
        df1123.timeZone = TimeZone(abbreviation: "GMT")
        df1123.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRfc1123() {
        XCTAssertEqual("Sat, 01 Jan 0001 00:00:00 GMT", RFC1123(Date.distantPast))
    }

    func testUrl () {
        let url = URL(string: "https://uid:pwd@example.com/foo")!
        XCTAssertEqual("https://uid:pwd@example.com/foo", url.description)
        XCTAssertEqual("https", url.scheme)
        XCTAssertEqual("example.com", url.host)
        XCTAssertEqual("uid", url.user)
        XCTAssertEqual("pwd", url.password)
        XCTAssertEqual("/foo", url.path)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
