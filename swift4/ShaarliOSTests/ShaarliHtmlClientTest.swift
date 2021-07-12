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

private let AGENT = "test"
private let TO : TimeInterval = 4.0

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

        let url1 = URL(string: "a.b")!
        XCTAssertNil(url1.host)
        XCTAssertNil(url1.scheme)
    }

    func testUrlCredential() {
        let cre = URLCredential(user:"", password:"", persistence:.permanent)
        XCTAssertEqual(true, cre.hasPassword)
        XCTAssertEqual("", cre.user)
        XCTAssertEqual("", cre.password)
    }

    func testBasic() {
        let str = httpBasic(URLCredential(user:"usr", password:"pwd", persistence:.forSession))
        XCTAssertEqual("Basic dXNyOnB3ZA==", str)
        guard let cre = httpBasic(str) else {
            XCTFail()
            return
        }
        XCTAssertTrue(cre.hasPassword)
        XCTAssertEqual("usr", cre.user)
        XCTAssertEqual("pwd", cre.password)

        let c : URLCredential? = nil
        XCTAssertNil(httpBasic(c))
        XCTAssertNil(httpBasic(URLCredential(user:"", password:"uhu", persistence:.permanent)))
        XCTAssertEqual("Basic dWh1Og==", httpBasic(URLCredential(user:"uhu", password:"", persistence:.forSession)))
        
        XCTAssertEqual("Basic ZGVtTzpkZW1PZGVtT2RlbU8=", httpBasic(URLCredential(user:"demO", password:"demOdemOdemO", persistence:.forSession)))
    }

    func testFormData() {
        XCTAssertEqual("1=a%26b", String(data: formData(["1":"a&b"]), encoding: .ascii))
        XCTAssertEqual("2%3D2=c%3Dc", String(data: formData(["2=2":"c=c"]), encoding: .ascii))
        XCTAssertEqual("3=d%0Ad", String(data: formData(["3":"d\nd"]), encoding: .ascii))

        var frm = ["3":"d\nd", LF_PRI:"on"]
        frm[LF_PRI] = nil
        XCTAssertEqual("3=d%0Ad", String(data: formData(frm), encoding: .ascii))
    }

    func testFormDataIssue59() {
        let pwd = ":8-$;(B%Z_rM]]?i?p{'+]1|xQk008]$,L}\\z2HxTB^%YpEl"
        let pw1 = ":8-$;(B%Z_rM]]?i?p{\'+]1|xQk008]$,L}\\z2HxTB^%YpEl"
        XCTAssertEqual(pw1, pwd, "literal escaping")
        // $ curl --trace-ascii - --data-urlencode password=':8-$;(B%Z_rM]]?i?p{\'+]1|xQk008]$,L}\\z2HxTB^%YpEl' https://demo.mro.name/
        let pwcurl = "%3A8-%24%3B%28B%25Z_rM%5D%5D%3Fi%3Fp%7B%27%2B%5D1%7CxQk008%5D%24%2CL%7D%5Cz2HxTB%5E%25YpEl"
        let pwok__ = "%3A8-%24%3B(B%25Z_rM%5D%5D%3Fi%3Fp%7B\'%2B%5D1%7CxQk008%5D%24%2CL%7D%5Cz2HxTB%5E%25YpEl"

        XCTAssertEqual("password=\(pwok__)", String(data: formData(["password":pwd]), encoding: .ascii))
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
        uc.host = "demo.mro.name"
        uc.port = 8443
        uc.user = "demo"
        uc.password = "demo -/:;&@\"$#%"
        uc.path = "/shaarli-v0.11.1-issue28/"
        uc.query = nil
        uc.fragment = nil
        XCTAssertEqual("https://demo:demo%20-%2F%3A;&%40%22$%23%25@demo.mro.name:8443/shaarli-v0.11.1-issue28/", uc.url?.absoluteString)

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
        let demo = URL(string:"https://demo:demo@demo.shaarli.org/")! // credentials are public
        // let demo = URL(string:"https://demo:demodemodemo@demo.mro.name:8443/shaarli-v0.10.2/")! // credentials are public
        // let demo = URL(string:"https://demo:demo@shaarli-next.hoa.ro/")! // credentials are public
        // let demo = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarli-v0.41b/")! // credentials are public
        // let demo = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarligo/")! // credentials are public

        let exp = self.expectation(description: "Probing") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e

        let srv = ShaarliHtmlClient(AGENT)
        srv.probe(demo, nil, TO) { (url, tit, pride, tizo, err) in
            XCTAssertEqual("", err)
            // XCTAssertEqual("https://demo.shaarli.org/", url.absoluteString)
            XCTAssertEqual("Shaarli demo", tit)

            //XCTAssertEqual("https://demo:demodemodemo@demo.mro.name:8443/shaarli-v0.10.2/", url.absoluteString)
            XCTAssertEqual("https://demo:demo@demo.shaarli.org/", url.absoluteString)
            // XCTAssertEqual("https://demo:demo@shaarli-next.hoa.ro/", url.absoluteString)
            // XCTAssertEqual("https://demo:demodemodemo@demo.mro.name:8443/shaarli-v0.41b/", url.absoluteString)
            // XCTAssertEqual("https://demo:demodemodemo@demo.mro.name/shaarligo/shaarligo.cgi", url.absoluteString)
            // XCTAssertEqual("ShaarliGo 🚀", tit)
            XCTAssertEqual(false, pride)
            XCTAssertEqual(nil, tizo?.identifier)
            // XCTAssertEqual("Europe/Paris", tizo?.identifier)
            exp.fulfill()
            return
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testProbeSunshineIssue28() {
        var uc = URLComponents(string: "")!
        uc.scheme = HTTP_HTTPS
        uc.host = "demo.mro.name"
        uc.port = 8443
        uc.path = "/shaarli-v0.11.1-issue28/"
        // credentials are public
        uc.user = "demo"
        uc.password = "demo -/:;&@\"$#%"
        XCTAssertEqual("https://demo:demo%20-%2F%3A;&%40%22$%23%25@demo.mro.name:8443/shaarli-v0.11.1-issue28/", uc.url?.absoluteString)
        let demo = uc.url!
        XCTAssertEqual("demo", demo.user)
        XCTAssertEqual("demo%20-%2F%3A;&%40%22$%23%25", demo.password)
        let exp = self.expectation(description: "Probing") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e

        let srv = ShaarliHtmlClient(AGENT)
        srv.probe(demo, nil, TO) { (url, tit, pride, tizo, err) in
            XCTAssertEqual("", err)
            XCTAssertEqual("https://demo:demo%20-%2F%3A;&%40%22$%23%25@demo.mro.name:8443/shaarli-v0.11.1-issue28/", url.absoluteString)
            XCTAssertEqual(false, pride)
            XCTAssertEqual("Europe/Berlin", tizo?.identifier)
            exp.fulfill()
            return
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testProbe403() {
        // let demo = URL(string:"https://demo:foo@demo.shaarli.org/")! // credentials are public
        let demo = URL(string:"https://tast:foo@demo.mro.name/shaarli-v0.10.2/")! // credentials are public
        // let demo = URL(string:"https://tast:foo@demo.mro.name/shaarli-v0.41b/")! // credentials are public
        
        let exp = self.expectation(description: "Probing") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e
        
        let srv = ShaarliHtmlClient(AGENT)
        srv.probe(demo, nil, TO) { (url, pong, pride, tizo, err) in
            XCTAssertEqual(URLEmpty, url)
            XCTAssertEqual("", pong)
            XCTAssertEqual("Wrong login/password.", err)
            XCTAssertEqual(false, pride)
            XCTAssertEqual(nil, tizo?.identifier)
            // XCTAssertEqual(ShaarliHtmlClient.STR_BANNED, err)
            exp.fulfill()
            return
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testProbe404() {
        // let demo = URL(string:"https://demo:foo@demo.shaarli.org/hgr/")! // credentials are public
        // let demo = URL(string:"https://tast:foo@demo.mro.name/shaarli-v0.10.2/")! // credentials are public
        let demo = URL(string:"https://demo.mro.name/bogus")! // credentials are public
        
        let exp = self.expectation(description: "Probing") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e
        
        let srv = ShaarliHtmlClient(AGENT)
        srv.probe(demo, nil, TO) { (url, pong, pride, tizo, err) in
            XCTAssertEqual(URLEmpty, url)
            XCTAssertEqual("", pong)
            XCTAssertEqual("Expected response HTTP status '200 Ok' but got '404 not found'", err)
            XCTAssertEqual(false, pride)
            XCTAssertEqual(nil, tizo?.identifier)
            exp.fulfill()
            return
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testGetSunshine() {
        // let end = URL(string:"https://demo:demo@demo.shaarli.org/")! // credentials are public
        // let end = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarli-v0.11.1/")! // credentials are public
        // let end = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarli-v0.10.4/")! // credentials are public
        // let end = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarli-v0.10.2/")! // credentials are public
        // let end = URL(string:"https://demo:demodemodemo@demo.mro.name:8443/shaarli-v0.10.2/")! // credentials are public
        let end = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarli-v0.41b/")! // credentials are public
        // let end = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarligo")! // credentials are public
        let url = URL(string:"https://shaarli.readthedocs.io")!

        let cre = URLCredential(user:"demO", password:"demOdemOdemO", persistence:.forSession)

        let exp = self.expectation(description: "Reading") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e

        let srv = ShaarliHtmlClient(AGENT)
        srv.get(end, cre, TO, url) { (_, act, frm, url, tit, dsc, tgs, pri, tim, seti, err) in
            XCTAssertEqual("https://demo.mro.name/shaarli-v0.41b/?post=https%3A%2F%2Fshaarli.readthedocs.io", act.absoluteString)
            XCTAssertEqual("https://shaarli.readthedocs.io", url.absoluteString)
            XCTAssertEqual("", tit)
            XCTAssertEqual([], tgs)
            XCTAssertFalse(pri)
            XCTAssertEqual("", err)
            // XCTAssertEqual([:], frm)
            exp.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testPostSunshine() {
        // let end = URL(string:"https://demo:demo@demo.shaarli.org/")! // credentials are public
        // let end = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarli-v0.11.1/")! // credentials are public
        // let end = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarli-v0.10.4/")! // credentials are public
        // let end = URL(string:"https://demo:demo@shaarli-next.hoa.ro/")! // credentials are public
        // let end = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarli-v0.10.2/")! // credentials are public
        // let end = URL(string:"https://demo:demodemodemo@demo.mro.name:8443/shaarli-v0.10.2/")! // credentials are public
        let end = URL(string:"https://demo:demodemodemo@demo.mro.name/shaarli-v0.41b/")! // credentials are public
        let url = URL(string:"http://idlewords.com/talks/website_obesity.htm?foo=bar#minimalism")!

        let exp0 = self.expectation(description: "Reading") // https://medium.com/@johnsundell/unit-testing-asynchronous-swift-code-9805d1d0ac5e
        let exp1 = self.expectation(description: "Posting")

        let srv = ShaarliHtmlClient(AGENT)
        srv.get(end, nil, TO, url) { (ses, act, frm, url, tit, dsc, tgs, pri, tim, seti, err0) in
            XCTAssertEqual("", err0)
            // XCTAssertEqual("http://idlewords.com/talks/website_obesity.htm#minimalism", url.absoluteString)
            XCTAssertEqual("http://idlewords.com/talks/website_obesity.htm?foo=bar#minimalism", url.absoluteString)
            // XCTAssertEqual("The Website Obesity Crisis", tit)
            XCTAssertEqual("", dsc, "why is dsc empty?")
            XCTAssertEqual([], tgs)
            //XCTAssertFalse(pri)

            //XCTAssertNil(ctx[LF_PRI])
            exp0.fulfill()

            srv.add(ses, act, frm, url, tit, dsc, tgs, pri) { err1 in
                XCTAssertEqual("", err1)
                exp1.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testTime() {
        let cli = ShaarliHtmlClient(AGENT)
        let tz = TimeZone(secondsFromGMT:2*60*60)!

        XCTAssertNil(cli.timeShaarli(tz, nil))
        XCTAssertNil(cli.timeShaarli(tz, "bogus"))
        XCTAssertNil(cli.timeShaarli(tz, ""))
        XCTAssertEqual("2021-04-07 14:15:06 +0000", cli.timeShaarli(tz, "20210407_161506")?.description)
    }
}
