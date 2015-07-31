//
// ShaarliM.h
// ShaarliCompanion
//
// Created by Marcus Rohrmoser on 17.07.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import <Foundation/Foundation.h>

#define M_FORM @"form"
#define F_TOKEN @"token"
#define M_HAS_LOGOUT @"has_logout"

#define POST_SOURCE @"http://app.mro.name/ShaarliOS"
#define POST_STEP_1 @"post#1"

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


@interface ShaarliM : NSObject <NSURLSessionDelegate>
@property (readonly, strong, nonatomic) NSURL *endpointUrl;
@property (readonly, strong, nonatomic) NSString *endpointStr;
@property (readonly, assign, nonatomic) BOOL endpointSecure;
@property (readonly, strong, nonatomic) NSString *userName;
@property (readonly, strong, nonatomic) NSString *passWord;

@property (readonly, strong, nonatomic) NSString *title;
@property (readonly, assign, nonatomic) BOOL isLoggedIn;


-(void)load;
-(void)save;
-(void)updateEndpoint:(NSString *)endpoint secure:(BOOL)secure user:(NSString *)user pass:(NSString *)pass completion:( void (^)(ShaarliM * me, NSError * error) )completion;
-(NSDictionary *)parseHtmlData:(NSData *)data error:(NSError **)error;

-(void)postURL:(NSURL *)url title:(NSString *)title tags:(id <NSFastEnumeration>)tags description:(NSString *)desc private:
   (BOOL)privat session:(NSURLSession *)session completion:( void (^)(ShaarliM * me, NSError * error) )completion;

-(void)fetchTagCloud:( void (^)(ShaarliM * me, NSError * error) )completion;


-(void)login:( void (^)(ShaarliM * me, NSError * error) )completionHandler;
-(BOOL)logout:(NSError **)err;
-(BOOL)refresh:(NSError **)err;


-(void)postTest;

@end
