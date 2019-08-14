//
//  ShaarliHtmlClientTest.swift
//  ShaarliOSTests
//
//  Created by Marcus Rohrmoser on 09.06.19.
//  Copyright © 2019 Marcus Rohrmoser mobile Software. All rights reserved.
//

import XCTest

class ShaarliHtmlClientTest: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        URLSession.shared.reset() { print("URLSession.reset() done.")}
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

        let emo = URL(string: percentEncode(in:"päng 🚀")!)!
        XCTAssertEqual("p%C3%A4ng%20%F0%9F%9A%80", emo.absoluteString)
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

        var frm = ["3":"d\nd", LF_PRI:"on"]
        frm[LF_PRI] = nil
        XCTAssertEqual("3=d%0Ad", String(data: formData(frm), encoding: .ascii))
    }

    func testEncoding() {
        let str = "Hello, wörld!"
        let byt = str.data(using: .utf8, allowLossyConversion: false)!
        XCTAssertEqual(str, String(bytes: byt, encoding:.utf8))
        XCTAssertEqual("Hello, wÃ¶rld!", String(bytes: byt, encoding:.isoLatin1))
    }

    // https://nshipster.com/swift-regular-expressions/
    func testRegex() {
        let ra0 = "Fancy a game of Cluedo™️?".range(of: "Clue(do)?™️?", options:.regularExpression)
        XCTAssertEqual(16, ra0?.lowerBound.encodedOffset)
        
        let msg = "<script>alert(\"foo\"); // bar \");"
        let ra1 = msg.range(of: PAT_WRONG_LOGIN, options:.regularExpression)!
        XCTAssertEqual("<script>alert(\"foo\");", msg[ra1])
    }

    func testProbeSunshine() {
        // let demo = URL(string:"https://demo:demo@demo.shaarli.org/")! // credentials are public
        // let demo = URL(string:"https://tast:tust@demo.mro.name/shaarli-v0.10.2/")! // credentials are public
        // let demo = URL(string:"https://tast:tust@demo.mro.name/shaarli-v0.41b/")! // credentials are public
        let demo = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarligo/shaarligo.cgi")! // credentials are public

        let exp = self.expectation(description: "Probing") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e

        let srv = ShaarliHtmlClient()
        srv.probe(demo) { (url, tit, err) in
            XCTAssertEqual("", err)
            // XCTAssertEqual("https://demo.shaarli.org/", url.absoluteString)
            // XCTAssertEqual("Shaarli demo", tit)

            // XCTAssertEqual("https://demo.mro.name/shaarli-v0.10.2/", url.absoluteString)
            // XCTAssertEqual("https://demo.mro.name/shaarli-v0.41b/", url.absoluteString)
            XCTAssertEqual("https://demo.mro.name/shaarligo/shaarligo.cgi", url.absoluteString)
            XCTAssertEqual("Uhu 🚀", tit)
            exp.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testProbe403() {
        // let demo = URL(string:"https://demo:foo@demo.shaarli.org/")! // credentials are public
        let demo = URL(string:"https://tast:foo@demo.mro.name/shaarli-v0.10.2/")! // credentials are public
        // let demo = URL(string:"https://tast:foo@demo.mro.name/shaarli-v0.41b/")! // credentials are public
        
        let exp = self.expectation(description: "Probing") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e
        
        let srv = ShaarliHtmlClient()
        srv.probe(demo) { (url, pong, err) in
            XCTAssertEqual(URLEmpty, url)
            XCTAssertEqual("", pong)
            XCTAssertEqual("Wrong login/password.", err)
            // XCTAssertEqual(ShaarliHtmlClient.STR_BANNED, err)
            exp.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testProbe404() {
        // let demo = URL(string:"https://demo:foo@demo.shaarli.org/hgr/")! // credentials are public
        // let demo = URL(string:"https://tast:foo@demo.mro.name/shaarli-v0.10.2/")! // credentials are public
        let demo = URL(string:"https://demo.mro.name/bogus")! // credentials are public
        
        let exp = self.expectation(description: "Probing") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e
        
        let srv = ShaarliHtmlClient()
        srv.probe(demo) { (url, pong, err) in
            XCTAssertEqual(URLEmpty, url)
            XCTAssertEqual("", pong)
            XCTAssertEqual("Expected status 200, got 404", err)
            exp.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testGetSunshine() {
        // let demo = URL(string:"https://demo:demo@demo.shaarli.org/")! // credentials are public
        // let url = URL(string:"https://shaarli.readthedocs.io")!

        let demo = URL(string:"https://tast:tust@demo.mro.name/shaarli-v0.10.2/")! // credentials are public
        let url = URL(string:"https://shaarli.readthedocs.io")!

        // let demo = URL(string:"https://tast:tust@demo.mro.name/shaarli-v0.41b/")! // credentials are public
        // let url = URL(string:"http://sebsauvage.net/wiki/doku.php?id=php:shaarli")!

        let exp = self.expectation(description: "Reading") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e

        let srv = ShaarliHtmlClient()
        srv.get(demo, url) { (frm, url, tit, dsc, tgs, pri, err) in
            XCTAssertEqual("https://shaarli.readthedocs.io", url.absoluteString)
            XCTAssertEqual("The personal, minimalist, super-fast, database free, bookmarking service", tit)
            XCTAssertEqual("Welcome to Shaarli! This is your first public bookmark. To edit or delete me, you must first login.\n\nTo learn how to use Shaarli, consult the link \"Documentation\" at the bottom of this page.\n\nYou use the community supported version of the original Shaarli project, by Sebastien Sauvage.", dsc, "why is dsc empty?")
            XCTAssertEqual(["opensource", "software"], tgs)
            XCTAssertFalse(pri)
            XCTAssertEqual("", err)
            // XCTAssertEqual([:], frm)
            exp.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testPostSunshine() {
        // let demo = URL(string:"https://demo:demo@demo.shaarli.org/")! // credentials are public
        // let url = URL(string:"http://idlewords.com/talks/website_obesity.htm#minimalism")!

        let demo = URL(string:"https://tast:tust@demo.mro.name/shaarli-v0.10.2/")! // credentials are public
        let url = URL(string:"http://idlewords.com/talks/website_obesity.htm#minimalism")!

        // let demo = URL(string:"https://tast:tust@demo.mro.name/shaarli-v0.41b/")! // credentials are public
        // let url = URL(string:"http://sebsauvage.net/wiki/doku.php?id=php:shaarli")!

        let exp0 = self.expectation(description: "Reading") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e
        let exp1 = self.expectation(description: "Posting")

        let srv = ShaarliHtmlClient()
        srv.get(demo, url) { (ctx, url, tit, dsc, tgs, pri, err0) in
            XCTAssertEqual("", err0)
            XCTAssertEqual("http://idlewords.com/talks/website_obesity.htm#minimalism", url.absoluteString)
            XCTAssertEqual("The Website Obesity Crisis", tit)
            XCTAssertEqual("", dsc, "why is dsc empty?")
            XCTAssertEqual([], tgs)
            XCTAssertFalse(pri)

            XCTAssertNil(ctx[LF_PRI])
            exp0.fulfill()

            srv.add(demo, ctx, url, tit, dsc, tgs, pri) { err1 in
                XCTAssertEqual("", err1)
                exp1.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
