//
// ShaarliM.m
// ShaarliCompanion
//
// Created by Marcus Rohrmoser on 17.07.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "ShaarliM.h"
#import "PDKeychainBindings.h"
#import <libxml2/libxml/HTMLparser.h>

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

static void FormField_StartElement(void *voidContext, const xmlChar *name, const xmlChar **attributes)
{
    if( 0 != strcmp("input", (const char *)name) )
        return;
    MRLogD(@"<%s>", name, nil);
    assert(voidContext && "ouch");
    NSMutableDictionary *d = (__bridge NSMutableDictionary *)voidContext;

    // refill name + value attributes into hash
    NSMutableDictionary *at = [NSMutableDictionary dictionaryWithCapacity:2];
    for( int i = 0; attributes[i + 1]; i += 2 ) {
        // MRLogD(@"%s=%s", attributes[i], attributes[i + 1], nil);
        if( 0 == strcmp("name", (const char *)attributes[i]) || 0 == strcmp("value", (const char *)attributes[i]) ) {
            NSString *k = [[NSString alloc] initWithCString:(const char *)attributes[i] encoding:NSUTF8StringEncoding];
            at[k] = [[NSString alloc] initWithCString:(const char *)attributes[i + 1] encoding:NSUTF8StringEncoding];
        }
    }
    // ignore empty input fields
    if( at[@"name"] && at[@"value"] )
        d[at[@"name"]] = at[@"value"];
}


static void FormField_StartElement2(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes)
{
    MRLogD(@"<2 %s>", localname, nil);
}


// static void FormField_EndElement(void *voidContext, const xmlChar *name)

static void FormField_EndElement2(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI)
{
    MRLogD(@"</2 %s>", localname, nil);
}


static htmlSAXHandler FormField_Handler = {
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, FormField_StartElement, NULL, // FormField_EndElement,
    NULL, NULL, // FormField_Characters,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, // cdata,
    NULL, 0, NULL, FormField_StartElement2, FormField_EndElement2, NULL
};

/** parse form data (token!) from the HTML response: */
NSDictionary *parseFormFields(NSData *data, id <NSFastEnumeration> fields)
{
    NSMutableDictionary *form = [NSMutableDictionary dictionaryWithCapacity:4];
    htmlParserCtxtPtr ctxt = htmlCreatePushParserCtxt(&FormField_Handler, (__bridge void *)form, (const char *)[data bytes], (int)data.length, "", XML_CHAR_ENCODING_NONE);
    htmlParseChunk(ctxt, "", 0, YES);
    htmlFreeParserCtxt(ctxt);
    MRLogD(@"%@", form, nil);
    return form;
}


#pragma mark -


@interface ShaarliM() <NSURLSessionDataDelegate>
@property (strong, nonatomic) NSURL *endpointUrl;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *passWord;
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
    MRLogD(@"", nil);
    self.userName = [[PDKeychainBindings sharedKeychainBindings] stringForKey:@"userName"];
    self.passWord = [[PDKeychainBindings sharedKeychainBindings] stringForKey:@"passWord"];
    self.endpointUrl = [NSURL URLWithString:[[PDKeychainBindings sharedKeychainBindings] stringForKey:@"endpointUrl"]];
#if 0
    self.endpointUrl = [NSURL URLWithString:@"http://links.mro.name"];
    self.userName = @"mro";
    self.passWord = @"Jahahw7zahKi";
    [self save];
#endif
}


-(void)save
{
    MRLogD(@"", nil);
    [[PDKeychainBindings sharedKeychainBindings] setString:self.userName forKey:@"userName"];
    [[PDKeychainBindings sharedKeychainBindings] setString:self.passWord forKey:@"passWord"];
    [[PDKeychainBindings sharedKeychainBindings] setString:self.endpointUrl.absoluteString forKey:@"endpointUrl"];
}


-(void)updateEndpoint:(NSString *)endpoint secure:(BOOL)secure user:(NSString *)user pass:(NSString *)pass completion:( void (^)(ShaarliM * me, NSError * error) )completion
{
    MRLogD(@"", nil);
    NSURL *ur = [[NSURL URLWithString:[NSString stringWithFormat:@"http%s://%@", (secure ? "s":""), endpoint, nil]] standardizedURL];

    // http://www.objc.io/issues/5-ios7/from-nsurlconnection-to-nsurlsession/
    // http://www.raywenderlich.com/51127/nsurlsession-tutorial

    // 1. GET the ?do=login action to get the token and returnurl as part of the form
    NSURLSession *session = [NSURLSession sharedSession];
    // http://www.raywenderlich.com/51127/nsurlsession-tutorial
    NSURL *u = [NSURL URLWithString:@"?do=login" relativeToURL:ur];
    [[session dataTaskWithURL:u completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
          MRLogD (@"complete %@", error, nil);
          if( error )
              completion (self, error);
          else {
              NSString *token = parseFormFields (data, @[@"token"])[@"token"];
              NSParameterAssert (token);

              NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:u];
              r.HTTPMethod = @"POST";
              r.HTTPBody = [@ { @"login":user, @"password":pass, @"token":token }
                            postData];
              [[session dataTaskWithRequest:r completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                    // check result (HTML content)?
                    if( !error ) {
                        self.endpointUrl = response.URL; // or original ur?
                        self.userName = user;
                        self.passWord = pass;
                        [self save];
                    }
                    completion (self, error);
                }
               ] resume];
          }
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
   (BOOL)private completion:( void (^)(ShaarliM * me, NSError * error) )completion
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSParameterAssert(self.endpointUrl);
    NSParameterAssert(self.userName);
    NSParameterAssert(self.passWord);
    NSParameterAssert(url);
    // test access to post/add link
    NSURL *u2 = [NSURL URLWithString:[@"?post=" stringByAppendingString:[[url description] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] relativeToURL:self.endpointUrl];
    [[session dataTaskWithURL:u2 completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
          MRLogD (@"complete %@", error, nil);
          if( !error ) {
              NSMutableDictionary *form = [parseFormFields (data, @[@"token", @"lf_linkdate"])mutableCopy];
              NSParameterAssert (form[@"token"]);
              NSParameterAssert (form[@"lf_linkdate"]);
              // pull out lf_linkdate, too
              NSMutableURLRequest *r2 = [NSMutableURLRequest requestWithURL:u2];
              r2.HTTPMethod = @"POST";
              NSParameterAssert (form[@"token"]);
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

    // 1. GET the ?do=login action to get the token and returnurl as part of the form
    NSURLSession *session = [NSURLSession sharedSession];
    // http://www.raywenderlich.com/51127/nsurlsession-tutorial
    NSURL *u = [NSURL URLWithString:@"?do=login" relativeToURL:self.endpointUrl];
    [[session dataTaskWithURL:u completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
          MRLogD (@"complete %@", error, nil);
          if( error )
              completionHandler (self, error);
          else {
              NSString *token = parseFormFields (data, @[@"token"])[@"token"];
              NSParameterAssert (token);

              NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:u];
              r.HTTPMethod = @"POST";
              r.HTTPBody = [@ { @"login":self.userName, @"password":self.passWord, @"token":token }
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


@end
