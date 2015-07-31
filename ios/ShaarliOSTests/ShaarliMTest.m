//
// ShaarliMTest.m
// ShaarliCompanion
//
// Created by Marcus Rohrmoser on 19.07.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XCTestCase+Tools.h"
#import "ShaarliM.h"

NSDictionary *parseShaarliHtml(NSData *data, NSError **error);

@interface ShaarliM() <NSURLSessionDataDelegate>
@property (strong, nonatomic) NSURL *endpointUrl;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *passWord;
@end


@interface ShaarliMTest : XCTestCase
@end

@implementation ShaarliMTest


-(void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}


-(void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


-(void)testPostData
{
    NSDictionary *d = @ {
        @"key0" : @"val ue",
        @"key1" : @"val?ue",
        @"key2" : @"val&ue",
    };
    XCTAssertEqualObjects(@"key2=val%26ue&key1=val%3Fue&key0=val%20ue", [[NSString alloc] initWithData:[d postData] encoding:NSUTF8StringEncoding], @"");
}


-(void)testHttpGetParams
{
    NSURL *url = [NSURL URLWithString:@"http://links.mro.name/?post=http%3A%2F%2Fww.heise.de%2Fa&title=Ti+tle&description=Des%20crip%20tio=n&source=http%3A%2F%2Fapp.mro.name%2FShaarliOS"];
    NSDictionary *p = [url dictionaryWithHttpFormUrl];
    XCTAssertEqual(4, p.count, @"");
    XCTAssertEqualObjects(@"http://ww.heise.de/a", p[@"post"], @"");
    XCTAssertEqualObjects(@"Ti tle", p[@"title"], @"");
    XCTAssertEqualObjects(@"Des crip tio=n", p[@"description"], @"");
    XCTAssertEqualObjects(@"http://app.mro.name/ShaarliOS", p[@"source"], @"");

    XCTAssertEqualObjects(@"Des%20crip%20tion", [@"Des crip tion" stringByAddingPercentEscapesForHttpFormUrl], @"hu");

    p = @ {
        @"descr=iption" : @"Des crip tion"
    };
    XCTAssertEqualObjects(@"descr%3Diption=Des%20crip%20tion", [p stringByAddingPercentEscapesForHttpFormUrl], @"hu");
}


-(void)_testLogin
{
    XCTAssertEqualObjects(@"ShaarliMTest", NSStringFromClass([self class]), @"foo");
    XCTAssertEqualObjects(@"testLogin", NSStringFromSelector(_cmd), @"foo");
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}


-(void)testPost
{
    ShaarliM *s = [[ShaarliM alloc] init];

    s.endpointUrl = [NSURL URLWithString:@"http://links.mro.name"];
    s.userName = @"mro";
    s.passWord = @"Jahahw7zahKi";

    [s postURL:[NSURL URLWithString:@"http://example.com"] title:@"example" tags:@[] description:@"description" private:
     YES session:nil completion:^(ShaarliM * me, NSError * error) {
         MRLogD (@"done", nil);
     }
    ];
}


-(void)testParseShaarliHtml
{
    {
        NSDictionary *ret = parseShaarliHtml([self dataWithContentsOfFixture:@"testLogin.ok" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(4, ret.count, @"entries' count");
        XCTAssertEqualObjects(@ (1), ret[M_HAS_LOGOUT], @"");
        XCTAssertEqualObjects(@"links.mro", ret[@"title"], @"");
        XCTAssertNotNil(ret[@"headerform"], @"");
        XCTAssertEqual(5, [ret[M_FORM] count], @"entries' count");
        XCTAssertEqualObjects(@"20150715_200440", ret[M_FORM][@"edit_link"], @"");
        XCTAssertEqualObjects(@"20150715_200440", ret[M_FORM][@"lf_linkdate"], @"");
        XCTAssertEqualObjects(@"", ret[M_FORM][@"searchtags"], @"");
        XCTAssertEqualObjects(@"", ret[M_FORM][@"searchterm"], @"");
        XCTAssertEqualObjects(@"6ff77552e09da9ef31e0e9d0b717da8933f68975", ret[M_FORM][@"token"], @"");
    }
    {
        NSDictionary *ret = parseShaarliHtml([self dataWithContentsOfFixture:@"testLogin.0" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(3, ret.count, @"entries' count");
        XCTAssertEqualObjects(@"links.mro", ret[@"title"], @"");
        XCTAssertNotNil(ret[@"headerform"], @"");
        XCTAssertEqual(2, [ret[M_FORM] count], @"entries' count");
        XCTAssertEqualObjects(@"http://links.mro.name/", ret[M_FORM][@"returnurl"], @"");
        XCTAssertEqualObjects(@"20119241badf78a3dcfa55ae58eab429a5d24bad", ret[M_FORM][@"token"], @"");
    }
    {
        NSDictionary *ret = parseShaarliHtml([self dataWithContentsOfFixture:@"05.addlink-1" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(4, ret.count, @"entries' count");
        XCTAssertEqualObjects(@"links.mro", ret[@"title"], @"");
        XCTAssertEqualObjects(@ (YES), ret[M_HAS_LOGOUT], @"");
        XCTAssertNotNil(ret[@"headerform"], @"");
        XCTAssertEqual(0, [ret[M_FORM] count], @"entries' count");
    }
    {
        NSDictionary *ret = parseShaarliHtml([self dataWithContentsOfFixture:@"05.addlink-2" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(3, ret.count, @"entries' count");
        XCTAssertEqualObjects(@"links.mro", ret[@"title"], @"");
        XCTAssertEqualObjects(@ (YES), ret[M_HAS_LOGOUT], @"");
        XCTAssertEqual(8, [ret[M_FORM] count], @"entries' count");
        XCTAssertEqualObjects(@"Cancel", ret[M_FORM][@"cancel_edit"], @"");
        XCTAssertEqualObjects(@"20150719_173950", ret[M_FORM][@"lf_linkdate"], @"");
        XCTAssertEqualObjects(@"", ret[M_FORM][@"lf_tags"], @"");
        XCTAssertEqualObjects(@"Note: ", ret[M_FORM][@"lf_title"], @"");
        XCTAssertEqualObjects(@"?tgI8rw", ret[M_FORM][@"lf_url"], @"");
        XCTAssertEqualObjects(@"http://links.mro.name/?do=login&post=", ret[M_FORM][@"returnurl"], @"");
        XCTAssertEqualObjects(@"Save", ret[M_FORM][@"save_edit"], @"");
        XCTAssertEqualObjects(@"e90b4ab4846c221880872003ba47859183da4e6e", ret[M_FORM][@"token"], @"");
    }
    {
        NSDictionary *ret = parseShaarliHtml([self dataWithContentsOfFixture:@"banned" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(2, ret.count, @"entries' count");
        XCTAssertEqualObjects(@"links.mro", ret[@"title"], @"");
        XCTAssertEqualObjects(@"You have been banned from login after too many failed attempts. Try later.", ret[@"headerform"], @"");
        XCTAssertEqual(0, [ret[M_FORM] count], @"entries' count");
    }
}


@end
