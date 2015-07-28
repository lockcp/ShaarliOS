//
// ShaarliMTest.m
// ShaarliCompanion
//
// Created by Marcus Rohrmoser on 19.07.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ShaarliM.h"


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

@end
