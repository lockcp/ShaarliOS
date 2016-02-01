//
// ShaarliMTest.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 19.07.15.
// Copyright (c) 2015-2016 Marcus Rohrmoser http://mro.name/me. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <UIKit/UIKit.h>
#import "XCTestCase+Tools.h"
#import "ShaarliM.h"

#define M_FORM @"form"
#define F_TOKEN F_K_TOKEN
#define M_HAS_LOGOUT @"has_logout"

NSDictionary *parseShaarliHtml(NSData *data, NSError **error);

@interface ShaarliM() <NSURLSessionDataDelegate>
@property (strong, nonatomic) NSURL *endpointURL;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *passWord;
@property (assign, nonatomic) BOOL privateDefault;
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


#if 0
-(void)_testPostData
{
    NSDictionary *d = @ {
        @"key0" : @"val ue",
        @"key1" : @"val?ue",
        @"key2" : @"val&ue",
    };
    XCTAssertEqualObjects(@"key2=val%26ue&key1=val%3Fue&key0=val%20ue", [[NSString alloc] initWithData:[d postData] encoding:NSUTF8StringEncoding], @"");
}


#endif


-(void)testStringByStrippingTags
{
    NSMutableArray *a = [NSMutableArray arrayWithCapacity:10];
    {
        [a removeAllObjects];
        XCTAssertEqualObjects(@"", [@"" stringByStrippingTags:a], @"");
        XCTAssertEqual(0, a.count, @"");
    }
    {
        [a removeAllObjects];
        XCTAssertEqualObjects(@" \n ", [@" \n " stringByStrippingTags:a], @"");
        XCTAssertEqual(0, a.count, @"");
    }
    {
        [a removeAllObjects];
        XCTAssertEqualObjects(@"", [@"  #ShaarliOS  " stringByStrippingTags:a], @"");
        XCTAssertEqual(1, a.count, @"");
        XCTAssertEqualObjects(@"ShaarliOS", a[0], @"");
    }
    {
        [a removeAllObjects];
        XCTAssertEqualObjects(@"foo", [@"#Shaarli💫 #b  #c ##d \nfoo" stringByStrippingTags:a], @"");
        XCTAssertEqual(4, a.count, @"");
        XCTAssertEqualObjects(@"Shaarli💫", a[0], @"");
        XCTAssertEqualObjects(@"b", a[1], @"");
        XCTAssertEqualObjects(@"c", a[2], @"");
        XCTAssertEqualObjects(@"#d", a[3], @"");
    }
}


#if 0
-(void)testHttpGetParams
{
    NSURL *url = [NSURL URLWithString:@"http://links.mro.name/?post=http%3A%2F%2Fww.heise.de%2Fa&title=Ti+tle&description=Des%20crip%20tio=n&source=http%3A%2F%2Fapp.mro.name%2FShaarliOS"];
    NSDictionary *p = [url dictionaryWithHttpFormUrl];
    XCTAssertEqual(4, p.count, @"");
    XCTAssertEqualObjects(@"http://ww.heise.de/a", p[K_F_POST], @"");
    XCTAssertEqualObjects(@"Ti tle", p[K_F_TITLE], @"");
    XCTAssertEqualObjects(@"Des crip tio=n", p[K_F_DESCRIPTION], @"");
    XCTAssertEqualObjects(@"http://app.mro.name/ShaarliOS", p[K_F_SOURCE], @"");

    XCTAssertEqualObjects(@"Des%20crip%20tion", [@"Des crip tion" stringByAddingPercentEscapesForHttpFormUrl], @"hu");

    p = @ {
        @"descr=iption" : @"Des crip tion"
    };
    XCTAssertEqualObjects(@"descr%3Diption=Des%20crip%20tion", [p stringByAddingPercentEscapesForHttpFormUrl], @"hu");
}


-(void)testParseShaarliHtml
{
    {
        NSDictionary *ret = parseShaarliHtml([self dataWithContentsOfFixture:@"testLogin.ok" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(4, ret.count, @"entries' count");
        XCTAssertEqualObjects(@ (1), ret[M_HAS_LOGOUT], @"");
        XCTAssertEqualObjects(@"links.mro", ret[K_F_TITLE], @"");
        XCTAssertNotNil(ret[@"headerform"], @"");
        XCTAssertEqual(5, [ret[M_FORM] count], @"entries' count");
        XCTAssertEqualObjects(@"20150715_200440", ret[M_FORM][@"edit_link"], @"");
        XCTAssertEqualObjects(@"20150715_200440", ret[M_FORM][@"lf_linkdate"], @"");
        XCTAssertEqualObjects(@"", ret[M_FORM][@"searchtags"], @"");
        XCTAssertEqualObjects(@"", ret[M_FORM][@"searchterm"], @"");
        XCTAssertEqualObjects(@"6ff77552e09da9ef31e0e9d0b717da8933f68975", ret[M_FORM][F_K_TOKEN], @"");
    }
    {
        NSDictionary *ret = parseShaarliHtml([self dataWithContentsOfFixture:@"testLogin.0" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(3, ret.count, @"entries' count");
        XCTAssertEqualObjects(@"links.mro", ret[K_F_TITLE], @"");
        XCTAssertNotNil(ret[@"headerform"], @"");
        XCTAssertEqual(2, [ret[M_FORM] count], @"entries' count");
        XCTAssertEqualObjects(@"http://links.mro.name/", ret[M_FORM][F_K_RETURNURL], @"");
        XCTAssertEqualObjects(@"20119241badf78a3dcfa55ae58eab429a5d24bad", ret[M_FORM][F_K_TOKEN], @"");
    }
    {
        NSDictionary *ret = parseShaarliHtml([self dataWithContentsOfFixture:@"05.addlink-1" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(4, ret.count, @"entries' count");
        XCTAssertEqualObjects(@"links.mro", ret[K_F_TITLE], @"");
        XCTAssertEqualObjects(@ (YES), ret[M_HAS_LOGOUT], @"");
        XCTAssertNotNil(ret[@"headerform"], @"");
        XCTAssertEqual(0, [ret[M_FORM] count], @"entries' count");
    }
    {
        NSDictionary *ret = parseShaarliHtml([self dataWithContentsOfFixture:@"05.addlink-2" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(3, ret.count, @"entries' count");
        XCTAssertEqualObjects(@"links.mro", ret[K_F_TITLE], @"");
        XCTAssertEqualObjects(@ (YES), ret[M_HAS_LOGOUT], @"");
        XCTAssertEqual(8, [ret[M_FORM] count], @"entries' count");
        XCTAssertEqualObjects(@"Cancel", ret[M_FORM][@"cancel_edit"], @"");
        XCTAssertEqualObjects(@"20150719_173950", ret[M_FORM][@"lf_linkdate"], @"");
        XCTAssertEqualObjects(@"", ret[M_FORM][K_F_LF_TAGS], @"");
        XCTAssertEqualObjects(@"Note: ", ret[M_FORM][K_F_LF_TITLE], @"");
        XCTAssertEqualObjects(@"?tgI8rw", ret[M_FORM][K_F_LF_URL], @"");
        XCTAssertEqualObjects(@"http://links.mro.name/?do=login&post=", ret[M_FORM][F_K_RETURNURL], @"");
        XCTAssertEqualObjects(@"Save", ret[M_FORM][@"save_edit"], @"");
        XCTAssertEqualObjects(@"e90b4ab4846c221880872003ba47859183da4e6e", ret[M_FORM][F_K_TOKEN], @"");
    }
    {
        NSDictionary *ret = parseShaarliHtml([self dataWithContentsOfFixture:@"banned" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(2, ret.count, @"entries' count");
        XCTAssertEqualObjects(@"links.mro", ret[K_F_TITLE], @"");
        XCTAssertEqualObjects(@"You have been banned from login after too many failed attempts. Try later.", ret[@"headerform"], @"");
        XCTAssertEqual(0, [ret[M_FORM] count], @"entries' count");
    }
}


-(void)testParseHtmlTags
{
    NSDictionary *ret = parseShaarliHtml([self dataWithContentsOfFixture:@"03.tagcloud" withExtension:@"html"], nil);
    // MRLogD(@"%@", ret, nil);
    XCTAssertEqual(2, ret.count, @"entries' count");
    XCTAssertEqualObjects(@"links.mro", ret[K_F_TITLE], @"");
    NSArray *tags = ret[@"tags"];
    MRLogD(@"%@", tags, nil);
    XCTAssertEqual(1794, tags.count, @"");
    {
        NSArray *sorted = [tags sortedArrayUsingComparator:^NSComparisonResult (NSDictionary * t1, NSDictionary * t2) {
                               const NSComparisonResult r0 = [t2[@"count"] compare:t1[@"count"]];
                               if( r0 != NSOrderedSame )
                                   return r0;
                               return [t1[@"label"] compare:t2[@"label"] options:0];
                           }
                          ];
        XCTAssertEqualObjects (@"Software", [sorted firstObject][@"label"], @"");
        XCTAssertEqualObjects (@ (170), [sorted firstObject][@"count"], @"");

        XCTAssertEqualObjects (@"§99StGB", [sorted lastObject][@"label"], @"");
        XCTAssertEqualObjects (@ (1), [sorted lastObject][@"count"], @"");
    }
}


-(void)testGithubIssue5
{
    {
        NSDictionary *ret = parseShaarliHtml([self dataWithContentsOfFixture:@"github-issue#5" withExtension:@"html"], nil);
        XCTAssertNotNil(ret);
        XCTAssertEqual(0, ret.count, @"May be empty, but mustn't crash", nil);
    }
    {
        NSDictionary *ret = parseShaarliHtml([NSData data], nil);
        XCTAssertNotNil(ret);
        XCTAssertEqual(0, ret.count, @"May be empty, but mustn't crash", nil);
    }
    {
        NSDictionary *ret = parseShaarliHtml(nil, nil);
        XCTAssertNotNil(ret);
        XCTAssertEqual(0, ret.count, @"May be empty, but mustn't crash", nil);
    }
}


#endif


@end
