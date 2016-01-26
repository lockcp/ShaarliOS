//
// ShaarliCmdUpdateEndpoint.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 20.01.16.
// Copyright (c) 2016 Marcus Rohrmoser. All rights reserved.
//

#import "ShaarliCmdUpdateEndpoint.h"

#define CMD_DO_LOGOUT @"?do=logout"
#define CMD_DO_LOGIN @"?do=login"
#define CMD_DO_CHANGEPASSWD @"?do=changepasswd"

typedef enum : NSUInteger {
    Start,
    GetLogin,
    DoLogout,
    // HttpAuth,
    PostLogin,
    Error,
    Success,
    Done
}
State_t;

@interface ShaarliCmdUpdateEndpoint() {
    State_t state;
}
@property (nonatomic, copy) void (^blockCompletion)(ShaarliCmdUpdateEndpoint * me, NSError * error);
@property (readwrite, nonatomic, strong) NSError *error;

@property (readonly, nonatomic, assign) BOOL authMissing;

@property (nonatomic, strong) NSString *scheme;
@property (nonatomic, strong) NSURLCredential *credential;
@property (nonatomic, strong) NSMutableDictionary *formDict;

@property (nonatomic, strong) NSString *endpoint;
@property (nonatomic, assign) BOOL privateDefault;
@property (nonatomic, assign) BOOL tagsActive;
@property (nonatomic, strong) NSString *tagsDefault;
@end

@implementation ShaarliCmdUpdateEndpoint


-(instancetype)initWithEndpoint:(NSString *)endpoint user:(NSString *)user pass:(NSString *)pass privateDefault:(BOOL)privateDefault
   tagsActive:(BOOL)tagsA tagsDefault:(NSString *)tagsD completion:( void (^)(ShaarliCmdUpdateEndpoint * me, NSError * error) )completion
{
    if( self = [super init] ) {
        self.blockCompletion = completion;
        self.form = @"loginform";

        self.endpoint = endpoint;
        self.privateDefault = privateDefault;
        self.tagsActive = tagsA;
        self.tagsDefault = tagsD;

        if( [self.endpoint hasPrefix:HTTP_HTTP] )
            self.endpoint = [self.endpoint substringFromIndex:[HTTP_HTTP length] + 3];
        if( [self.endpoint hasPrefix:HTTP_HTTPS] )
            self.endpoint = [self.endpoint substringFromIndex:[HTTP_HTTPS length] + 3];

        self.scheme = HTTP_HTTPS;
        // check for credential in store
        // MRLogD (@"credentials in storage: %@", session.configuration.URLCredentialStorage.allCredentials, nil);
        self.credential = [NSURLCredential credentialWithUser:user password:pass persistence:NSURLCredentialPersistenceSynchronizable];
        NSParameterAssert(self.credential.user && [self.credential.user isEqualToString:user]);
        NSParameterAssert(self.credential.password && [self.credential.password isEqualToString:pass]);

        state = Start;
    }
    return self;
}


-(BOOL)authMissing
{
    return NO;
}


-(NSURL *)endpointURL
{
    NSString *u = [NSString stringWithFormat:@"%@://%@", self.scheme, self.endpoint, nil];
    return [[NSURL URLWithString:u] standardizedURL];
}


#pragma mark - FSM


-(BOOL)exitIfError:(NSError *)error autoResume:(BOOL)autoResume
{
    if( nil == error )
        return NO;
    self.error = error;
    state = Error;
    [self resume];
    return YES;
}


-(void)resume
{
    [self processState:YES];
}


-(void)processState:(BOOL)autoResume
{
    MRLogD(@"%d", state, nil);
    NSParameterAssert( (Error != state && nil == self.error) || (Error == state && nil != self.error) );
    __weak typeof(self) weakSelf = self;

    switch( state ) {
    case Start:
        state = GetLogin;
        [self resume];
        return;
    case GetLogin:
    {
        NSURLSession *session = [NSURLSession sharedSession];
        NSParameterAssert(session.configuration);

        NSURL *ur = self.endpointURL;
        MRLogD(@"%@ %@", ur, self.credential.user, nil);

        // http://www.objc.io/issues/5-ios7/from-nsurlconnection-to-nsurlsession/
        // http://www.raywenderlich.com/51127/nsurlsession-tutorial

        // 1. GET the ?do=login action to get the token (and returnurl) as part of the form

        // http://www.raywenderlich.com/51127/nsurlsession-tutorial
        NSURL *u = [[NSURL URLWithString:CMD_DO_LOGIN relativeToURL:ur] standardizedURL];

        [[session dataTaskWithURL:u completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
              // MRLogD (@"complete %@", response.URL, nil);
              if( error ) {
                  if( [HTTP_HTTPS isEqualToString:self.scheme] ) {
                      self.scheme = HTTP_HTTP;
                      state = GetLogin;
                      [weakSelf resume];
                      return;
                  }
                  [weakSelf exitIfError:error autoResume:autoResume];
                  return;
              }
              if( ![weakSelf parseAnyResponse:response data:data error:&error] ) {
                  NSParameterAssert (error);
                  [weakSelf exitIfError:error autoResume:autoResume];
                  return;
              }
              if( self.hasLogOutLink ) {
                  state = DoLogout;
                  [weakSelf resume];
                  return;
              }
              weakSelf.formDict = [weakSelf fetchForm:&error];
              [weakSelf exitIfError:error autoResume:autoResume];
              for( NSString * field in @[F_K_LOGIN, F_K_PASSWORD, F_K_TOKEN] ) {
                  if( !weakSelf.formDict[field] ) {
                      MRLogW (@"missing login form field: '%@'", field, nil);
                      MRLogW (@"response data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], nil);
                      [weakSelf exitIfError:[NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_NO_TOKEN userInfo:@ { NSURLErrorKey:u, NSLocalizedDescriptionKey:NSLocalizedString (@"No token found.", @"ShaarliCmdUpdateEndpoint.m") }
                       ] autoResume:autoResume];
                      return;
                  }
              }
              state = PostLogin;
              [weakSelf resume];
          }
         ] resume];
        return;
    }
    case DoLogout: {
        NSURLSession *session = [NSURLSession sharedSession];
        NSParameterAssert (session.configuration);
        NSURL *ur = self.endpointURL;
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:CMD_DO_LOGOUT relativeToURL:ur] standardizedURL]];
        [[session dataTaskWithRequest:req completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
              state = GetLogin;
              [weakSelf resume];
              return;
          }
         ] resume];
    }
    case PostLogin: {
        NSURLSession *session = [NSURLSession sharedSession];
        NSParameterAssert (session.configuration);

        NSURL *ur = self.endpointURL;
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:CMD_DO_LOGIN relativeToURL:ur] standardizedURL]];
        req.HTTPMethod = HTTP_POST;
        self.formDict[F_K_LOGIN] = self.credential.user;
        self.formDict[F_K_PASSWORD] = self.credential.password;
        self.formDict[F_K_RETURNURL] = [[NSURL URLWithString:CMD_DO_CHANGEPASSWD relativeToURL:ur] absoluteString];
        req.HTTPBody = [self.formDict postData];

        [[session dataTaskWithRequest:req completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
              if( [weakSelf exitIfError:error autoResume:autoResume] )
                  return;
              // MRLogD (@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], nil);
              [weakSelf receivedPost1Response:response data:data error:&error];
              if( [weakSelf exitIfError:error autoResume:autoResume] )
                  return;
              if( weakSelf.hasLogOutLink ) {
                  state = Success;
                  [weakSelf resume];
                  return;
              }
              [weakSelf exitIfError:[NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_NO_LINK_ADDED userInfo:@ { NSURLErrorKey:req.URL, NSLocalizedDescriptionKey:NSLocalizedString (@"Couldn't find link in result.", @"ShaarliCmdUpdateEndpoint.m") }
               ] autoResume:autoResume];
              return;
          }
         ] resume];
        return;
    }
    case Error:
    case Success:
        self.blockCompletion (self, self.error);
        state = Done;
        return;
    default:
        NSParameterAssert (NO);
    }
}


@end
