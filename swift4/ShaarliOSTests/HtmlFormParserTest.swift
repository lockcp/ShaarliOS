//
//  HtmlFormParserTest.swift
//  ShaarliOSTests
//
//  Created by Marcus Rohrmoser on 09.06.19.
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

import XCTest

class HtmlFormParserTest: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAtt2dict() {
        var ar0:[String?] = [nil]
        let di0 = atts2dict({ ar0[$0] })
        XCTAssertEqual([:], di0)

        var ar1 = ["name", "lf_tags", "value", "opensource software", "foo", nil, nil]
        let di1 = atts2dict({ ar1[$0] })
        XCTAssertEqual("lf_tags", di1["name"])
        XCTAssertEqual("opensource software", di1["value"])
        
        var ar2 = ["type", "checkbox", "name", "Kenntnisse_in", "checked", nil, "value", "HTML", nil]
        let di2 = atts2dict({ ar2[$0] })
        XCTAssertEqual("Kenntnisse_in", di2["name"])
        XCTAssertEqual("HTML", di2["value"])
        XCTAssertEqual("checked", di2["checked"])
    }

    func testLoadfile() {
        let d = dataWithContentsOfFixture(me:self, fileName: "login.0", extensio:"html")
        XCTAssertEqual(2509, d.count)
    }

    func testFindForms() {
        let raw = dataWithContentsOfFixture(me:self, fileName: "login.0", extensio:"html")
        let frms = findHtmlForms(raw, "utf-8")
        XCTAssertEqual(1, frms.count)
        let frm = frms["loginform"]!
        XCTAssertEqual(3, frm.count)
        XCTAssertNil(frm["login"])
        XCTAssertNil(frm["password"])
        XCTAssertEqual("Login", frm[""])
        XCTAssertEqual("20119241badf78a3dcfa55ae58eab429a5d24bad", frm["token"])
        XCTAssertNil(frm["longlastingsession"])
        XCTAssertEqual("http://links.mro.name/", frm["returnurl"])
    }

    func testLinkForm() {
        let raw = dataWithContentsOfFixture(me:self, fileName: "linkform.0", extensio:"html")
        let frms = findHtmlForms(raw, "utf-8")
        XCTAssertEqual(2, frms.count)
        let frm = frms["linkform"]!
        XCTAssertEqual(9, frm.count)
        XCTAssertEqual("06767bf39b3202f0c32d2dad3249742260c721b2", frm["token"], "token")
        XCTAssertEqual("1", frm["lf_id"], "lf_id")
        XCTAssertEqual("Apply Changes", frm["save_edit"], "save_edit")
        XCTAssertEqual("opensource software", frm["lf_tags"], "lf_tags")
        XCTAssertEqual("Welcome to Shaarli! This is your first public bookmark. To edit or delete me, you must first login.\n\nTo learn how to use Shaarli, consult the link \"Documentation\" at the bottom of this page.\n\nYou use the community supported version of the original Shaarli project, by Sebastien Sauvage.", frm["lf_description"], "lf_description")
        XCTAssertEqual("https://demo.shaarli.org/?", frm["returnurl"], "returnurl")
        XCTAssertEqual("20190701_010131", frm["lf_linkdate"], "lf_linkdate")
        XCTAssertEqual("https://shaarli.readthedocs.io", frm["lf_url"], "lf_url")
        XCTAssertEqual("The personal, minimalist, super-fast, database free, bookmarking service", frm["lf_title"], "lf_title")
        XCTAssertNil(frm["lf_private"], "value nil is treated like non-existing")
    }

    func testLinkForm1() {
        let raw = dataWithContentsOfFixture(me:self, fileName: "linkform.1", extensio:"html")
        let frms = findHtmlForms(raw, "utf-8")
        XCTAssertEqual(1, frms.count)
        let frm = frms["linkform"]!
        XCTAssertEqual(1, frm.count)
        XCTAssertEqual("opensource software", frm["lf_tags"], "lf_tags")
    }

    func testConfigForm0() {
        let raw = dataWithContentsOfFixture(me:self, fileName: "configform.0", extensio:"html")
        let frms = findHtmlForms(raw, "utf-8")
        XCTAssertEqual(1, frms.count)
        let frm = frms["configform"]!
        XCTAssertEqual(3, frm.count)
        XCTAssertEqual("🚀 Uhu", frm["title"], "title")
        XCTAssertEqual(nil, frm["continent"], "continent")
        XCTAssertEqual(nil, frm["city"], "city")
    }

    func testAlgebraicSumType() {
        // https://www.metaltoad.com/blog/sum-algebraic-data-types-haskell-and-swift
        // For simplicity sake dictionaries are good enough. Instead https://developer.apple.com/documentation/swift/keyvaluepairs
        enum FieldValue : Equatable {
            case text(String)
            case onoff(Bool)
            case option([String:Bool])
        }
        typealias FieldName = String
        typealias Frm = [FieldName:FieldValue]

        let f : Frm = [
            "foo":FieldValue.text("Foo"),
            "bar":FieldValue.onoff(false),
            "baz":FieldValue.option(["Europe":true, "Africa":false]),
        ]
        XCTAssertEqual(3, f.count, "count")
        XCTAssertEqual(FieldValue.text("Foo"), f["foo"], "text")
        XCTAssertEqual(FieldValue.onoff(false), f["bar"], "bool")

        switch f["foo"]! {
        case .text(let x): XCTAssertEqual("Foo", x)
        default: XCTFail()
        }
        switch f["bar"]! {
        case .onoff(let x): XCTAssertEqual(false, x)
        default: XCTFail()
        }
        switch f["baz"]! {
        case .option(let x):
            XCTAssertEqual(2, x.count)
            XCTAssertEqual(true, x["Europe"])
            XCTAssertEqual(false, x["Africa"])
        default: XCTFail()
        }
    }
}
