//
// ShaarliPostResponseTest.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 12.10.15.
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
#import "ShaarliCmdPost.h"

@interface ShaarliCmdPostTest : XCTestCase
@end

// There's three steps to a post:
// - ?post
// - do=login
// - do=post
//
// Each has sunshine and error cases (with and without recovery).
//
// The three are linked together, dependant if it's just a connection/login probe or a real post.
@implementation ShaarliCmdPostTest

-(void)testExample
{
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}


@end
