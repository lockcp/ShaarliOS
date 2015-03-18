//
// NSBundle+MroSemVer.m
//
// Created by Marcus Rohrmoser on 28.11.13.
// Copyright (c) 2013 Marcus Rohrmoser mobile Software. All rights reserved.
//

#import "NSBundle+MroSemVer.h"

@implementation NSBundle(MroSemVer)

+(NSString *)semVer
{
    NSDictionary *info = [[self mainBundle] infoDictionary];
    NSString *marketing = info[@"CFBundleShortVersionString"];
    // NSString *version = info[@"CFBundleVersion"];
    // NSString *build = info[@"CFBundleVersionGitSHA"];
    return [NSString stringWithFormat:@"v%@", marketing, nil];
}


@end
