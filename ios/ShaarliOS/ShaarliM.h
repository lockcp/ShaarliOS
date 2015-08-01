//
// ShaarliM.h
// ShaarliCompanion
//
// Created by Marcus Rohrmoser on 17.07.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import <Foundation/Foundation.h>

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
@end

@interface ShaarliM : NSObject <NSURLSessionDelegate>
    // configured
@property (readonly, strong, nonatomic) NSString *userName;
@property (readonly, strong, nonatomic) NSString *passWord;
@property (readonly, strong, nonatomic) NSURL *endpointUrl;
@property (readonly, strong, nonatomic) NSString *endpointStr;
@property (readonly, assign, nonatomic) BOOL isSetUp;
@property (readonly, assign, nonatomic) BOOL endpointSecure;
// parsed
@property (readonly, strong, nonatomic) NSString *title;

-(void)load;
-(void)save;
-(void)updateEndpoint:(NSString *)endpoint secure:(BOOL)secure user:(NSString *)user pass:(NSString *)pass completion:( void (^)(ShaarliM * me, NSError * error) )completion;
-(NSURLSession *)postSession;
-(void)postUrl:(NSURL *)url title:(NSString *)title description:(NSString *)desc tags:(id <NSFastEnumeration>)tags private:
   (BOOL)private session:(NSURLSession *)session delegate:(id <ShaarliPostDelegate>)delg;

-(void)postTest;

@end
