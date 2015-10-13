//
// ShaarliCmd.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 12.10.15.
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

#import "ShaarliCmd.h"
#import <libxml2/libxml/HTMLparser.h>
#import <libxml2/libxml/xpath.h>


@interface ShaarliCmd() {
    htmlParserCtxtPtr ctxHtml;
    xmlXPathContextPtr ctxXPath;
}
@property (nonatomic, readwrite, strong) NSURLResponse *response;
@property (nonatomic, readwrite, assign) NSStringEncoding encoding;
@property (nonatomic, readwrite, assign) BOOL hasLogOutLink;
@end


#pragma mark Internal Helpers (C)

static inline const char *x2c(const xmlChar *c)
{
    return NULL == c ? "" : (const char *)c;
}


static inline NSString *x2o(const xmlChar *c, const NSStringEncoding enc)
{
    return NULL == c ? nil : [[NSString alloc] initWithCString:x2c(c) encoding:enc];
}


static inline const xmlChar *c2x(const char *c)
{
    return (xmlChar *)c;
}


static inline const NSStringEncoding x2e(const xmlCharEncoding e)
{
    assert(XML_CHAR_ENCODING_UTF8 == e && "odd in-memory charset");
    return NSUTF8StringEncoding;
}


/**
 *
 * @param ctxXPath see `xmlXPathNewContext`
 * @param xpathStr something like `string(//foo)`
 * @return
 */
static NSString *stringFromXPath(const xmlXPathContextPtr ctxXPath, const char *xpathStr)
{
    assert(ctxXPath && "must be set.");
    assert( (NULL == ctxXPath->node || ctxXPath->doc == (void *)ctxXPath->node) && "mustn't be set." );
    const NSStringEncoding enc = x2e(ctxXPath->doc->charset);
    const xmlXPathCompExprPtr xpath = xmlXPathCtxtCompile( ctxXPath, c2x(xpathStr) ); // could be cached but I don't consider that worth while
    assert(XML_FROM_NONE == (xmlErrorDomain)ctxXPath->lastError.domain && "XPath eval failure.");
    assert(0 == ctxXPath->lastError.code && "XPath eval failure.");
    assert(xpath && "compile failure.");
    const xmlXPathObjectPtr xpo = xmlXPathCompiledEval(xpath, ctxXPath);
    assert(XML_FROM_NONE == (xmlErrorDomain)ctxXPath->lastError.domain && "XPath eval failure.");
    assert(0 == ctxXPath->lastError.code && "XPath eval failure.");
    assert(xpo && "XPath eval failure.");
    // xmlSaveFormatFileEnc("-", ctxXPath->doc, "UTF-8", 1);
    assert(XPATH_STRING == xpo->type && "XPath result type mismatch.");
    NSString *ret = [[NSString alloc] initWithCString:x2c(xpo->stringval) encoding:enc];

    xmlXPathFreeObject(xpo);
    xmlXPathFreeCompExpr(xpath);
    return ret;
}


static BOOL booleanFromXPath(const xmlXPathContextPtr ctxXPath, const char *xpathStr)
{
    assert(ctxXPath && "must be set.");
    assert( (NULL == ctxXPath->node || ctxXPath->doc == (void *)ctxXPath->node) && "mustn't be set." );
    const NSStringEncoding enc = x2e(ctxXPath->doc->charset);
    const xmlXPathCompExprPtr xpath = xmlXPathCtxtCompile( ctxXPath, c2x(xpathStr) ); // could be cached but I don't consider that worth while
    assert(XML_FROM_NONE == (xmlErrorDomain)ctxXPath->lastError.domain && "XPath eval failure.");
    assert(0 == ctxXPath->lastError.code && "XPath eval failure.");
    assert(xpath && "compile failure.");
    const xmlXPathObjectPtr xpo = xmlXPathCompiledEval(xpath, ctxXPath);
    assert(XML_FROM_NONE == (xmlErrorDomain)ctxXPath->lastError.domain && "XPath eval failure.");
    assert(0 == ctxXPath->lastError.code && "XPath eval failure.");
    assert(xpo && "XPath eval failure.");
    // xmlSaveFormatFileEnc("-", ctxXPath->doc, "UTF-8", 1);
    assert(XPATH_BOOLEAN == xpo->type && "XPath result type mismatch.");
    const BOOL ret = 0 != xpo->boolval;

    xmlXPathFreeObject(xpo);
    xmlXPathFreeCompExpr(xpath);
    return ret;
}


/** Pull out name and value attributes as a NSDictionary.
 *
 * @param ctxXPath see `xmlXPathNewContext`
 * @param xpathStr something like `/html/body//form[@name='loginform']//input[(@type='text' or @type='hidden') and @name and @value]`
 */
static NSMutableDictionary *dictFromXPathFormInputNameValue(const xmlXPathContextPtr ctxXPath, const char *xpathStr)
{
    assert(ctxXPath && "must be set.");
    assert( (NULL == ctxXPath->node || ctxXPath->doc == (void *)ctxXPath->node) && "mustn't be set." );
    const NSStringEncoding enc = x2e(ctxXPath->doc->charset);
    const xmlXPathCompExprPtr xpath = xmlXPathCtxtCompile( ctxXPath, c2x(xpathStr) ); // could be cached but I don't consider that worth while
    assert(XML_FROM_NONE == (xmlErrorDomain)ctxXPath->lastError.domain && "XPath eval failure.");
    assert(0 == ctxXPath->lastError.code && "XPath eval failure.");
    assert(xpath && "compile failure.");
    const xmlXPathObjectPtr xpo = xmlXPathCompiledEval(xpath, ctxXPath);
    assert(XML_FROM_NONE == (xmlErrorDomain)ctxXPath->lastError.domain && "XPath eval failure.");
    assert(0 == ctxXPath->lastError.code && "XPath eval failure.");
    assert(xpo && "XPath eval failure.");

    assert(XPATH_NODESET == xpo->type && "XPath result type mismatch.");
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:10];
    const xmlNodeSetPtr ns = xpo->nodesetval;
    if( !xmlXPathNodeSetIsEmpty(ns) ) {
        for( int i = ns->nodeNr - 1; i >= 0; i-- ) {
            const xmlNodePtr n = ns->nodeTab[i];
            assert(XML_ELEMENT_NODE == n->type && "odd type");
            NSString *name = nil;
            NSString *value = nil;
            if( 0 == strcmp( "input", x2c(n->name) ) ) {
                for( xmlAttr *attr = n->properties; attr; attr = attr->next ) {
                    assert(XML_TEXT_NODE == attr->children->type && "odd node type");
                    assert(NULL == attr->children->next && "expected no siblings");
                    // MRLogD(@"'%s'='%s'", attr->name, attr->children->content, nil);
                    if( 0 == strcmp( "name", x2c(attr->name) ) )
                        name = x2o(attr->children->content, enc);
                    else if( 0 == strcmp( "value", x2c(attr->name) ) )
                        value = x2o(attr->children->content, enc);
                    else if( 0 == strcmp( "checked", x2c(attr->name) ) )
                        value = @"on";
                    if( name && value )
                        break;
                }
            } else if( 0 == strcmp( "textarea", x2c(n->name) ) ) {
                {
                    xmlChar *s = xmlNodeGetContent(n);
                    value = x2o(s, enc);
                    xmlFree(s);
                }
                for( xmlAttr *attr = n->properties; attr; attr = attr->next ) {
                    assert(XML_TEXT_NODE == attr->children->type && "odd node type");
                    assert(NULL == attr->children->next && "expected no siblings");
                    // MRLogD(@"'%s'='%s'", attr->name, attr->children->content, nil);
                    if( 0 == strcmp( "name", x2c(attr->name) ) )
                        name = x2o(attr->children->content, enc);
                    if( name )
                        break;
                }
            } else {
                MRLogD(@"strange element", nil);
            }
            if( name )
                ret[name] = value ? value : @"";
            else
                MRLogW(@"@name missing.", nil);
        }
    }

    xmlXPathFreeObject(xpo);
    xmlXPathFreeCompExpr(xpath);
    return ret;
}


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


@implementation ShaarliCmd


#pragma mark Internal


-(BOOL)parseAnyResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error
{
    // cleanup
    if( ctxXPath )
        xmlXPathFreeContext(ctxXPath);
    if( ctxHtml )
        htmlFreeParserCtxt(ctxHtml);
    self.response = response;
    if( error )
        *error = nil;
    if( !data )
        return NO;
    // MRLogD(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], nil);
    {
        // parse HTML
        ctxHtml = htmlCreatePushParserCtxt(NULL, NULL, (const char *)[data bytes], (int)data.length, "", XML_CHAR_ENCODING_NONE);
        ctxHtml->linenumbers = 1;
        ctxHtml->options = HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING | HTML_PARSE_NONET;
        NSAssert(0 == ctxHtml->errNo, @"foo", nil);
        NSAssert(NULL != ctxHtml, @"no HTML context", nil);
        const xmlParserErrors errorCode = htmlParseChunk(ctxHtml, "", 0, YES);
        // NSAssert(XML_ERR_OK == errorCode, @"foo", nil);
        NSAssert(NULL != ctxHtml->myDoc, @"no document found", nil);
    }
    {
        // create a XPath context
        ctxXPath = xmlXPathNewContext(ctxHtml->myDoc);
        NSAssert(NULL != ctxXPath, @"foo", nil);
        NSAssert(XML_FROM_NONE == ctxXPath->lastError.domain, @"foo", nil);
        NSAssert(0 == ctxXPath->lastError.code, @"foo", nil);
        self.encoding = x2e(ctxXPath->doc->charset);
    }
    // extract error in case
    NSString *errMsg = stringFromXPath(ctxXPath, "normalize-space(string(/html/body//*[@id='headerform']/text()))");
    if( 0 == errMsg.length ) {
        errMsg = stringFromXPath(ctxXPath, "normalize-space(string(/html[1=count(*)]/head[1=count(*)]/script[starts-with(.,'alert(')]))");
        if( 0 < errMsg.length ) {
            errMsg = [errMsg stringByReplacingOccurrencesOfString:@"alert(\"" withString:@""];
            errMsg = [errMsg stringByReplacingOccurrencesOfString:@"\");document.location='?do=login';" withString:@""];
        }
    }
    if( 0 == errMsg.length )
        errMsg = nil;
    if( errMsg ) {
        if( error ) {
            // how to map the error message to a code?
            *error = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_BANNED userInfo:@ { NSURLErrorKey:response.URL, NSLocalizedDescriptionKey:NSLocalizedString(errMsg, @"ShaarliResponse.m") }
                     ];
        }
        return NO;
    }
    return YES;
}


-(BOOL)booleanForXPath:(NSString *)xpath error:(NSError **)error
{
    return booleanFromXPath(ctxXPath, [xpath cStringUsingEncoding:self.encoding]);
}


-(NSMutableDictionary *)fetchForm:(NSString *)formName error:(NSError **)error
{
    if( error )
        *error = nil;
    NSString *xpath = [NSString stringWithFormat:@"/html/body//form[@name='%1$@']//input[(@type='text' or @type='password' or @type='hidden' or @type='checkbox') and @name] | /html/body//form[@name='%1$@']//textarea[@name]", formName, nil];
    return dictFromXPathFormInputNameValue(ctxXPath, [xpath cStringUsingEncoding:self.encoding]);
}


#pragma mark Public Implementation


-(instancetype)initWithResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error
{
    if( !data )
        return nil;
    if( self = [super init] ) {
        if( ![self parseAnyResponse:response data:data error:error] )
            return nil;
    }
    return self;
}


-(void)dealloc
{
    if( ctxXPath )
        xmlXPathFreeContext(ctxXPath);
    if( ctxHtml )
        htmlFreeParserCtxt(ctxHtml);
}


-(BOOL)hasLogOutLink
{
    return [@"?do=logout" isEqualToString:stringFromXPath(ctxXPath, "normalize-space(string(/html/body//a[@href='?do=logout']/@href))")];
}


-(NSString *)fetchTitle:(NSError **)error
{
    if( error )
        *error = nil;
    return stringFromXPath(ctxXPath, "normalize-space(string(/html/body//*[@id='shaarli_title']))");
}


-(NSMutableDictionary *)fetchForm:(NSError **)error
{
    return [self fetchForm:self.form error:error];
}


-(NSString *)fetchToken:(NSError **)error
{
    NSString *ret = [self fetchForm:error][@"token"];
    if( !ret )
        return nil;
    return ret;
}


-(BOOL)receivedPost1Response:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error
{
    [self parseAnyResponse:response data:data error:error];
    if( error && *error )
        return NO;
    if( !self.hasLogOutLink ) {
        if( error )
            *error = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:SHAARLI_ERROR_LOGOUT_BUTTON_EXPECTED userInfo:@ { NSURLErrorKey:response.URL, NSLocalizedDescriptionKey:NSLocalizedString([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], @"ShaarliResponse.m") }
                     ];
        return NO;
    }
    return YES;
}


@end
