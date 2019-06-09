//
//  ShaarliSrvTest.swift
//  ShaarliOSTests
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import XCTest

class ShaarliSrvTest: XCTestCase {

    func dataWithContentsOfFixture(fileName: String, extensio:String) -> NSData {
        let b = Bundle(for: type(of: self))
        let sub = "testdata" + "/" + String(describing: self.classForCoder)
        guard let u = b.url(forResource: fileName, withExtension: extensio, subdirectory:sub)
            else { return NSData() }
        guard let d = NSData(contentsOf: u)
            else { return NSData() }
        return d
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUrl () {
        let url = URL(string: "https://uid:pwd@example.com/foo")!
        XCTAssertEqual("https://uid:pwd@example.com/foo", url.description)
        XCTAssertEqual("https", url.scheme)
        XCTAssertEqual("example.com", url.host)
        XCTAssertEqual("uid", url.user)
        XCTAssertEqual("pwd", url.password)
        XCTAssertEqual("/foo", url.path)
        XCTAssertEqual(nil, url.query)
        XCTAssertEqual(nil, url.fragment)
        
        var b = URLComponents(string:url.description)!
        b.user = "foo"
        let u2 = b.url!
        XCTAssertEqual("foo", u2.user)
        XCTAssertEqual("pwd", u2.password)
    }

    func testDictionary() {
        let d0 = [ "loginform" : [
            "token": "34534563456",
            "foo": "bar",
        ] ]
        XCTAssertEqual(1, d0.count)

        var d1 : [String : [String : String]] = [:]
        d1["loginform"] = [ "token": "3453456345" ]
        XCTAssertEqual(1, d1.count)
        XCTAssertEqual("3453456345", d1["loginform"]!["token"])
    }
    
    func testLoadfile() {
        let d = dataWithContentsOfFixture(fileName: "login.0", extensio:"html")
        XCTAssertEqual(2509, d.length)
    }

    func testFindForm() {
        let srv = ShaarliSrv()
        XCTAssertNotNil(srv)
        let forms = srv.findForms(html:"")
        XCTAssertEqual(0, forms.count)
    }
    
    func testProbe () {
        let srv = ShaarliSrv()
        XCTAssertNotNil(srv)
    }

}
