//
// NSBundle+MroSemVer.h
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

#import <Foundation/Foundation.h>

/** `CFBundleShortVersionString`+`CFBundleVersion` according to http://semver.org/spec/v2.0.0.html
 */
@interface NSBundle(MroSemVer)
+(NSString *)semVer;
@end
