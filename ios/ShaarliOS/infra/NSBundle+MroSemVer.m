//
// NSBundle+MroSemVer.m
//
// Created by Marcus Rohrmoser on 28.11.13.
// Copyright (c) 2013-2015 Marcus Rohrmoser http://mro.name/me. All rights reserved.
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

#import "NSBundle+MroSemVer.h"

@implementation NSBundle(MroSemVer)

+(NSString *)semVer
{
    NSDictionary *info = [[self mainBundle] infoDictionary];
    // NSString *marketing = info[@"CFBundleShortVersionString"];
    NSString *version = info[@"CFBundleVersion"];
    NSString *build = info[@"CFBundleGitSHA"];
    return [NSString stringWithFormat:@"v%@+%@", version, build, nil];
}


@end
