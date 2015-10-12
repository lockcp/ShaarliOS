//
// ShaarliCmdLogin.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 12.10.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "ShaarliCmdLogin.h"

@interface ShaarliCmdLogin()
@end

@implementation ShaarliCmdLogin

-(instancetype)initWithResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error
{
    if( self = [super initWithResponse:response data:data error:error] ) {
        self.form = @"loginform";
        if( ![self fetchToken:error] ) {
            if( error )
                *error = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_NO_TOKEN userInfo:@ { NSURLErrorKey:response.URL, NSLocalizedDescriptionKey:NSLocalizedString(@"No token found.", @"ShaarliM") }
                         ];
            return nil;
        }
    }
    return self;
}


-(BOOL)receivedPost1Response:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error
{
    self.form = nil; // there's no more to come
    return [super receivedPost1Response:response data:data error:error];
}


@end
