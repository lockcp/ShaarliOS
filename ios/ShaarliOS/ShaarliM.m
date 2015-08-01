//
// ShaarliM.m
// ShaarliCompanion
//
// Created by Marcus Rohrmoser on 17.07.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "ShaarliM.h"

#define USE_KEYCHAIN 1

@implementation NSString(HttpGetParams)

/**
 * https://web.archive.org/web/20090430095243/http://simonwoodside.com/weblog/2009/4/22/how_to_really_url_encode/
 * https://madebymany.com/blog/url-encoding-an-nsstring-on-ios
 */
-(NSString *)stringByAddingPercentEscapesForHttpFormUrl
{
#if 1
    // http://stackoverflow.com/a/8086845
    return (NSString *)CFBridgingRelease( CFURLCreateStringByAddingPercentEscapes(
                                              NULL,
                                              (__bridge CFStringRef)self,
                                              NULL,
                                              CFSTR("!*'();:@&=+$,/?%#[]\" "),
                                              kCFStringEncodingUTF8) );
#else
    CFStringRef src = (__bridge CFStringRef)self;
    CFStringRef keep = CFSTR("!$&'()*+,-./:;=?@_~");
    CFStringRef dst = CFURLCreateStringByAddingPercentEscapes( NULL, src, NULL, keep, CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding) );
    NSString *ret = (__bridge NSString *)dst;
    CFRelease(dst);
    return ret;
#endif
}


@end



@implementation NSDictionary(HttpGetParams)
-(NSString *)stringByAddingPercentEscapesForHttpFormUrl
{
    NSMutableString *s = [NSMutableString stringWithCapacity:100];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * stop) {
         if( 0 < s.length )
             [s appendString:@"&"];
         [s appendString:[key stringByAddingPercentEscapesForHttpFormUrl]];
         [s appendString:@"="];
         [s appendString:[obj stringByAddingPercentEscapesForHttpFormUrl]];
     }
    ];
    return s;
}
@end


@implementation NSDictionary(HttpPostData)

-(NSData *)postData
{
    return [[self stringByAddingPercentEscapesForHttpFormUrl] dataUsingEncoding:NSUTF8StringEncoding];
}


@end

@implementation NSURL(HttpGetParams)


-(NSDictionary *)dictionaryWithHttpFormUrl
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:5];
    for( NSString *part in[self.query componentsSeparatedByString : @"&"] ) {
        const NSRange r = [part rangeOfString:@"="];
        if( NSNotFound == r.location )
            ret[[part stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] = @ (YES);
        else {
            // http://stackoverflow.com/questions/3423545/objective-c-iphone-percent-encode-a-string#comment8231731_3426140
            // http://stackoverflow.com/questions/2678551/when-to-encode-space-to-plus-or-20
            NSString *key = [[part substringToIndex:r.location] stringByReplacingOccurrencesOfString:@"+" withString:@"%20"];
            NSString *value = [[part substringFromIndex:r.location + r.length] stringByReplacingOccurrencesOfString:@"+" withString:@"%20"];
            ret[[key stringByRemovingPercentEncoding]] = [value stringByRemovingPercentEncoding];
        }
    }
    return ret;
}


-(NSDictionary *)queryDictionary
{
    return [self dictionaryWithHttpFormUrl];
}


@end


@implementation NSURL(ProtectionSpace)

-(NSURLProtectionSpace *)protectionSpace
{
    NSURL *u = self;
    NSNumber *pn = u.port ? u.port : (@ { @"http" : @ (80), @"https" : @ (443) }
                                      [u.scheme]);
    NSParameterAssert(pn);
    return [[NSURLProtectionSpace alloc] initWithHost:u.host port:[pn integerValue] protocol:u.scheme realm:nil authenticationMethod:NSURLAuthenticationMethodHTMLForm];
}


@end

#pragma mark -


#pragma mark libxml2 LoginForm

#define M_FORM @"form"
#define F_TOKEN @"token"
#define M_HAS_LOGOUT @"has_logout"

#define T_A @"a"
#define T_DIV @"div"
#define T_SPAN @"span"

#define M_TITLE @"title"
#define M_TEXT @"text"
#define M_ID_HEADERFORM @"headerform"

#import <libxml2/libxml/HTMLparser.h>

static void ShaarliHtml_StartElement(void *voidContext, const xmlChar *name, const xmlChar **attributes)
{
    assert(voidContext && "ouch");
    NSMutableDictionary *d = (__bridge NSMutableDictionary *)voidContext;

    if( 0 == strcmp("a", (const char *)name) ) {
        for( int i = 0; attributes[i + 1]; i += 2 ) {
            const char *name = (const char *)attributes[i];
            const char *value = (const char *)attributes[i + 1];

            if( 0 == strcmp("href", name) && 0 == strcmp("?do=logout", value) )
                // https://github.com/dimtion/Shaarlier/commit/e55b150770b67561d0e07c8b1d5ab88b4f1ce52b#commitcomment-12407612
                d[M_HAS_LOGOUT] = @ (YES);
        }
        return;
    }
    // shaarli_title
    if( 0 == strcmp("span", (const char *)name) ) {
        for( int i = 0; attributes[i + 1]; i += 2 ) {
            const char *name = (const char *)attributes[i];
            const char *value = (const char *)attributes[i + 1];

            if( 0 == strcmp("id", name) && 0 == strcmp("shaarli_title", value) )
                d[T_SPAN] = M_TITLE;
            [d[M_TEXT] setString:@""];
        }
        return;
    }
    if( 0 == strcmp("div", (const char *)name) ) {
        for( int i = 0; attributes[i + 1]; i += 2 ) {
            const char *name = (const char *)attributes[i];
            const char *value = (const char *)attributes[i + 1];

            if( 0 == strcmp("id", name) && 0 == strcmp("headerform", value) ) {
                d[T_DIV] = M_ID_HEADERFORM;
                [d[M_TEXT] setString:@""];
            }
        }
        return;
    }
    if( 0 == strcmp("input", (const char *)name) ) {
        // MRLogD(@"<%s>", name, nil);
        NSMutableDictionary *form = d[M_FORM];
        if( !form )
            form = d[M_FORM] = [[NSMutableDictionary alloc] initWithCapacity:5];
        // refill name + value attributes into hash
        NSMutableDictionary *at = [NSMutableDictionary dictionaryWithCapacity:2];
        for( int i = 0; attributes[i + 1]; i += 2 ) {
            const char *name = (const char *)attributes[i];
            const char *value = (const char *)attributes[i + 1];
            // MRLogD(@"%s=%s", attributes[i], attributes[i + 1], nil);
            if( 0 == strcmp("name", name) || 0 == strcmp("value", name) ) {
                NSString *k = [[NSString alloc] initWithCString:name encoding:NSUTF8StringEncoding];
                at[k] = [[NSString alloc] initWithCString:value encoding:NSUTF8StringEncoding];
            }
        }
        // ignore empty input fields
        if( at[@"name"] && at[@"value"] )
            form[at[@"name"]] = at[@"value"];
        return;
    }
}


void ShaarliTextRefill(NSMutableDictionary *d, NSString *mark, NSString *tag)
{
    NSMutableString *str = d[M_TEXT];
    d[mark] = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [d removeObjectForKey:tag];
    [str setString:@""];
}


static void ShaarliHtml_EndElement(void *voidContext, const xmlChar *name)
{
    assert(voidContext && "ouch");
    NSMutableDictionary *d = (__bridge NSMutableDictionary *)voidContext;

    if( 0 == strcmp("span", (const char *)name) && [M_TITLE isEqualToString:d[T_SPAN]] )
        ShaarliTextRefill(d, M_TITLE, T_SPAN);
    if( 0 == strcmp("div", (const char *)name) && [M_ID_HEADERFORM isEqualToString:d[T_DIV]] )
        ShaarliTextRefill(d, M_ID_HEADERFORM, T_DIV);
}


static void ShaarliHtml_StartElement2(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes)
{
    MRLogD(@"<2 %s>", localname, nil);
}


// static void FormField_EndElement(void *voidContext, const xmlChar *name)

static void ShaarliHtml_EndElement2(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI)
{
    MRLogD(@"</2 %s>", localname, nil);
}


static void ShaarliHtml_Characters(void *voidContext, const xmlChar *ch, int len)
{
    assert(voidContext && "ouch");
    NSMutableDictionary *d = (__bridge NSMutableDictionary *)voidContext;

    if( [M_TITLE isEqualToString:d[T_SPAN]] || [M_ID_HEADERFORM isEqualToString:d[T_DIV]] ) {
        NSMutableString *str = d[M_TEXT];
        if( !str )
            str = d[M_TEXT] = [NSMutableString stringWithCapacity:200];
        char tmp[len + 1];
        tmp[len] = '\0';
        strncpy(tmp, (const char *)ch, len);
        [str appendFormat:@"%s", tmp];
    }
}


static htmlSAXHandler FormField_Handler = {
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ShaarliHtml_StartElement, ShaarliHtml_EndElement,
    NULL, ShaarliHtml_Characters,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, // cdata,
    NULL, 0, NULL, ShaarliHtml_StartElement2, ShaarliHtml_EndElement2, NULL
};

/** parse form data (token!) from the HTML response: */
NSDictionary *parseShaarliHtml(NSData *data, NSError **error)
{
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:4];
    htmlParserCtxtPtr ctxt = htmlCreatePushParserCtxt(&FormField_Handler, (__bridge void *)d, (const char *)[data bytes], (int)data.length, "", XML_CHAR_ENCODING_NONE);
    htmlParseChunk(ctxt, "", 0, YES);
    htmlFreeParserCtxt(ctxt);
    [d removeObjectForKey:T_A];
    [d removeObjectForKey:T_SPAN];
    [d removeObjectForKey:T_DIV];
    [d removeObjectForKey:M_TEXT];
    // MRLogD(@"%@", d, nil);
    return d;
}


#import "PDKeychainBindings.h"
#import "NSUserDefaults+Share.h"

#pragma mark -


@interface ShaarliM()
@property (strong, nonatomic) NSURL *endpointUrl;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *passWord;
@property (strong, nonatomic) NSString *title;

@property (weak, nonatomic) id <ShaarliPostDelegate> postDelegate;
@end

@implementation ShaarliM

-(instancetype)init
{
    MRLogD(@"", nil);
    return [super init];
}


-(NSDictionary *)parseHtmlData:(NSData *)data error:(NSError **)error
{
    return parseShaarliHtml(data, error);
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
        MRLogW(@"strange configuration", nil);
    // NSAssert( (nil == self.title) == (nil == self.endpointUrl), @"strange config.", nil );
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


-(void)updateEndpoint:(NSString *)endpoint secure:(BOOL)secure user:(NSString *)user pass:(NSString *)pass completion:( void (^)(ShaarliM * me, NSError * error) )completion
{
    const BOOL force = NO;

    NSURLSession *session = [NSURLSession sharedSession];
    NSParameterAssert(session.configuration);

    NSURL *ur = [[NSURL URLWithString:[NSString stringWithFormat:@"http%s://%@", (secure ? "s":""), endpoint, nil]] standardizedURL];
    MRLogD(@"%@ %@", ur, user, nil);

    NSURLProtectionSpace *ps = [ur protectionSpace];
    NSDictionary *cd = [session.configuration.URLCredentialStorage credentialsForProtectionSpace:ps];
    NSURLCredential *cre0 = cd[user];

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
          NSDictionary *r = parseShaarliHtml (data, nil);
          if( [r[M_HAS_LOGOUT] boolValue] && !force ) {
              // check if there's a logout link - we're already logged in then.
              NSParameterAssert (cre0);
              if( !error ) {
                  self.title = r[M_TITLE];
                  [self save];
              }
              completion (self, error);
              return;
          }
          // check for token
          NSString *token = error ? nil:r[M_FORM][F_TOKEN];
          if( !token ) {
              if( !error ) {
                  if( r[M_ID_HEADERFORM] ) {
                      error = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_BANNED userInfo:@ { NSURLErrorKey:u, NSLocalizedDescriptionKey:NSLocalizedString (r[M_ID_HEADERFORM], @"ShaarliM") }
                              ];
                  } else {
                      error = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_NO_TOKEN userInfo:@ { NSURLErrorKey:u, NSLocalizedDescriptionKey:NSLocalizedString (@"No token found.", @"ShaarliM") }
                              ];
                      MRLogW (@"todo: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], nil);
                  }
              }
              completion (self, error);
              return;
          }
          NSParameterAssert (token);
          NSParameterAssert (!error);

          // check for credential in store
          // MRLogD (@"credentials in storage: %@", session.configuration.URLCredentialStorage.allCredentials, nil);
          NSURLCredential *cre1 = cre0 ? cre0:[NSURLCredential credentialWithUser:user password:pass persistence:NSURLCredentialPersistenceSynchronizable];
          NSParameterAssert (cre1.user && [cre1.user isEqualToString:user]);
          NSParameterAssert (cre1.password && [cre1.password isEqualToString:pass]);

          NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:u];
          req.HTTPMethod = @"POST";
          NSDictionary *post = @ { @"login":cre1.user, @"password":cre1.password, F_TOKEN:token };
          req.HTTPBody = [post postData];
          // MRLogD (@"%@", post, nil);
          [[session dataTaskWithRequest:req completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                // MRLogD (@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], nil);
                NSDictionary *res = parseShaarliHtml (data, nil);
                if( !error && ![res[M_HAS_LOGOUT] boolValue] )
                    error = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_LOGOUT_BUTTON_EXPECTED userInfo:@ { NSURLErrorKey:u, NSLocalizedDescriptionKey:NSLocalizedString ([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], @"ShaarliM.m") }
                            ];
                if( !error && !res[M_TITLE] )
                    error = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_TITLE_EXPECTED userInfo:@ { NSURLErrorKey:u, NSLocalizedDescriptionKey:NSLocalizedString (@"Shaarli title not found.", @"ShaarliM") }
                            ];
                if( !error ) {
                    self.endpointUrl = ur;
                    self.title = res[M_TITLE];
                    self.userName = cre1.user;
                    self.passWord = cre1.password;
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
                completion (self, error);
            }
           ] resume];
      }
     ] resume];
}


-(NSURLSession *)postSession
{
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


#pragma mark -

#define POST_SOURCE @"http://app.mro.name/ShaarliOS"
#define POST_STEP_1 @"post#1"
#define POST_STEP_2 @"post#2"
#define POST_STEP_3 @"post#3"
#define POST_STEP_4 @"post#4"


-(void)postTest
{
    MRLogD(@"-", nil);

    NSString *confName = BUNDLE_ID @".backgroundpost";
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:confName];
    // conf = [NSURLSessionConfiguration defaultSessionConfiguration];
    conf.sharedContainerIdentifier = @"group." BUNDLE_ID; // http://stackoverflow.com/a/26319143
    conf.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain;
    conf.networkServiceType = NSURLNetworkServiceTypeBackground;
    conf.allowsCellularAccess = YES;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:conf delegate:self delegateQueue:nil];
    session.sessionDescription = @"Shaarli Post";

    NSParameterAssert(session.configuration.HTTPCookieStorage);
    NSParameterAssert(session.configuration.HTTPCookieStorage == [NSHTTPCookieStorage sharedHTTPCookieStorage]);
    NSParameterAssert(NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain == session.configuration.HTTPCookieAcceptPolicy);
    NSParameterAssert(session.configuration.HTTPShouldSetCookies);
    NSParameterAssert(self == session.delegate);

    for( NSHTTPCookie *cook in session.configuration.HTTPCookieStorage.cookies ) {
        MRLogD(@"deleteCookie %@", cook, nil);
        [session.configuration.HTTPCookieStorage deleteCookie:cook];
    }

    NSString *par = @"?";
    par = [par stringByAppendingString:[@ { @"post":@"http://ww.heise.de/a", @"title":@"Ti tlə", @"description":[[NSDate date] description], @"source":POST_SOURCE }
                                        stringByAddingPercentEscapesForHttpFormUrl]];

    NSURL *cmd = [NSURL URLWithString:par relativeToURL:self.endpointUrl];
    NSURLSessionTask *dt = [session downloadTaskWithURL:cmd];
    dt.taskDescription = POST_STEP_1;
    [dt resume];
}


-(void)postUrl:(NSURL *)url title:(NSString *)title description:(NSString *)desc tags:(id <NSFastEnumeration>)tags private:
   (BOOL)private session:(NSURLSession *)session delegate:(id <ShaarliPostDelegate>)delg
{
    NSString *par = @"?";
    NSParameterAssert(nil == self.postDelegate);
    NSParameterAssert(delg);
    self.postDelegate = delg;
    par = [par stringByAppendingString:[@ { @"post":url.absoluteString, @"title":title, @"description":desc, @"source":POST_SOURCE }
                                        stringByAddingPercentEscapesForHttpFormUrl]];
    NSURL *cmd = [NSURL URLWithString:par relativeToURL:self.endpointUrl];
    NSURLSessionTask *dt = [session downloadTaskWithURL:cmd];
    dt.taskDescription = POST_STEP_1;
    [dt resume];
    // see -(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)task didFinishDownloadingToURL:(NSURL *)location
}


#pragma mark NSURLSessionDelegate


/* The last message a session receives.  A session will only become
 * invalid because of a systemic error or when it has been
 * explicitly invalidated, in which case the error parameter will be nil.
 */
-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    MRLogD(@"%@", session.sessionDescription, nil);
    NSParameterAssert(NO);
}


/* If implemented, when a connection level authentication challenge
 * has occurred, this delegate will be given the opportunity to
 * provide authentication credentials to the underlying
 * connection. Some types of authentication will apply to more than
 * one request on a given connection to a server (SSL Server Trust
 * challenges).  If this delegate message is not implemented, the
 * behavior will be to use the default handling, which may involve user
 * interaction.
 */
-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
   completionHandler:( void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * credential) )completionHandler
{
    MRLogD(@"%@", session.sessionDescription, nil);
    NSParameterAssert(NO);
}


/* If an application has received an
 * -application:handleEventsForBackgroundURLSession:completionHandler:
 * message, the session delegate will receive this message to indicate
 * that all messages previously enqueued for this session have been
 * delivered.  At this time it is safe to invoke the previously stored
 * completion handler, or to begin any internal updates that will
 * result in invoking the completion handler.
 */
-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    MRLogD(@"%@", session.sessionDescription, nil);
    // NSParameterAssert(NO);
}


#pragma mark NSURLSessionTaskDelegate


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:( void (^)(NSURLRequest *) )completionHandler
{
    MRLogD(@"REDIRECT to %@", request.URL, nil);
    completionHandler(request);
}


/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // handle (low level network) error and signal posting complete.
    NSParameterAssert(!error);
}


#pragma mark NSUrlSessionDataDelegate


/* The task has received a response and no further messages will be
 * received until the completion block is called. The disposition
 * allows you to cancel a request or to turn a data task into a
 * download task. This delegate message is optional - if you do not
 * implement it, you can get the response as a property of the task.
 *
 * This method will not be called for background upload tasks (which cannot be converted to download tasks).
 */
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:( void (^)(NSURLSessionResponseDisposition disposition) )completionHandler
{
    completionHandler(NSURLSessionResponseBecomeDownload);
}


#pragma mark NSURLSessionDownloadDelegate


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)task didFinishDownloadingToURL:(NSURL *)location
{
    NSParameterAssert(self.postDelegate);
    MRLogD(@"%@ ORIGINAL: %@ %@", task.taskDescription, task.originalRequest.HTTPMethod, task.originalRequest.URL, nil);
    MRLogD(@"%@ CURRENT : %@ %@", task.taskDescription, task.currentRequest.HTTPMethod, task.currentRequest.URL, nil);
    NSArray *cookies = [session.configuration.HTTPCookieStorage cookiesForURL:task.currentRequest.URL];
    MRLogD(@"cookies %@", cookies, nil);

    NSParameterAssert(task.originalRequest.HTTPShouldHandleCookies);
    // NSParameterAssert(NSURLNetworkServiceTypeBackground == task.originalRequest.networkServiceType);

    NSData *data = [NSData dataWithContentsOfURL:location];
    NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *ret = [self parseHtmlData:data error:nil];
    NSMutableDictionary *post = ret[M_FORM];
    MRLogD(@"%@ %@", task.taskDescription, ret, nil);
    if( !post[F_TOKEN] ) {
        NSError *e = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_NO_TOKEN userInfo:@ { NSURLErrorKey:task.originalRequest.URL, NSLocalizedDescriptionKey:NSLocalizedString(@"Couldn't find token in page.", @"ShaarliM") }
                     ];
        [self.postDelegate shaarli:self didFinishPostWithError:e];
        self.postDelegate = nil;
        return;
    }
    NSParameterAssert(40 == [post[F_TOKEN] length]);
    if( [POST_STEP_1 isEqualToString:task.taskDescription] ) {
        if( ![ret[M_HAS_LOGOUT] boolValue] ) {
            NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:task.currentRequest.URL];
            req.HTTPMethod = @"POST";

            NSDictionary *cd = [session.configuration.URLCredentialStorage credentialsForProtectionSpace:[req.URL protectionSpace]];
            NSParameterAssert(1 == cd.count);
            NSURLCredential *cre = [[cd objectEnumerator] nextObject];

            post[@"login"] = cre.user;
            post[@"password"] = cre.password;
            post[@"returnurl"] = task.originalRequest.URL.absoluteString;
            req.HTTPBody = [post postData];
            NSURLSessionTask *dt = [session downloadTaskWithRequest:req];
            dt.taskDescription = POST_STEP_2;
            [dt resume];
        } else {
            NSError *e = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_LOGOUT_BUTTON_EXPECTED userInfo:@ { NSURLErrorKey:task.originalRequest.URL, NSLocalizedDescriptionKey:NSLocalizedString(@"Wasn't logged in.", @"ShaarliM") }
                         ];
            [self.postDelegate shaarli:self didFinishPostWithError:e];
            self.postDelegate = nil;
        }
        return;
    }
    if( [POST_STEP_2 isEqualToString:task.taskDescription] ) {
        if( [ret[M_HAS_LOGOUT] boolValue] ) {
            NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:task.currentRequest.URL];
            req.HTTPMethod = @"POST";
            NSDictionary *params = [req.URL dictionaryWithHttpFormUrl];
            [post setValue:params[@"post"] forKey:@"lf_" @"url"];
            [post setValue:params[@"title"] forKey:@"lf_" @"title"];
            [post setValue:params[@"description"] forKey:@"lf_" @"description"];
            [post setValue:params[@"source"] forKey:@"lf_" @"source"];

            [post setValue:params[@"tags"] forKey:@"lf_" @"tags"];
            [post setValue:params[@"private"] forKey:@"lf_" @"private"];
#if DEBUG
            [post setValue:@"on" forKey:@"lf_" @"private"];
#endif
            req.HTTPBody = [post postData];
            NSURLSessionTask *dt = [session downloadTaskWithRequest:req];
            dt.taskDescription = POST_STEP_3;
            [dt resume];
        } else {
            NSError *e = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_LOGOUT_BUTTON_EXPECTED userInfo:@ { NSURLErrorKey:task.originalRequest.URL, NSLocalizedDescriptionKey:NSLocalizedString(@"I expected to be logged in now. Looks cookies don't work properly.", @"ShaarliM") }
                         ];
            [self.postDelegate shaarli:self didFinishPostWithError:e];
            self.postDelegate = nil;
        }
        return;
    }
    if( [POST_STEP_3 isEqualToString:task.taskDescription] ) {
        NSError *e = nil;
        if( [ret[M_HAS_LOGOUT] boolValue] ) {
            MRLogD(@"Success! Signal creation of '%@'", task.currentRequest.URL.fragment, nil);
        } else {
            e = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_LOGOUT_BUTTON_EXPECTED userInfo:@ { NSURLErrorKey:task.originalRequest.URL, NSLocalizedDescriptionKey:NSLocalizedString(@"I expected to be logged in now. Looks cookies don't work properly.", @"ShaarliM") }
                ];
        }
        [self.postDelegate shaarli:self didFinishPostWithError:e];
        self.postDelegate = nil;
        return;
    }
    NSParameterAssert(NO);
    NSError *e = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_POST_FALLTHROUGH userInfo:@ { NSURLErrorKey:task.originalRequest.URL, NSLocalizedDescriptionKey:NSLocalizedString(@"This is most likely a programming error.", @"ShaarliM") }
                 ];
    [self.postDelegate shaarli:self didFinishPostWithError:e];
    self.postDelegate = nil;
}


@end
