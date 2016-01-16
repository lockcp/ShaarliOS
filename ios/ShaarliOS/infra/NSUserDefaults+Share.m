//
// NSUserDefaults+Share.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 18.03.15.
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
