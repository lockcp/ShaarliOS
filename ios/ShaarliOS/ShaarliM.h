//
// ShaarliM.h
// ShaarliOS
//
// Created by Marcus Rohrmoser on 17.07.15.
// Copyright (c) 2015 Marcus Rohrmoser http://mro.name/me. All rights reserved.
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

@interface NSString(StripShaarliTags)
-(NSString *)stringByStrippingTags:(NSMutableArray *)tags;
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

@class ShaarliM;

@protocol ShaarliPostDelegate <NSObject>
-(void)shaarli:(ShaarliM *)shaarli didFinishPostWithError:(NSError *)error;
/** fetched late during post. */
@property (readonly, assign, nonatomic) BOOL postPrivate;
@end

@interface ShaarliM : NSObject <NSURLSessionDelegate>
    // configured
@property (readonly, strong, nonatomic) NSString *userName;
@property (readonly, strong, nonatomic) NSString *passWord;
@property (readonly, strong, nonatomic) NSURL *endpointUrl;
@property (readonly, strong, nonatomic) NSString *endpointStr;
@property (readonly, assign, nonatomic) BOOL isSetUp;
@property (readonly, assign, nonatomic) BOOL endpointSecure;
@property (readonly, assign, nonatomic) BOOL privateDefault;
@property (readonly, assign, nonatomic) BOOL tagsActive;
@property (readonly, strong, nonatomic) NSString *tagsDefault;
// parsed
@property (readonly, strong, nonatomic) NSString *title;

-(void)load;
-(void)save;
-(void)updateEndpoint:(NSString *)endpoint secure:(BOOL)secure user:(NSString *)user pass:(NSString *)pass privateDefault:(BOOL)privateDefault
   tagsActive:(BOOL)tagsA tagsDefault:(NSString *)tagsD completion:( void (^)(ShaarliM * me, NSError * error) )completion;
-(NSURLSession *)postSession;
-(void)postUrl:(NSURL *)url title:(NSString *)title description:(NSString *)desc session:(NSURLSession *)session delegate:(id <ShaarliPostDelegate>)delg;

-(void)postTest;

@end
