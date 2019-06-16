//
//  ShaarliSrvTest.swift
//  ShaarliOSTests
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import XCTest

class ShaarliHtmlClientTest: XCTestCase {
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

    func testUrlEmpty () {
        XCTAssertEqual("", URLEmpty.absoluteString)
    }

    func testUrl() {
        let url = URL(string: "https://uid:pwd@example.com/foo")!
        XCTAssertEqual("https://uid:pwd@example.com/foo", url.absoluteString)
        XCTAssertEqual("https", url.scheme)
        XCTAssertEqual("example.com", url.host)
        XCTAssertEqual("uid", url.user)
        XCTAssertEqual("pwd", url.password)
        XCTAssertEqual("/foo", url.path)
        XCTAssertEqual(nil, url.query)
        XCTAssertEqual(nil, url.fragment)

        var b = URLComponents(string:url.absoluteString)!
        b.user = "foo"
        let u2 = b.url!
        XCTAssertEqual("foo", u2.user)
        XCTAssertEqual("pwd", u2.password)
    }

    func testFormString() {
        let a = [
            URLQueryItem(name: "1", value: "a&b"),
            URLQueryItem(name: "2=2", value: "c=c"),
            URLQueryItem(name: "3", value: "d\nd")
        ]
        XCTAssertEqual("1=a%26b&2%3D2=c%3Dc&3=d%0Ad", formString(a))
    }

    func testFormData() {
        XCTAssertEqual("1=a%26b", String(data: formData(["1":"a&b"]), encoding: .ascii))
        XCTAssertEqual("2%3D2=c%3Dc", String(data: formData(["2=2":"c=c"]), encoding: .ascii))
        XCTAssertEqual("3=d%0Ad", String(data: formData(["3":"d\nd"]), encoding: .ascii))
    }

    func testProbeSunshine() {
        let demo = URL(string:"https://demo:demo@demo.shaarli.org/")! // credentials are public
        // let demo = URL(string:"https://tast:tust@demo.mro.name/shaarli-v0.10.2/")! // credentials are public
        // let demo = URL(string:"https://tast:tust@demo.mro.name/shaarli-v0.41b/")! // credentials are public

        let exp = self.expectation(description: "Probing") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e

        let srv = ShaarliHtmlClient()
        srv.probe(demo, "päng 🚀") { (url, pong, err) in
            exp.fulfill()
            XCTAssertEqual(URL(string:"https://demo.shaarli.org/"), url)
            XCTAssertEqual("päng+🚀", pong)
            XCTAssertEqual("", err)
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}
