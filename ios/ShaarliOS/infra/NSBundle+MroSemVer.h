//
// NSBundle+MroSemVer.h
//
// Created by Marcus Rohrmoser on 28.11.13.
// Copyright (c) 2013 Marcus Rohrmoser mobile Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/** `CFBundleShortVersionString`+`CFBundleVersion` according to http://semver.org/spec/v2.0.0.html
 */
@interface NSBundle(MroSemVer)
+(NSString *)semVer;
@end
