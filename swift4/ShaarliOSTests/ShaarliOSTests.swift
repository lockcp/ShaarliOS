//
//  ShaarliOSTests.swift
//  ShaarliOSTests
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
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

        XCTAssertEqual("ha", isTag("#ha"))
        XCTAssertEqual("🐳", isTag("🐳"))
        XCTAssertEqual("", isTag("foo#nein"))

        XCTAssertEqual(["ha"], tagsFromString("#ha, 1.2 foo#nein"), "aha")
        XCTAssertEqual(["🐳"], tagsFromString("🐳, foo#nein"), "aha")
        XCTAssertEqual(["$", "§", "†"], tagsFromString("#§, #$ #† foo#nein"), "aha")
        XCTAssertEqual(["🐳"], tagsFromString("#🐳, foo#nein #"), "aha")
        XCTAssertEqual(["ipsum", "opensource", "🐳"], tagsFromString("""
            Lorem #ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.

            Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.

            Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. #opensource #🐳
"""), "ja, genau")
        XCTAssertEqual(["⭐️"], tagsFromString("a single ⭐️ is also a tag"), "aha")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
