//
// ShaarliCmdLogin.h
// ShaarliOS
//
// Created by Marcus Rohrmoser on 12.10.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "ShaarliCmd.h"

@interface ShaarliCmdLogin : ShaarliCmd

/** Process response of step 1, the essentially the login form token. */
-(instancetype)initWithResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error;

/** Process response of step 2, the login result. */
-(BOOL)receivedPost1Response:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error;

@end
