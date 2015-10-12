//
// ShaarliResponseXsltTest.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 02.08.15.
// Copyright (c) 2015 Marcus Rohrmoser http://mro.name/me. All rights reserved.
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
#import <XCTest/XCTest.h>

#import <libxml2/libxml/HTMLparser.h>

/** getting xslt is a bit a pain: http://stackoverflow.com/questions/7895157/applying-xslt-to-an-xml-coming-from-a-webservice-in-ios
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
