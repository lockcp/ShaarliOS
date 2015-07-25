//
// NSUserDefaults+Share.m
// ShaarliCompanion
//
// Created by Marcus Rohrmoser on 18.03.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "NSUserDefaults+Share.h"

@implementation NSUserDefaults(Share)

+(NSUserDefaults *)shaarliDefaults
{
    static NSUserDefaults *_shareDefaults = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
                      _shareDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group." BUNDLE_ID];
                  }
                  );
    NSParameterAssert(_shareDefaults);
    return _shareDefaults;
}


@end
