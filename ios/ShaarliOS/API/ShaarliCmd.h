//
// ShaarliCmd.h
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

#import <Foundation/Foundation.h>

@interface NSURL(CmdBuilder)
-(NSURL *)urlForCommand:(NSString *)cmd;
-(NSString *)stripSchemeAndCommand:(NSString *)cmd;
@end

@interface NSString(HttpGetParams)
-(NSString *)stringByAddingPercentEscapesForHttpFormUrl;
@end
@interface NSURL(HttpGetParams)
-(NSDictionary *)dictionaryWithHttpFormUrl;
@end
@interface NSDictionary(HttpGetParams)
-(NSString *)stringByAddingPercentEscapesForHttpFormUrl;
@end
@interface NSDictionary(HttpPostData)
-(NSData *)postData;
@end

@interface NSURL(ProtectionSpace)
@property (nonatomic, readonly, assign) NSURLProtectionSpace *protectionSpace;
@end

@interface ShaarliCmd : NSObject

@property (nonatomic, readonly, strong) NSURLResponse *response;

/** The current 'main' form name. */
@property (nonatomic, readwrite, strong) NSString *form;

/** That's a bit shaky, avoid relying on it. */
@property (nonatomic, readonly, assign) BOOL hasLogOutLink;

-(instancetype)initWithResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error;
-(NSString *)fetchTitle:(NSError **)error;
-(NSMutableDictionary *)fetchForm:(NSString *)formName error:(NSError **)error;
-(NSMutableDictionary *)fetchForm:(NSError **)error;
-(NSString *)fetchToken:(NSError **)error;
-(BOOL)receivedPost1Response:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error;

-(BOOL)parseAnyResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error;
-(BOOL)booleanForXPath:(NSString *)xpath error:(NSError **)error;

@end
