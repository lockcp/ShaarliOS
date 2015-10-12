//
// ShaarliResponseXsltTest.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 02.08.15.
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

#import <UIKit/UIKit.h>
#import "XCTestCase+Tools.h"

#import <libxml2/libxml/HTMLparser.h>
#import <libxml2/libxml/xpath.h>

static inline const char *x2c(const xmlChar *c)
{
    return (const char *)c;
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
    assert(NULL == ctxXPath->node && "mustn't be set.");
    const NSStringEncoding enc = x2e(ctxXPath->doc->charset);
    const xmlXPathCompExprPtr xpath = xmlXPathCtxtCompile( ctxXPath, c2x(xpathStr) ); // could be cached but I don't consider that worth while
    assert(XML_FROM_NONE == (xmlErrorDomain)ctxXPath->lastError.domain && "XPath eval failure.");
    assert(0 == ctxXPath->lastError.code && "XPath eval failure.");
    assert(xpath && "compile failure.");
    const xmlXPathObjectPtr xpo = xmlXPathCompiledEval(xpath, ctxXPath);
    assert(XML_FROM_NONE == (xmlErrorDomain)ctxXPath->lastError.domain && "XPath eval failure.");
    assert(0 == ctxXPath->lastError.code && "XPath eval failure.");
    assert(xpo && "XPath eval failure.");

    assert(XPATH_STRING == xpo->type && "XPath result type mismatch.");
    NSString *ret = [[NSString alloc] initWithCString:x2c(xpo->stringval) encoding:enc];

    xmlXPathFreeObject(xpo);
    xmlXPathFreeCompExpr(xpath);
    return ret;
}


/** Pull out name and value attributes as a NSDictionary.
 *
 * @param ctxXPath see `xmlXPathNewContext`
 * @param xpathStr something like `/html/body//form[@name='loginform']//input[(@type='text' or @type='hidden') and @name and @value]`
 */
static NSDictionary *dictFromXPathFormInputNameValue(const xmlXPathContextPtr ctxXPath, const char *xpathStr)
{
    assert(ctxXPath && "must be set.");
    assert(NULL == ctxXPath->node && "mustn't be set.");
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
    for( int i = ns->nodeNr - 1; i >= 0; i-- ) {
        const xmlNodePtr n = ns->nodeTab[i];
        assert(XML_ELEMENT_NODE == n->type && "odd type");
        assert(0 == strcmp( "input", x2c(n->name) ) && "odd name");
        // const size_t siz = sizeof(n->properties);
        NSString *name = nil;
        NSString *value = nil;
        for( xmlAttr *attr = n->properties; attr; attr = attr->next ) {
            assert(XML_TEXT_NODE == attr->children->type && "odd node type");
            assert(NULL == attr->children->next && "expected no siblings");
            // MRLogD(@"'%s'='%s'", attr->name, attr->children->content, nil);
            if( 0 == strcmp( "name", x2c(attr->name) ) )
                name = [[NSString alloc] initWithCString:x2c(attr->children->content) encoding:enc];
            else if( 0 == strcmp( "value", x2c(attr->name) ) )
                value = [[NSString alloc] initWithCString:x2c(attr->children->content) encoding:enc];
        }
        if( name && value )
            ret[name] = value;
        else if( !name )
            MRLogW(@"@name missing.", nil);
    }

    xmlXPathFreeObject(xpo);
    xmlXPathFreeCompExpr(xpath);
    return ret;
}


@interface ShaarliResponseXPathTest : XCTestCase
@end

@implementation ShaarliResponseXPathTest

-(void)testStringFromXPath
{
    NSData *data = [self dataWithContentsOfFixture:@"testLogin.0" withExtension:@"html"];
    XCTAssertEqual(2509, data.length, @"foo", nil);
    NSString *shaarliTitle = nil;
    NSString *token = nil;
    {
        const htmlParserCtxtPtr ctxHtml = htmlCreatePushParserCtxt(NULL, NULL, (const char *)[data bytes], (int)data.length, "", XML_CHAR_ENCODING_NONE);
        XCTAssertEqual(0, ctxHtml->errNo, @"foo", nil);
        XCTAssert(NULL != ctxHtml, @"foo", nil);
        const xmlParserErrors errorCode = htmlParseChunk(ctxHtml, "", 0, YES);
        XCTAssertEqual(XML_ERR_OK, errorCode, @"foo", nil);
        XCTAssert(NULL != ctxHtml->myDoc, @"foo", nil);
        {
            const xmlXPathContextPtr ctxXpath = xmlXPathNewContext(ctxHtml->myDoc);
            XCTAssert(NULL != ctxXpath, @"foo", nil);
            XCTAssertEqual(XML_FROM_NONE, ctxXpath->lastError.domain, @"foo", nil);
            XCTAssertEqual(0, ctxXpath->lastError.code, @"foo", nil);

            shaarliTitle = stringFromXPath(ctxXpath, "string(/html/body//*[@id='shaarli_title'])");
            token = stringFromXPath(ctxXpath, "string(/html/body//form[@name='loginform']//input[@name='token']/@value)");

            xmlXPathFreeContext(ctxXpath);
        }
        htmlFreeParserCtxt(ctxHtml);
    }
    XCTAssertEqualObjects(@"links.mro", shaarliTitle, @"foo", nil);
    XCTAssertEqualObjects(@"20119241badf78a3dcfa55ae58eab429a5d24bad", token, @"foo", nil);
}


-(void)testDictFromXPathFormInputNameValue
{
    NSData *data = [self dataWithContentsOfFixture:@"testLogin.0" withExtension:@"html"];
    XCTAssertEqual(2509, data.length, @"foo", nil);
    NSDictionary *form = nil;
    {
        const htmlParserCtxtPtr ctxHtml = htmlCreatePushParserCtxt(NULL, NULL, (const char *)[data bytes], (int)data.length, "", XML_CHAR_ENCODING_NONE);
        XCTAssertEqual(0, ctxHtml->errNo, @"foo", nil);
        XCTAssert(NULL != ctxHtml, @"foo", nil);
        const xmlParserErrors errorCode = htmlParseChunk(ctxHtml, "", 0, YES);
        XCTAssertEqual(XML_ERR_OK, errorCode, @"foo", nil);
        XCTAssert(NULL != ctxHtml->myDoc, @"foo", nil);
        {
            const xmlXPathContextPtr ctxXpath = xmlXPathNewContext(ctxHtml->myDoc);
            XCTAssert(NULL != ctxXpath, @"foo", nil);
            XCTAssertEqual(XML_FROM_NONE, ctxXpath->lastError.domain, @"foo", nil);
            XCTAssertEqual(0, ctxXpath->lastError.code, @"foo", nil);

            form = dictFromXPathFormInputNameValue(ctxXpath, "/html/body//form[@name='loginform']//input[(@type='text' or @type='hidden') and @name and @value]");

            xmlXPathFreeContext(ctxXpath);
        }
        htmlFreeParserCtxt(ctxHtml);
    }
    XCTAssertEqual(2, form.count, @"foo", nil);
    XCTAssertEqualObjects(@"http://links.mro.name/", form[@"returnurl"], @"foo", nil);
    XCTAssertEqualObjects(@"20119241badf78a3dcfa55ae58eab429a5d24bad", form[@"token"], @"foo", nil);
}


@end
