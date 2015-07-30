//
// ShaarliM.m
// ShaarliCompanion
//
// Created by Marcus Rohrmoser on 17.07.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "ShaarliM.h"
#import <libxml2/libxml/HTMLparser.h>

#define USE_KEYCHAIN 1

@interface NSURL(ProtectionSpace)
@property (nonatomic, readonly, assign) NSURLProtectionSpace *protectionSpace;
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

@implementation NSDictionary(PostData)

-(NSData *)postData
{
    NSMutableString *s = [NSMutableString stringWithCapacity:100];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * stop) {
         [s appendFormat:@"%@=%@&", [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [obj stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
     }
    ];
    return [s dataUsingEncoding:NSUTF8StringEncoding];
}


@end


#pragma mark libxml2 LoginForm


#define T_A @"a"
#define T_DIV @"div"
#define T_SPAN @"span"

#define M_TITLE @"title"
#define M_TEXT @"text"
#define M_FORM @"form"
#define M_ID_HEADERFORM @"headerform"

#define F_TOKEN @"token"

#define M_HAS_LOGOUT @"has_logout"

static void ShaarliHtml_StartElement(void *voidContext, const xmlChar *name, const xmlChar **attributes)
{
    assert(voidContext && "ouch");
    NSMutableDictionary *d = (__bridge NSMutableDictionary *)voidContext;

    if( 0 == strcmp("a", (const char *)name) ) {
        for( int i = 0; attributes[i + 1]; i += 2 ) {
            const char *name = (const char *)attributes[i];
            const char *value = (const char *)attributes[i + 1];

            if( 0 == strcmp("href", name) && 0 == strcmp("?", value) )
                d[T_A] = M_TITLE;
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
        }
        return;
    }
    if( 0 == strcmp("div", (const char *)name) ) {
        for( int i = 0; attributes[i + 1]; i += 2 ) {
            const char *name = (const char *)attributes[i];
            const char *value = (const char *)attributes[i + 1];

            if( 0 == strcmp("id", name) && 0 == strcmp("headerform", value) )
                d[T_DIV] = M_ID_HEADERFORM;
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

    if( [M_TITLE isEqualToString:d[T_A]] || [M_ID_HEADERFORM isEqualToString:d[T_DIV]] ) {
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
NSDictionary *parseShaarliHtml(NSData *data, id <NSFastEnumeration> fields)
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


@interface ShaarliM() <NSURLSessionDataDelegate>
@property (strong, nonatomic) NSURL *endpointUrl;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *passWord;
@property (strong, nonatomic) NSString *title;
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


-(void)load
{
    NSUserDefaults *d = [NSUserDefaults shaarliDefaults];
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
#if 0
    self.endpointUrl = [NSURL URLWithString:@"http://links.mro.name"];
    self.userName = @"mro";
    self.passWord = @"Jahahw7zahKi";
    self.title = @"links.mro";
    [self save];
#endif
    MRLogD(@"%@", self.title, nil);
    MRLogD(@"%@", self.userName, nil);
}


-(void)save
{
    MRLogD(@"", nil);
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
          NSDictionary *r = parseShaarliHtml (data, @[F_TOKEN]);
          if( [r[M_HAS_LOGOUT] boolValue] && !force ) {
              // check if there's a logout link - we're already logged in then.
              NSParameterAssert (cre0);
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


#pragma mark -



-(void)fetchTagCloud:( void (^)(ShaarliM * me, NSError * error) )completionHandler
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSParameterAssert(self.userName);
    NSParameterAssert(self.passWord);
    NSParameterAssert(self.endpointUrl);
    // test access to tag cloud
    NSURL *u1 = [NSURL URLWithString:@"?do=tagcloud" relativeToURL:self.endpointUrl];
    [[session dataTaskWithURL:u1 completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
          MRLogD (@"complete %@", error, nil);
          if( !error ) {
              // MRLogD (@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], nil);
          }
      }
     ] resume];
}


-(void)postURL:(NSURL *)url title:(NSString *)title tags:(id <NSFastEnumeration>)tags description:(NSString *)desc private:
   (BOOL)private session:(NSURLSession *)session completion:( void (^)(ShaarliM * me, NSError * error) )completion
{
    if( !session )
        session = [NSURLSession sharedSession];
    else {
        MRLogD(@"re-use session '%@', %@", session.sessionDescription, session.configuration.sharedContainerIdentifier, nil);
    }
    NSParameterAssert(self.endpointUrl);
    NSParameterAssert(self.userName);
    NSParameterAssert(self.passWord);
    NSParameterAssert(url);

    // test access to post/add link
    NSURL *u2 = [NSURL URLWithString:[@"?post=" stringByAppendingString:[url.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] relativeToURL:self.endpointUrl];
    [[session dataTaskWithURL:u2 completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
          MRLogD (@"complete %@", error, nil);
          if( !error ) {
              NSMutableDictionary *form = [parseShaarliHtml (data, @[F_TOKEN, @"lf_linkdate"])[M_FORM] mutableCopy];
              NSParameterAssert (form[F_TOKEN]);
              NSParameterAssert (form[@"lf_linkdate"]);
              // pull out lf_linkdate, too
              NSMutableURLRequest *r2 = [NSMutableURLRequest requestWithURL:u2];
              r2.HTTPMethod = @"POST";
              NSParameterAssert (form[F_TOKEN]);
              /*
               * lf_description  descr
               * lf_private      on
               * lf_tags         t1 t2
               * lf_title        title
               * lf_url	         http://foo
               * returnurl       http://links.mro.name/?do=addlink
               * save_edit	     Save
               * lf_linkdate     20150718_003725    local time / server time?
               * token	         c867d40b2afd895bf7c1f569a20c607f9ffc8f50
               */
              form[@"lf_private"] = private ? @"on":@"off";

              // allow manual edit!

              r2.HTTPBody = [form postData];
              [[session dataTaskWithRequest:r2 completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                    MRLogD (@"complete %@", error, nil);
                    if( !error ) {
                        MRLogD (@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], nil);
                    }
                }
               ] resume];
          }
      }
     ] resume];
}


-(void)login:( void (^)(ShaarliM * me, NSError * error) )completionHandler
{
    MRLogD(@"", nil);

    // http://www.objc.io/issues/5-ios7/from-nsurlconnection-to-nsurlsession/
    // http://www.raywenderlich.com/51127/nsurlsession-tutorial

    NSParameterAssert(self.endpointUrl);
    NSParameterAssert(self.userName);
    NSParameterAssert(self.passWord);

    // 1. GET the ?do=login action to get the token and returnurl as part of the form
    NSURLSession *session = [NSURLSession sharedSession];

    // NSURLCredential *cre = [NSURLCredential credentialWithUser:self.userName password:self.passWord persistence:NSURLCredentialPersistenceForSession];
    NSDictionary *d = [session.configuration.URLCredentialStorage credentialsForProtectionSpace:self.endpointUrl.protectionSpace];
    NSURLCredential *cre = d[self.userName];
    NSParameterAssert(nil == cre);
    cre = [NSURLCredential credentialWithUser:self.userName password:self.passWord persistence:NSURLCredentialPersistenceSynchronizable];
    MRLogD(@"%@", cre, nil);
    [session.configuration.URLCredentialStorage setCredential:cre forProtectionSpace:self.endpointUrl.protectionSpace];

    // http://www.raywenderlich.com/51127/nsurlsession-tutorial
    NSURL *u = [NSURL URLWithString:@"?do=login" relativeToURL:self.endpointUrl];
    [[session dataTaskWithURL:u completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
          MRLogD (@"complete %@", error, nil);
          if( error )
              completionHandler (self, error);
          else {
              NSString *token = parseShaarliHtml (data, @[F_TOKEN])[M_FORM][F_TOKEN];
              NSParameterAssert (token);

              NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:u];
              r.HTTPMethod = @"POST";
              r.HTTPBody = [@ { @"login":self.userName, @"password":self.passWord, F_TOKEN:token }
                            postData];
              [[session dataTaskWithRequest:r completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                    // check result?
                    completionHandler (self, error);
                }
               ] resume];
          }
      }
     ] resume];
}


-(BOOL)logout:(NSError **)err
{
    MRLogD(@"", nil);
    return NO;
}


-(BOOL)refresh:(NSError **)err
{
    MRLogD(@"", nil);
    return NO;
}


#pragma NSURLSessionDelegate


/* The last message a session receives.  A session will only become
 * invalid because of a systemic error or when it has been
 * explicitly invalidated, in which case the error parameter will be nil.
 */
-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    MRLogD(@"-", nil);
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
    MRLogD(@"-", nil);
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
    MRLogD(@"-", nil);
    NSParameterAssert(NO);
}


@end
