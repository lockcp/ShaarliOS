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
    GetLoginFormAndToken,
    DoLogout,
    // HttpAuth,
    PostLoginForm,
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

@property (nonatomic, strong) NSString *title;

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

        if( [self.endpoint hasPrefix:HTTP_HTTPS @"://"] )
            self.endpoint = [self.endpoint substringFromIndex:[HTTP_HTTPS  @"://" length]];
        if( [self.endpoint hasPrefix:HTTP_HTTP @"://"] )
            self.endpoint = [self.endpoint substringFromIndex:[HTTP_HTTP  @"://" length]];

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
    NSString *u = [NSString stringWithFormat:@"%@" @"://" @"%@", self.scheme, self.endpoint, nil];
    return [[NSURL URLWithString:u] standardizedURL];
}


#pragma mark - FSM


-(BOOL)exitIfError:(NSError *)error autoResume:(NSInteger)autoNextSteps
{
    if( nil == error )
        return NO;
    self.error = error;
    state = Error;
    [self processState:autoNextSteps - 1];
    return YES;
}


-(void)resume
{
    [self processState:1000];
}


-(void)processState:(NSInteger)autoNextSteps
{
    MRLogD(@"%d %d", state, autoNextSteps, nil);
    if( 0 > autoNextSteps )
        return;
    NSParameterAssert( (Error != state && nil == self.error) || (Error == state && nil != self.error) );
    __weak typeof(self) weakSelf = self;

    NSURLSession *session = [NSURLSession sharedSession];
    NSParameterAssert(session.configuration);
    NSURL *ur = self.endpointURL;

    switch( state ) {
    case Start:
        state = GetLoginFormAndToken;
        [self processState:autoNextSteps - 1];
        return;
    case GetLoginFormAndToken:
    {
        // http://www.objc.io/issues/5-ios7/from-nsurlconnection-to-nsurlsession/
        // http://www.raywenderlich.com/51127/nsurlsession-tutorial
        NSURL *u = [ur urlForCommand:CMD_DO_LOGIN];
        MRLogD(@"%@ %@ %@", HTTP_GET, u, self.credential.user, nil);
        [[session dataTaskWithURL:u completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
              // MRLogD (@"complete %@", response.URL, nil);
              if( error ) {
                  // retry with (unsecure) http
                  if( [HTTP_HTTPS isEqualToString:self.scheme] ) {
                      self.scheme = HTTP_HTTP;
                      state = GetLoginFormAndToken;
                      [weakSelf processState:autoNextSteps - 1];
                      return;
                  }
                  [weakSelf exitIfError:error autoResume:autoNextSteps - 1];
                  return;
              }
              if( ![weakSelf parseAnyResponse:response data:data error:&error] ) {
                  NSParameterAssert (error);
                  [weakSelf exitIfError:error autoResume:autoNextSteps - 1];
                  return;
              }
              if( self.hasLogOutLink ) {
                  state = DoLogout;
                  [weakSelf processState:autoNextSteps - 1];
                  return;
              }
              weakSelf.title = [weakSelf fetchTitle:&error];
              if( [weakSelf exitIfError:error autoResume:autoNextSteps - 1] )
                  return;
              weakSelf.formDict = [weakSelf fetchForm:&error];
              if( [weakSelf exitIfError:error autoResume:autoNextSteps - 1] )
                  return;
              for( NSString * field in @[F_K_LOGIN, F_K_PASSWORD, F_K_TOKEN] ) {
                  if( !weakSelf.formDict[field] ) {
                      MRLogW (@"missing login form field: '%@'", field, nil);
                      // MRLogW (@"response data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], nil);
                      [weakSelf exitIfError:[NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_NO_TOKEN userInfo:@ { NSURLErrorKey:u, NSLocalizedDescriptionKey:NSLocalizedString (@"Required login form field slot missing.", @"ShaarliCmdUpdateEndpoint") }
                       ] autoResume:autoNextSteps - 1];
                      return;
                  }
              }
              state = PostLoginForm;
              [weakSelf processState:autoNextSteps - 1];
          }
         ] resume];
    }
        return;
    case DoLogout: {
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[ur urlForCommand:CMD_DO_LOGOUT]];
        MRLogD (@"%@ %@", req.HTTPMethod, req.URL, nil);
        [[session dataTaskWithRequest:req completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
              if( [weakSelf exitIfError:error autoResume:autoNextSteps - 1] )
                  return;
              state = GetLoginFormAndToken;
              [weakSelf processState:autoNextSteps - 1];
              return;
          }
         ] resume];
    }
        return;
    case PostLoginForm: {
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[ur urlForCommand:CMD_DO_LOGIN]];
        req.HTTPMethod = HTTP_POST;
        self.formDict[F_K_LOGIN] = self.credential.user;
        self.formDict[F_K_PASSWORD] = self.credential.password;
        self.formDict[F_K_RETURNURL] = [[ur urlForCommand:CMD_DO_CHANGEPASSWD] absoluteString];
        req.HTTPBody = [self.formDict postData];
        MRLogD (@"%@ %@", req.HTTPMethod, req.URL, nil);
        [[session dataTaskWithRequest:req completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
              if( [weakSelf exitIfError:error autoResume:autoNextSteps - 1] )
                  return;
              // MRLogD (@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], nil);
              [weakSelf receivedPost1Response:response data:data error:&error];
              if( [weakSelf exitIfError:error autoResume:autoNextSteps - 1] )
                  return;
              if( !weakSelf.title ) {
                  MRLogW (@"This is a bit od, there's no title yet.", nil);
                  weakSelf.title = [weakSelf fetchTitle:&error];
                  if( [weakSelf exitIfError:error autoResume:autoNextSteps - 1] )
                      return;
              }
              if( weakSelf.hasLogOutLink ) {
                  state = Success;
                  [weakSelf processState:autoNextSteps - 1];
                  return;
              }
              [weakSelf exitIfError:[NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_LOGOUT_BUTTON_EXPECTED userInfo:@ { NSURLErrorKey:req.URL, NSLocalizedDescriptionKey:NSLocalizedString (@"Couldn't find logout link, so maybe I'm not logged in properly.", @"ShaarliCmdUpdateEndpoint.m") }
               ] autoResume:autoNextSteps - 1];
              return;
          }
         ] resume];
    }
        return;
    case Error:
        NSParameterAssert (self.error);
    case Success:
        self.blockCompletion (self, self.error);
        state = Done;
        return;
    default:
        NSParameterAssert (NO);
    }
}


@end
