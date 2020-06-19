//
//  ShaarliOSTests.swift
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
@testable import ShaarliOS

func dataWithContentsOfFixture(me mu:AnyObject, fileName: String, extensio:String) -> Data  {
    precondition(true, "Never happens")
    let ty:AnyObject.Type = type(of: mu)
    let bu = Bundle(for: ty)
    let sub = "testdata/\(String(describing: ty))"
    guard let ur = bu.url(forResource: fileName, withExtension: extensio, subdirectory:sub)
        else { return Data() }
    do {
        return try Data(contentsOf: ur)
    } catch {
        return Data()
    }
}

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

    func testEnumerateSubstrings() {
        var a:[String] = []
        let str = "#You shouldn’t do that"
        // https://medium.com/@sorenlind/three-ways-to-enumerate-the-words-in-a-string-using-swift-7da5504f0062
        str.enumerateSubstrings(in: str.startIndex..<str.endIndex, options:.byWords) { sub, _, _, _ in
            a.append(sub ?? "")
        }
        XCTAssertEqual(["You", "shouldn’t", "do", "that"], a)
    }

    func testScanUpToCharacters() {
        let sc = Scanner(string:"#You shouldn’t do that")
        let set = CharacterSet.whitespacesAndNewlines

        var value: NSString?
        guard sc.scanUpToCharacters(from: set, into: &value) else { return }
        let dst = value as String?

        XCTAssertEqual("#You", dst)
    }

    func testTagsFromString() {
        // -(NSString *)stringByStrippingTags:(NSMutableArray *)tags
        // https://code.mro.name/mro/ShaarliOS/src/e9009ef466582e806b97d723e5acea885eaa4c7d/ios/ShaarliOS/ShaarliM.m#L33
        // tagsFromString
        // https://code.mro.name/mro/ShaarliGo/src/c65e142dda32bac7cec02deedc345b8f32a2cf8e/atom.go#L495
        // https://code.mro.name/mro/ShaarliGo/src/c65e142dda32bac7cec02deedc345b8f32a2cf8e/atom_test.go#L44
        // api0LinkForMap
        // https://code.mro.name/mro/ShaarliGo/src/c65e142dda32bac7cec02deedc345b8f32a2cf8e/api0.go#L432

        XCTAssertEqual("ha", isTag(word:"#ha"))
        XCTAssertEqual("🐳", isTag(word:"🐳"))
        XCTAssertEqual("", isTag(word:"foo#nein"))

        XCTAssertEqual("><(((°>", isTag(word:"#><(((°>"))
        XCTAssertEqual("F#", isTag(word:"#F#"))
        XCTAssertEqual("#F#", isTag(word:"##F#"))

        XCTAssertEqual(["ha"], tagsFrom(string:"#ha, 1.2 foo#nein"), "aha")
        XCTAssertEqual(["🐳"], tagsFrom(string:"🐳, foo#nein"), "aha")
        XCTAssertEqual(["$", "§", "†"], tagsFrom(string:"#§, #$ #† foo#nein"), "aha")
        XCTAssertEqual(["🐳"], tagsFrom(string:"#🐳, foo#nein #"), "aha")
        XCTAssertEqual(["ipsum", "opensource", "🐳"], tagsFrom(string:"""
            Lorem #ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.

            Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.

            Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. #opensource #🐳
"""), "ja, genau")
        XCTAssertEqual(["⭐️"], tagsFrom(string:"a single ⭐️ is also a tag"), "aha")
    }

    func testFold() {
        XCTAssertEqual("hallo wyrld!", fold(lbl:" Hälló wÿrld! "))
        XCTAssertEqual("demaiziere", fold(lbl:" DeMaizière \n"))
        XCTAssertEqual("cegłowski", fold(lbl:"\tCegłowski"))
    }

    func testTagsNormalise() {
        let n0 = tagsNormalise(description:"#A", extended:"#B #C", tags:["a", "c", "D"], known:["c"])
        XCTAssertEqual("#A", n0.description)
        XCTAssertEqual("#B #C\n#D", n0.extended)
        XCTAssertEqual(["B", "D", "a", "c"], n0.tags.sorted())

        let n1 = tagsNormalise(description:"", extended:"📱 #Shaarli💫", tags:[], known:[])
        XCTAssertEqual("", n1.description)
        XCTAssertEqual("📱 #Shaarli💫", n1.extended)
        XCTAssertEqual(["Shaarli💫", "📱"], n1.tags)

        let n2 = tagsNormalise(description:"", extended:"", tags:n1.tags, known:[])
        XCTAssertEqual("", n2.description)
        XCTAssertEqual("#Shaarli💫 📱", n2.extended)
        XCTAssertEqual(["Shaarli💫", "📱"], n2.tags)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
