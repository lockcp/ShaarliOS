//
// ShaarliPostCmd.h
// ShaarliOS
//
// Created by Marcus Rohrmoser on 12.10.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "ShaarliCmd.h"

@protocol ShaarliPostDelegate <NSObject>
-(void)didPostLoginForm:(NSMutableDictionary *)form toURL:(NSURL *)url error:(NSError *)error;
-(void)didFinishPostFormToURL:(NSURL *)dst error:(NSError *)error;
@end

@interface ShaarliCmdPost : ShaarliCmd

@property (nonatomic, readwrite, strong) NSURLSession *session;
@property (nonatomic, readwrite, strong) NSURL *endpointUrl;
@property (nonatomic, readwrite, assign) id <ShaarliPostDelegate> delegate;

-(void)startPostForURL:(NSURL *)url title:(NSString *)title desc:(NSString *)desc;
-(void)finishPostForm:(NSMutableDictionary *)form toURL:(NSURL *)url;

@end
