//
// ShaarliM.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 17.07.15.
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

#import "ShaarliM.h"
#import "ShaarliCmdPost.h"
#import "ShaarliCmdUpdateEndpoint.h"

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
@property (strong, nonatomic) NSURL *endpointURL;
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
    return [NSSet setWithObject:@"endpointURL.scheme"];
}


-(BOOL)endpointSecure
{
    return ![HTTP_HTTP isEqualToString:self.endpointURL.scheme];
}


+(NSSet *)keyPathsForValuesAffectingEndpointStr
{
    return [NSSet setWithObject:@"endpointURL.resourceSpecifier"];
}


-(NSString *)endpointStr
{
    return [self.endpointURL.resourceSpecifier substringFromIndex:2];
}


+(NSSet *)keyPathsForValuesAffectingIsSetUp
{
    return [NSSet setWithObject:@"endpointURL"];
}


-(BOOL)isSetUp
{
    return nil != self.endpointURL;
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
    self.passWord = [[PDKeychainBindings sharedKeychainBindings] stringForKey:@"password"];
    self.endpointURL = [NSURL URLWithString:[[PDKeychainBindings sharedKeychainBindings] stringForKey:@"endpointURL"]];
    if( nil == self.endpointURL ) {
        // migrate legacy
        self.endpointURL = [NSURL URLWithString:[[PDKeychainBindings sharedKeychainBindings] stringForKey:@"endpointUrl"]];
    }
#else
    self.userName = [d valueForKey:@"userName"];
    self.passWord = [d valueForKey:@"password"];
    self.endpointURL = [d URLForKey:@"endpointURL"];
#endif
    if( !( (nil == self.title) == (nil == self.endpointURL) ) )
        // don't assert because HTML markup might bring title in another tag:
        MRLogW(@"strange configuration. title='%@' endpoint='%@'", self.title, self.endpointURL, nil);
    MRLogD(@"%@", self.title, nil);
    MRLogD(@"%@", self.userName, nil);
}


-(void)save
{
    MRLogD(@"", nil);
    NSAssert( (nil == self.title) == (nil == self.endpointURL), @"strange config.", nil );
    NSUserDefaults *d = [NSUserDefaults shaarliDefaults];
    NSParameterAssert(d);
    [d setValue:self.title forKey:@"title"];
    [d setBool:self.privateDefault forKey:@"privateDefault"];
    [d setBool:self.tagsActive forKey:@"tagsActive"];
    [d setObject:self.tagsDefault forKey:@"tagsDefault"];
#if USE_KEYCHAIN
    [[PDKeychainBindings sharedKeychainBindings] setString:self.userName forKey:@"userName"];
    [[PDKeychainBindings sharedKeychainBindings] setString:self.passWord forKey:@"password"];
    [[PDKeychainBindings sharedKeychainBindings] setString:self.endpointURL.absoluteString forKey:@"endpointURL"];
#else
    [d setValue:self.userName forKey:@"userName"];
    [d setValue:self.passWord forKey:@"password"];
    [d setURL:self.endpointURL forKey:@"endpointURL"];
#endif
    [d synchronize];
}


-(void)updateEndpoint:(NSString *)endpoint secure:(BOOL)secure user:(NSString *)user pass:(NSString *)pass privateDefault:(BOOL)privateDefault
   tagsActive:(BOOL)tagsA tagsDefault:(NSString *)tagsD completion:( void (^)(ShaarliM * me, NSError * error) )completion
{
    NSParameterAssert(completion);
    __weak typeof(self) weakSelf = self;

    ShaarliCmdUpdateEndpoint *c = [[ShaarliCmdUpdateEndpoint alloc] initWithEndpoint:endpoint user:user pass:pass privateDefault:privateDefault tagsActive:tagsA tagsDefault:tagsD completion:^(ShaarliCmdUpdateEndpoint * me, NSError * error) {
                                       if( !error ) {
                                           // @TODO self.title = me.title;
                                           weakSelf.title = me.title;
                                           weakSelf.endpointURL = me.endpointURL;
                                           weakSelf.userName = me.credential.user;
                                           weakSelf.passWord = me.credential.password;
                                           weakSelf.privateDefault = me.privateDefault;
                                           weakSelf.tagsActive = me.tagsActive;
                                           weakSelf.tagsDefault = me.tagsDefault;
                                           [weakSelf save];
                                       }
                                       completion (weakSelf, error);
                                   }
                                  ];
    [c resume];
}


-(NSURLSession *)postSession
{
    NSParameterAssert(self.endpointURL);
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

    NSURLProtectionSpace *ps = [self.endpointURL protectionSpace];
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
