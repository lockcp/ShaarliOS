//
// ShaarliResponseXsltTest.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 02.08.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <libxml2/libxml/HTMLparser.h>

/** getting xslt iss a bit a pain: http://stackoverflow.com/questions/7895157/applying-xslt-to-an-xml-coming-from-a-webservice-in-ios
 */

@interface ShaarliResponseXsltTest : XCTestCase
@end

@implementation ShaarliResponseXsltTest

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


-(void)testExample
{
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}


-(void)testPerformanceExample
{
    // This is an example of a performance test case.
    [self measureBlock:^{
         // Put the code you want to measure the time of here.
     }
    ];
}


@end
