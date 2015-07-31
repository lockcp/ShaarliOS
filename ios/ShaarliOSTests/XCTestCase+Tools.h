//
// XCTestCase+Tools.h
// ShaarliOS
//
// Created by Marcus Rohrmoser on 31.07.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface XCTestCase(Tools)
-(NSData *)dataWithContentsOfFixture:(NSString *)fileName withExtension:(NSString *)ext;
@end
