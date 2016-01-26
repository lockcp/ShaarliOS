//
// ShaarliCmdPost.m
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

#import "ShaarliCmdPost.h"

@implementation NSData(NSString)
-(NSString *)stringfromNSData
{
    return [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}


@end


#define POST_SOURCE @"http://app.mro.name/ShaarliOS"

@implementation ShaarliCmdPost


#pragma mark Internal Helpers


-(NSMutableDictionary *)parseLoginForm:(NSURL *)location error:(NSError **)error
{
    NSParameterAssert(error);
    NSData *d = [NSData dataWithContentsOfURL:location options:0 error:error];
    if( *error )
        return nil;
    if( ![self parseAnyResponse:nil data:d error:error] )
        return nil;
    return [self fetchForm:@"loginform" error:error];
}


-(void)postLoginForm:(NSMutableDictionary *)form toURL:(NSURL *)url
{
    // MRLogD(@"-", nil);
    NSParameterAssert(self.session);
    NSParameterAssert(self.endpointURL);
    NSParameterAssert(self.delegate);

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = HTTP_POST;
    req.HTTPBody = [form postData];
    NSURLSessionTask *dt = [self.session downloadTaskWithRequest:req completionHandler:^(NSURL * location, NSURLResponse * response, NSError * error) {
                                NSMutableDictionary *form = error ? nil:[self fetchPostFormForPostURLParse:location error:&error];
                                dispatch_async (dispatch_get_main_queue (), ^{ [self.delegate didPostLoginForm:form toURL:response.URL error:error];
                                                }
                                                );
                            }
                           ];
    dt.taskDescription = @"post URL, step 1";
    MRLogD (@"%@: %@ %@ HTTPBody: %@", dt.taskDescription, dt.originalRequest.HTTPMethod, dt.originalRequest.URL, [dt.originalRequest.HTTPBody stringfromNSData], nil);
    [dt resume];
}


-(NSMutableDictionary *)fetchPostFormForPostURLParse:(NSURL *)location error:(NSError **)error
{
    NSParameterAssert(error);
    NSData *d = [NSData dataWithContentsOfURL:location options:0 error:error];
    if( *error )
        return nil;
    if( ![self parseAnyResponse:nil data:d error:error] )
        return nil;
    return [self fetchForm:@"linkform" error:error];
}


-(BOOL)parsePostResult:(NSURL *)location url:(NSString *)lf_url error:(NSError **)error
{
    NSParameterAssert(error);
    NSData *d = [NSData dataWithContentsOfURL:location options:0 error:error];
    if( *error )
        return NO;
    if( ![self parseAnyResponse:nil data:d error:error] )
        return NO;
    while( [lf_url hasPrefix:@"?"] || [lf_url hasPrefix:@"#"] )
        lf_url = [lf_url substringFromIndex:1];
    // the latter is a bit coarse, but the link was subject to change multiple times https://github.com/shaarli/Shaarli/issues/356
    NSString *xpath = [NSString stringWithFormat:@"boolean(0 < count(/html/body//a[contains(@href, '%@')]))", lf_url];
    return [self booleanForXPath:xpath error:error];
}


#pragma mark Public API


-(void)startPostForURL:(NSURL *)url title:(NSString *)title desc:(NSString *)desc
{
    // MRLogD(@"-", nil);
    NSParameterAssert(self.session);
    NSParameterAssert(self.endpointURL);
    NSParameterAssert(self.delegate);

    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:3];
    d[K_F_SOURCE] = POST_SOURCE;
    d[K_F_POST] = url ? url.absoluteString : @"";
    if( title )
        d[K_F_TITLE] = title;
    if( desc )
        d[K_F_DESCRIPTION] = desc;

    NSString *par = @"?";
    par = [par stringByAppendingString:[d stringByAddingPercentEscapesForHttpFormUrl]];
    NSURL *cmd = [NSURL URLWithString:par relativeToURL:self.endpointURL];
    NSURLSessionTask *dt = [self.session downloadTaskWithURL:cmd completionHandler:^(NSURL * location, NSURLResponse * response, NSError * error) {
                                if( !error ) {
                                    NSMutableDictionary *form = [self parseLoginForm:location error:&error];

                                    NSURLProtectionSpace *ps = [self.endpointURL protectionSpace];
                                    NSURLCredential *cre0 = [self.session.configuration.URLCredentialStorage defaultCredentialForProtectionSpace:ps];
                                    NSParameterAssert (cre0);
                                    NSParameterAssert (cre0.user);
                                    NSParameterAssert (cre0.password);

                                    form[F_K_LOGIN] = cre0.user;
                                    form[F_K_PASSWORD] = cre0.password;
                                    form[F_K_RETURNURL] = [cmd absoluteString];
                                    [self postLoginForm:form toURL:response.URL];
                                } else
                                    dispatch_async (dispatch_get_main_queue (), ^{ [self.delegate didPostLoginForm:nil toURL:response.URL error:error];
                                                    }
                                                    );
                            }
                           ];
    dt.taskDescription = @"post URL, step 0";
    MRLogD (@"%@: %@ %@ HTTPBody: %@", dt.taskDescription, dt.originalRequest.HTTPMethod, dt.originalRequest.URL, [dt.originalRequest.HTTPBody stringfromNSData], nil);
    [dt resume];
}


-(void)finishPostForm:(NSMutableDictionary *)form toURL:(NSURL *)url
{
    // MRLogD(@"-", nil);
    NSParameterAssert(self.session);
    NSParameterAssert(self.endpointURL);
    NSParameterAssert(self.delegate);

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = HTTP_POST;
    form[K_F_LF_SOURCE] = POST_SOURCE;
    form[@"save_edit"] = @"Save";
    req.HTTPBody = [form postData];

    NSURLSessionTask *dt = [self.session downloadTaskWithRequest:req completionHandler:^(NSURL * location, NSURLResponse * response, NSError * error) {
                                if( !error ) {
                                    NSURL *newUrl = [NSURL URLWithString:[form[K_F_LF_URL] stringByReplacingOccurrencesOfString:@"?" withString:@"/?#"] relativeToURL:self.endpointURL];
                                    if( ![response.URL.absoluteString isEqualToString:[newUrl absoluteString]] ) {
                                        // look for the lf_url in the results list (see https://github.com/shaarli/Shaarli/issues/356 ).
                                        const BOOL ok = [self parsePostResult:location url:form[K_F_LF_URL] error:&error];
                                        if( !ok ) {
                                            error = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_NO_LINK_ADDED userInfo:@ { NSURLErrorKey:req.URL, NSLocalizedDescriptionKey:NSLocalizedString (@"Couldn't find added link on your Shaarli.", @"ShaarliCmdPost") }
                                                    ];
                                        }
                                    }
                                }
                                dispatch_async (dispatch_get_main_queue (), ^{ [self.delegate didFinishPostFormToURL:response.URL error:error];
                                                }
                                                );
                            }
                           ];
    dt.taskDescription = @"post URL, step 2";
    MRLogD (@"%@: %@ %@ HTTPBody: %@", dt.taskDescription, dt.originalRequest.HTTPMethod, dt.originalRequest.URL, [dt.originalRequest.HTTPBody stringfromNSData], nil);
    [dt resume];
}


@end
