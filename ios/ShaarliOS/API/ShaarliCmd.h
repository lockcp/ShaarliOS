//
// ShaarliCmd.h
// ShaarliOS
//
// Created by Marcus Rohrmoser on 12.10.15.
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
