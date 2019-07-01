//
//  FormParserTest.swift
//  ShaarliOSTests
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import XCTest

class FormParserTest: XCTestCase {
    func dataWithContentsOfFixture(fileName: String, extensio:String) -> Data  {
        let b = Bundle(for: type(of: self))
        let sub = "testdata" + "/" + String(describing: self.classForCoder)
        guard let u = b.url(forResource: fileName, withExtension: extensio, subdirectory:sub)
            else { return Data() }
        do {
            return try Data(contentsOf: u)
        } catch {
            return Data()
        }
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadfile() {
        let d = dataWithContentsOfFixture(fileName: "login.0", extensio:"html")
        XCTAssertEqual(2509, d.count)
    }

    func testFindForms() {
        let raw = dataWithContentsOfFixture(fileName: "login.0", extensio:"html")
        let frms = findForms(raw, "utf-8")
        XCTAssertEqual(1, frms.count)
        let frm = frms["loginform"]!
        XCTAssertEqual(6, frm.count)
        XCTAssertEqual("", frm["login"])
        XCTAssertEqual("", frm["password"])
        XCTAssertEqual("Login", frm[""])
        XCTAssertEqual("20119241badf78a3dcfa55ae58eab429a5d24bad", frm["token"])
        XCTAssertEqual("", frm["longlastingsession"])
        XCTAssertEqual("http://links.mro.name/", frm["returnurl"])
    }

    func testLinkForm() {
        let raw = dataWithContentsOfFixture(fileName: "link_form.0", extensio:"html")
        let frms = findForms(raw, "utf-8")
        XCTAssertEqual(2, frms.count)
        let frm = frms["linkform"]!
        XCTAssertEqual(10, frm.count)
        XCTAssertEqual([
            "token": "06767bf39b3202f0c32d2dad3249742260c721b2",
            "lf_id": "1",
            "save_edit": "Apply Changes",
            "lf_tags": "opensource software",
            "lf_description": "Welcome to Shaarli! This is your first public bookmark. To edit or delete me, you must first login.\n\nTo learn how to use Shaarli, consult the link \"Documentation\" at the bottom of this page.\n\nYou use the community supported version of the original Shaarli project, by Sebastien Sauvage.",
            "returnurl": "https://demo.shaarli.org/?",
            "lf_linkdate": "20190701_010131",
            "lf_url": "https://shaarli.readthedocs.io",
            "lf_title": "The personal, minimalist, super-fast, database free, bookmarking service",
            "lf_private": ""
            ], frm)
        XCTAssertEqual("https://demo.shaarli.org/?", frm["returnurl"])
    }
}
