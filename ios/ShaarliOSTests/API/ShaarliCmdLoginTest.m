//
// ShaarliLoginResponseTest.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 12.10.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XCTestCase+Tools.h"
#import "ShaarliCmdLogin.h"

@interface ShaarliCmdLoginTest : XCTestCase
@end

@implementation ShaarliCmdLoginTest

-(void)testLoginSunshineCase
{
    NSError *err = nil;
    ShaarliCmdLogin *r = [[ShaarliCmdLogin alloc] initWithResponse:nil data:[self dataWithContentsOfFixture:@"testLogin.0" withExtension:@"html"] error:&err];
    XCTAssertNotNil(r);
    XCTAssertNil(err);
    XCTAssert(!r.hasLogOutLink, @"");
    XCTAssertEqualObjects(@"links.mro", [r fetchTitle:&err], @"");
    XCTAssertNil(err);

    XCTAssertEqualObjects(@"20119241badf78a3dcfa55ae58eab429a5d24bad", [r fetchToken:&err], @"");

    NSDictionary *form = [r fetchForm:&err];
    XCTAssertNil(err);
    XCTAssertEqual(5, form.count, @"");
    XCTAssertEqualObjects(@"20119241badf78a3dcfa55ae58eab429a5d24bad", form[@"token"], @"");
    XCTAssertEqualObjects(@"http://links.mro.name/", form[@"returnurl"], @"");
    XCTAssertEqualObjects(@"", form[@"login"], @"");
    XCTAssertEqualObjects(@"", form[@"password"], @"");
    XCTAssertEqualObjects(@"", form[@"longlastingsession"], @"");

    XCTAssert([r receivedPost1Response:nil data:[self dataWithContentsOfFixture:@"testLogin.ok" withExtension:@"html"] error:&err], @"");
    XCTAssert(r.hasLogOutLink, @"");
#if 0
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
#endif
}


@end
