//
// ShaarliM.m
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

#import "ShaarliM.h"
#import "ShaarliCmdLogin.h"
#import "ShaarliCmdPost.h"

#define USE_KEYCHAIN 1

#pragma mark -


@implementation NSString(ShaarliTags)

-(NSString *)stringByStrippingTags:(NSMutableArray *)tags
{
    NSError *err = nil;
    NSRegularExpression *rex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*#(\\S+)\\s*" options:NSRegularExpressionAnchorsMatchLines error:&err];
    NSParameterAssert(nil == err);
    __block NSRange all = NSMakeRange(0, self.length);
    for(;; ) {
        __block NSInteger count = 0;
        [rex enumerateMatchesInString:self options:NSMatchingReportProgress range:all usingBlock:^(NSTextCheckingResult * res, NSMatchingFlags flags, BOOL * stop) {
             if( 0 == res.numberOfRanges )
                 return;
             count++;
             NSParameterAssert (2 == res.numberOfRanges);
             const NSRange r0 = [res rangeAtIndex:0];
             const NSRange r1 = [res rangeAtIndex:1];
             NSParameterAssert (all.length >= r0.length);
             NSParameterAssert (all.location + r0.length <= self.length);
             all.location += r0.length;
             all.length -= r0.length;

             all.location = r0.location + r0.length;

             [tags addObject:[self substringWithRange:r1]];
         }
        ];
        if( count == 0 )
            break;
    }
    return [self substringWithRange:all];
}

@end


#import "PDKeychainBindings.h"
#import "NSUserDefaults+Share.h"

#pragma mark -


@interface ShaarliM()
@property (strong, nonatomic) NSURL *endpointUrl;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *passWord;
@property (strong, nonatomic) NSString *title;
@property (assign, nonatomic) BOOL privateDefault;
@property (assign, nonatomic) BOOL tagsActive;
@property (strong, nonatomic) NSString *tagsDefault;
@end

@implementation ShaarliM

-(instancetype)init
{
    MRLogD(@"", nil);
    return [super init];
}


+(NSSet *)keyPathsForValuesAffectingEndpointSecure
{
    return [NSSet setWithObject:@"endpointUrl.scheme"];
}


-(BOOL)endpointSecure
{
    return ![@"http" isEqualToString:self.endpointUrl.scheme];
}


+(NSSet *)keyPathsForValuesAffectingEndpointStr
{
    return [NSSet setWithObject:@"endpointUrl.resourceSpecifier"];
}


-(NSString *)endpointStr
{
    return [self.endpointUrl.resourceSpecifier substringFromIndex:2];
}


+(NSSet *)keyPathsForValuesAffectingIsSetUp
{
    return [NSSet setWithObject:@"endpointUrl"];
}


-(BOOL)isSetUp
{
    return nil != self.endpointUrl;
}


-(void)load
{
    NSUserDefaults *d = [NSUserDefaults shaarliDefaults];
    [d synchronize];
    NSParameterAssert(d);
    self.title = [d valueForKey:@"title"];
    self.privateDefault = [d boolForKey:@"privateDefault"];
    self.tagsActive = [d objectForKey:@"tagsActive"] ? [d boolForKey:@"tagsActive"] : YES;
    self.tagsDefault = [d objectForKey:@"tagsDefault"] ? [d stringForKey:@"tagsDefault"] : @"#ShaarliOS";
#if USE_KEYCHAIN
    self.userName = [[PDKeychainBindings sharedKeychainBindings] stringForKey:@"userName"];
    self.passWord = [[PDKeychainBindings sharedKeychainBindings] stringForKey:@"passWord"];
    self.endpointUrl = [NSURL URLWithString:[[PDKeychainBindings sharedKeychainBindings] stringForKey:@"endpointUrl"]];
#else
    self.userName = [d valueForKey:@"userName"];
    self.passWord = [d valueForKey:@"passWord"];
    self.endpointUrl = [d URLForKey:@"endpointUrl"];
#endif
    if( !( (nil == self.title) == (nil == self.endpointUrl) ) )
        // don't assert because HTML markup might bring title in another tag:
        MRLogW(@"strange configuration. title='%@' endpoint='%@'", self.title, self.endpointUrl, nil);
    MRLogD(@"%@", self.title, nil);
    MRLogD(@"%@", self.userName, nil);
}


-(void)save
{
    MRLogD(@"", nil);
    NSAssert( (nil == self.title) == (nil == self.endpointUrl), @"strange config.", nil );
    NSUserDefaults *d = [NSUserDefaults shaarliDefaults];
    NSParameterAssert(d);
    [d setValue:self.title forKey:@"title"];
    [d setBool:self.privateDefault forKey:@"privateDefault"];
    [d setBool:self.tagsActive forKey:@"tagsActive"];
    [d setObject:self.tagsDefault forKey:@"tagsDefault"];
#if USE_KEYCHAIN
    [[PDKeychainBindings sharedKeychainBindings] setString:self.userName forKey:@"userName"];
    [[PDKeychainBindings sharedKeychainBindings] setString:self.passWord forKey:@"passWord"];
    [[PDKeychainBindings sharedKeychainBindings] setString:self.endpointUrl.absoluteString forKey:@"endpointUrl"];
#else
    [d setValue:self.userName forKey:@"userName"];
    [d setValue:self.passWord forKey:@"passWord"];
    [d setURL:self.endpointUrl forKey:@"endpointUrl"];
#endif
    [d synchronize];
}


-(void)updateEndpoint:(NSString *)endpoint secure:(BOOL)secure user:(NSString *)user pass:(NSString *)pass privateDefault:(BOOL)privateDefault
   tagsActive:(BOOL)tagsA tagsDefault:(NSString *)tagsD completion:( void (^)(ShaarliM * me, NSError * error) )completion
{
    const BOOL force = YES;

    NSURLSession *session = [NSURLSession sharedSession];
    NSParameterAssert(session.configuration);

    NSURL *ur = [[NSURL URLWithString:[NSString stringWithFormat:@"http%s://%@", (secure ? "s":""), endpoint, nil]] standardizedURL];
    MRLogD(@"%@ %@", ur, user, nil);

    NSURLProtectionSpace *ps = [ur protectionSpace];
    NSURLCredential *cre0 = [session.configuration.URLCredentialStorage defaultCredentialForProtectionSpace:ps];

    // http://www.objc.io/issues/5-ios7/from-nsurlconnection-to-nsurlsession/
    // http://www.raywenderlich.com/51127/nsurlsession-tutorial

    // 1. GET the ?do=login action to get the token (and returnurl) as part of the form

    // http://www.raywenderlich.com/51127/nsurlsession-tutorial
    NSURL *u = [NSURL URLWithString:@"?do=login" relativeToURL:ur];
    [[session dataTaskWithURL:u completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
          // MRLogD (@"complete %@", response.URL, nil);
          if( error ) {
              completion (self, error);
              return;
          }
          ShaarliCmdLogin *resp = [[ShaarliCmdLogin alloc] initWithResponse:response data:data error:&error];
          if( resp.hasLogOutLink && !force ) {
              // check if there's a logout link - we're already logged in then.
              NSParameterAssert (cre0);
              NSParameterAssert (!error);
              self.title = [resp fetchTitle:nil];
              [self save];
              completion (self, nil);
              return;
          }

          if( error ) {
              completion (self, error);
              return;
          }

          NSMutableDictionary *form = [resp fetchForm:&error];
          if( error ) {
              completion (self, error);
              return;
          }
          NSParameterAssert (!error);

          for( NSString * field in @[@"login", @"password", @"token"] ) {
              if( !form[field] )
                  MRLogW (@"missing login form field: '%@'", field, nil);
          }

          // check for credential in store
          // MRLogD (@"credentials in storage: %@", session.configuration.URLCredentialStorage.allCredentials, nil);
          NSURLCredential *cre1 = [NSURLCredential credentialWithUser:user password:pass persistence:NSURLCredentialPersistenceSynchronizable];
          NSParameterAssert (cre1.user && [cre1.user isEqualToString:user]);
          NSParameterAssert (cre1.password && [cre1.password isEqualToString:pass]);

          NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:u];
          req.HTTPMethod = @"POST";
          form[@"login"] = cre1.user;
          form[@"password"] = cre1.password;
          form[@"returnurl"] = @"/?do=changepasswd";
          req.HTTPBody = [form postData];
          // MRLogD (@"%@", post, nil);
          [[session dataTaskWithRequest:req completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                if( !error ) {
                    // MRLogD (@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], nil);
                    [resp receivedPost1Response:response data:data error:&error];
                    if( !error && resp.hasLogOutLink ) {
                        self.endpointUrl = ur;
                        self.title = [resp fetchTitle:nil];
                        self.userName = cre1.user;
                        self.passWord = cre1.password;
                        self.privateDefault = privateDefault;
                        self.tagsActive = tagsA;
                        self.tagsDefault = tagsD;
                        [session.configuration.URLCredentialStorage setCredential:cre1 forProtectionSpace:ps];
#ifndef NS_BLOCK_ASSERTIONS
                        NSParameterAssert ([user isEqual:self.userName]);
                        NSParameterAssert ([pass isEqual:self.passWord]);
                        NSURLCredential *cre2 = [session.configuration.URLCredentialStorage credentialsForProtectionSpace:ps][user];
                        NSParameterAssert ([cre1.user isEqual:cre2.user]);
                        NSParameterAssert ([cre1.password isEqual:cre2.password]);
#endif
                        [self save];
                    }
                }
                completion (self, error);
            }
           ] resume];
      }
     ] resume];
}


-(NSURLSession *)postSession
{
    NSParameterAssert(self.endpointUrl);
#if 0
    NSString *confName = BUNDLE_ID @".backgroundpost";
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:confName];
#else
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
#endif
    conf.sharedContainerIdentifier = @"group." BUNDLE_ID; // http://stackoverflow.com/a/26319143
    conf.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain;
    conf.networkServiceType = NSURLNetworkServiceTypeBackground;
    conf.allowsCellularAccess = YES;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:conf delegate:self delegateQueue:nil];
    session.sessionDescription = @"Shaarli Post";

    NSURLProtectionSpace *ps = [self.endpointUrl protectionSpace];
    for( NSURLCredential *c in[[session.configuration.URLCredentialStorage credentialsForProtectionSpace:ps] allValues] ) {
        [session.configuration.URLCredentialStorage removeCredential:c forProtectionSpace:ps options:@ { NSURLCredentialStorageRemoveSynchronizableCredentials:@YES }
        ];
    }
    {
        NSURLCredential *cre = [NSURLCredential credentialWithUser:self.userName password:self.passWord persistence:NSURLCredentialPersistenceSynchronizable];
        [session.configuration.URLCredentialStorage setCredential:cre forProtectionSpace:ps];
    }

    NSParameterAssert(session.configuration.HTTPCookieStorage);
    NSParameterAssert(session.configuration.HTTPCookieStorage == [NSHTTPCookieStorage sharedHTTPCookieStorage]);
    NSParameterAssert(NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain == session.configuration.HTTPCookieAcceptPolicy);
    NSParameterAssert(session.configuration.HTTPShouldSetCookies);
    NSParameterAssert(self == session.delegate);
    for( NSHTTPCookie *cook in session.configuration.HTTPCookieStorage.cookies ) {
        MRLogD(@"deleteCookie %@", cook, nil);
        [session.configuration.HTTPCookieStorage deleteCookie:cook];
    }

    return session;
}


@end
