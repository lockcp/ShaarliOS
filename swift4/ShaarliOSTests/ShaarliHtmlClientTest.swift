//
//  ShaarliHtmlClientTest.swift
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

        let url1 = URL(string: "a.b")!
        XCTAssertNil(url1.host)
        XCTAssertNil(url1.scheme)
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

    func testUrlEscaping() {
        var uc = URLComponents(string: "scheme://uid:pwd@host:123/path?q=s#frag")!
        uc.user = "my uid_with_:_/_@_?_&_$_ä_🚀_end"
        uc.password = "my pwd_with_:_/_@_?_&_$_ä_🚀_end"
        XCTAssertEqual("scheme://my%20uid_with_%3A_%2F_%40_%3F_&_$_%C3%A4_%F0%9F%9A%80_end:my%20pwd_with_%3A_%2F_%40_%3F_&_$_%C3%A4_%F0%9F%9A%80_end@host:123/path?q=s#frag", uc.url?.absoluteString)
        XCTAssertEqual("my pwd_with_:_/_@_?_&_$_ä_🚀_end", uc.password)

        uc.scheme = HTTP_HTTPS
        uc.host = "demo.0x4c.de"
        uc.port = 8443
        uc.user = "demo"
        uc.password = "demo -/:;&@\"$#%"
        uc.path = "/shaarli-v0.11.1-issue28/"
        uc.query = nil
        uc.fragment = nil
        XCTAssertEqual("https://demo:demo%20-%2F%3A;&%40%22$%23%25@demo.0x4c.de:8443/shaarli-v0.11.1-issue28/", uc.url?.absoluteString)

        let u2 = uc.url!
        XCTAssertEqual(uc.scheme, u2.scheme)
        XCTAssertEqual(uc.host, u2.host)
        XCTAssertEqual(uc.port, u2.port)
        XCTAssertEqual(uc.user, u2.user)
        XCTAssertEqual("demo%20-%2F%3A;&%40%22$%23%25", u2.password) // URL.password is raw!
        XCTAssertEqual("/shaarli-v0.11.1-issue28", u2.path)
        XCTAssertEqual(uc.query, u2.query)
        XCTAssertEqual(uc.fragment, u2.fragment)
    }

    // https://nshipster.com/swift-regular-expressions/
    func testRegex() {
        let ra0 = "Fancy a game of Cluedo™️?".range(of: "Clue(do)?™️?", options:.regularExpression)
        XCTAssertEqual(16, ra0?.lowerBound.encodedOffset)

        let msg = "<script>alert(\"foo\"); // bar \");"
        let ra1 = msg.range(of: PAT_WRONG_LOGIN, options:.regularExpression)!
        XCTAssertEqual("<script>alert(\"foo\");", msg[ra1])
    }

    func testResponseLoginFormSunshine() {
        let raw = dataWithContentsOfFixture(me:self, fileName: "login.0", extensio:"html")
        let re = HTTPURLResponse(url: URLEmpty, statusCode: 200, httpVersion: "1.1", headerFields:[
            "Content-Type":"text/html; charset=utf-8",
            "Content-Length":"\(raw.count)",
        ])!
        XCTAssertEqual(200, re.statusCode)
        XCTAssertEqual("text/html", re.mimeType)
        XCTAssertEqual("utf-8", re.textEncodingName)
        XCTAssertEqual(2509, re.expectedContentLength)
        let res = check(raw, re, nil)
        XCTAssertEqual("", res.1)
        XCTAssertEqual(1, res.0.count)
        guard let lifo = res.0[LOGIN_FORM] else {
            XCTFail()
            return
        }
        XCTAssertEqual(3, lifo.count)
        XCTAssertEqual("http://links.mro.name/", lifo["returnurl"])
        XCTAssertEqual("Login", lifo[""])
        XCTAssertEqual("20119241badf78a3dcfa55ae58eab429a5d24bad", lifo["token"])
    }

    func testResponseLoginFormBanned() {
        let raw = dataWithContentsOfFixture(me:self, fileName: "login.banned", extensio:"html")
        let re = HTTPURLResponse(url: URLEmpty, statusCode: 200, httpVersion: "1.1", headerFields:[
            "Content-Type":"text/html; charset=utf-8",
            "Content-Length":"\(raw.count)",
            ])!
        XCTAssertEqual(200, re.statusCode)
        XCTAssertEqual("text/html", re.mimeType)
        XCTAssertEqual("utf-8", re.textEncodingName)
        XCTAssertEqual(1982, re.expectedContentLength)
        let res = check(raw, re, nil)
        XCTAssertEqual("You have been banned from login after too many failed attempts. Try later.", res.1)
        XCTAssertEqual(0, res.0.count)
    }

    func testProbeSunshine() {
        // let demo = URL(string:"https://demo:demo@demo.shaarli.org/")! // credentials are public
        let demo = URL(string:"https://demo:demodemodemo@demo.0x4c.de:8443/shaarli-v0.10.2/")! // credentials are public
        // let demo = URL(string:"https://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/")! // credentials are public
        // let demo = URL(string:"https://demo:demodemodemo@demo.0x4c.de/shaarligo/")! // credentials are public

        let exp = self.expectation(description: "Probing") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e

        let srv = ShaarliHtmlClient()
        srv.probe(demo) { (url, tit, err) in
            XCTAssertEqual("", err)
            // XCTAssertEqual("https://demo.shaarli.org/", url.absoluteString)
            // XCTAssertEqual("Shaarli demo", tit)

            XCTAssertEqual("https://demo:demodemodemo@demo.0x4c.de:8443/shaarli-v0.10.2/", url.absoluteString)
            // XCTAssertEqual("https://demo:demodemodemo@demo.0x4c.de:8443/shaarli-v0.41b/", url.absoluteString)
            // XCTAssertEqual("https://demo:demodemodemo@demo.0x4c.de/shaarligo/shaarligo.cgi", url.absoluteString)
            // XCTAssertEqual("ShaarliGo 🚀", tit)
            exp.fulfill()
            return true
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testProbeSunshineIssue28() {
        var uc = URLComponents(string: "")!
        uc.scheme = HTTP_HTTPS
        uc.host = "demo.0x4c.de"
        uc.port = 8443
        uc.path = "/shaarli-v0.11.1-issue28/"
        // credentials are public
        uc.user = "demo"
        uc.password = "demo -/:;&@\"$#%"
        XCTAssertEqual("https://demo:demo%20-%2F%3A;&%40%22$%23%25@demo.0x4c.de:8443/shaarli-v0.11.1-issue28/", uc.url?.absoluteString)
        let demo = uc.url!
        XCTAssertEqual("demo", demo.user)
        XCTAssertEqual("demo%20-%2F%3A;&%40%22$%23%25", demo.password)
        let exp = self.expectation(description: "Probing") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e

        let srv = ShaarliHtmlClient()
        srv.probe(demo) { (url, tit, err) in
            XCTAssertEqual("", err)
            XCTAssertEqual("https://demo:demo%20-%2F%3A;&%40%22$%23%25@demo.0x4c.de:8443/shaarli-v0.11.1-issue28/", url.absoluteString)
            exp.fulfill()
            return true
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testProbe403() {
        // let demo = URL(string:"https://demo:foo@demo.shaarli.org/")! // credentials are public
        let demo = URL(string:"https://tast:foo@demo.0x4c.de/shaarli-v0.10.2/")! // credentials are public
        // let demo = URL(string:"https://tast:foo@demo.mro.name/shaarli-v0.41b/")! // credentials are public
        
        let exp = self.expectation(description: "Probing") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e
        
        let srv = ShaarliHtmlClient()
        srv.probe(demo) { (url, pong, err) in
            XCTAssertEqual(URLEmpty, url)
            XCTAssertEqual("", pong)
            XCTAssertEqual("Wrong login/password.", err)
            // XCTAssertEqual(ShaarliHtmlClient.STR_BANNED, err)
            exp.fulfill()
            return true
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testProbe404() {
        // let demo = URL(string:"https://demo:foo@demo.shaarli.org/hgr/")! // credentials are public
        // let demo = URL(string:"https://tast:foo@demo.mro.name/shaarli-v0.10.2/")! // credentials are public
        let demo = URL(string:"https://demo.0x4c.de/bogus")! // credentials are public
        
        let exp = self.expectation(description: "Probing") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e
        
        let srv = ShaarliHtmlClient()
        srv.probe(demo) { (url, pong, err) in
            XCTAssertEqual(URLEmpty, url)
            XCTAssertEqual("", pong)
            XCTAssertEqual("Expected status 200, got 404: 'not found'", err)
            exp.fulfill()
            return true
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testGetSunshine() {
        let demo = URL(string:"https://demo:demo@demo.shaarli.org/")! // credentials are public
        let url = URL(string:"https://shaarli.readthedocs.io")!

        // let demo = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarli-v0.10.2/")! // credentials are public
        // let url = URL(string:"https://shaarli.readthedocs.io")!

        // let demo = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarli-v0.41b/")! // credentials are public
        // let url = URL(string:"http://sebsauvage.net/wiki/doku.php?id=php:shaarli")!

        // let demo = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarligo/shaarligo.cgi")! // credentials are public
        // let url = URL(string:"http://sebsauvage.net/wiki/doku.php?id=php:shaarli")!

        let exp = self.expectation(description: "Reading") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e

        let srv = ShaarliHtmlClient()
        srv.get(demo, url) { (_, frm, url, tit, dsc, tgs, pri, err) in
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
        let end = URL(string:"https://demo:demo@demo.shaarli.org/")! // credentials are public
        // let end = URL(string:"https://demo:demodemodemo@demo.0x4c.de:8443/shaarli-v0.10.2/")! // credentials are public
        let url = URL(string:"http://idlewords.com/talks/website_obesity.htm#minimalism")!

        // let demo = URL(string:"https://tast:tust@demo.mro.name/shaarli-v0.10.2/")! // credentials are public
        // let url = URL(string:"http://idlewords.com/talks/website_obesity.htm#minimalism")!

        // let demo = URL(string:"https://tast:tust@demo.mro.name/shaarli-v0.41b/")! // credentials are public
        // let url = URL(string:"http://sebsauvage.net/wiki/doku.php?id=php:shaarli")!

        // let demo = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarligo/shaarligo.cgi")! // credentials are public
        // let url = URL(string:"http://idlewords.com/talks/website_obesity.htm#minimalism")!

        let exp0 = self.expectation(description: "Reading") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e
        let exp1 = self.expectation(description: "Posting")

        let srv = ShaarliHtmlClient()
        srv.get(end, url) { (ses, ctx, url, tit, dsc, tgs, pri, err0) in
            XCTAssertEqual("", err0)
            XCTAssertEqual("http://idlewords.com/talks/website_obesity.htm#minimalism", url.absoluteString)
            XCTAssertEqual("The Website Obesity Crisis", tit)
            XCTAssertEqual("", dsc, "why is dsc empty?")
            XCTAssertEqual([], tgs)
            XCTAssertFalse(pri)

            XCTAssertNil(ctx[LF_PRI])
            exp0.fulfill()

            srv.add(ses, end, ctx, url, tit, dsc, tgs, pri) { err1 in
                XCTAssertEqual("", err1)
                exp1.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
