//
// ShaarliCmdUpdateEndpoint.h
// ShaarliOS
//
// Created by Marcus Rohrmoser on 20.01.16.
// Copyright (c) 2016 Marcus Rohrmoser. All rights reserved.
//

#import "ShaarliCmd.h"

@interface ShaarliCmdUpdateEndpoint : ShaarliCmd

@property (readonly, nonatomic, strong) NSURLCredential *credential;
@property (readonly, nonatomic, assign) BOOL privateDefault;
@property (readonly, nonatomic, assign) BOOL tagsActive;
@property (readonly, nonatomic, strong) NSString *tagsDefault;

-(NSURL *)endpointURL;

-(instancetype)initWithEndpoint:(NSString *)endpoint user:(NSString *)user pass:(NSString *)pass privateDefault:(BOOL)privateDefault
   tagsActive:(BOOL)tagsA tagsDefault:(NSString *)tagsD completion:( void (^)(ShaarliCmdUpdateEndpoint * me, NSError * error) )completion;
-(void)resume;
@end
