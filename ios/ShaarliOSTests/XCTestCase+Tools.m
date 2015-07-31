//
// XCTestCase+Tools.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 31.07.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "XCTestCase+Tools.h"

@implementation XCTestCase(Tools)

-(NSData *)dataWithContentsOfFixture:(NSString *)fileName withExtension:(NSString *)ext
{
    NSBundle *b = [NSBundle bundleForClass:[self class]];
    NSURL *u = [b URLForResource:fileName withExtension:ext subdirectory:[@"testdata" stringByAppendingPathComponent:NSStringFromClass([self class])]];
    return [NSData dataWithContentsOfURL:u];
}


@end
