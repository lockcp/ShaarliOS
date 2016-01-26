//
// ShaarliStateParseTest.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 02.08.15.
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

#import <UIKit/UIKit.h>
#import "XCTestCase+Tools.h"
#import "MROStateMachine.h"


#pragma mark The Parser


#define M_FORM @"form"
#define F_TOKEN F_K_TOKEN
#define M_HAS_LOGOUT @"has_logout"

#define T_A @"a"
#define T_DIV @"div"
#define T_SPAN @"span"

#define M_TITLE @"title"
#define M_TEXT @"text"
#define M_TAGS @"tags"
#define M_ID_HEADERFORM @"headerform"
#define M_ID_CLOUDTAG @"cloudtag"

#define M_TAG_COUNT @"tag count"
#define M_TAG_HREF @"tag href"
#define M_TAG_LABEL @"tag label"

#define M_STATE_MACHINE @"statemachine"

#import <libxml2/libxml/HTMLparser.h>

static void ShaarliHtml_StartElement(void *voidContext, const xmlChar *name, const xmlChar **attributes)
{
    assert(voidContext && "ouch");
    NSMutableDictionary *d = (__bridge NSMutableDictionary *)voidContext;
    MROStateMachine *sm = d[M_STATE_MACHINE];

    if( [sm isCurrentStateName:@"response"] && 0 == strcmp("div", (const char *)name) && 0 == strcmp("id", (const char *)attributes[0]) && 0 == strcmp("headerform", (const char *)attributes[1]) ) {
        [sm sendAction:@selector(transitionForm:)];
    }
}


static void ShaarliTextRefill(NSMutableDictionary *d, NSString *mark, NSString *tag)
{
    NSMutableData *dat = d[M_TEXT];
    NSString *str = [[NSString alloc] initWithData:dat encoding:NSUTF8StringEncoding];
    d[mark] = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [d removeObjectForKey:tag];
    [dat setData:nil];
}


static void ShaarliHtml_EndElement(void *voidContext, const xmlChar *name)
{
    assert(voidContext && "ouch");
    NSMutableDictionary *d = (__bridge NSMutableDictionary *)voidContext;
}


static void ShaarliHtml_Characters(void *voidContext, const xmlChar *ch, int len)
{
    assert(voidContext && "ouch");
    NSMutableDictionary *d = (__bridge NSMutableDictionary *)voidContext;
}


static htmlSAXHandler FormField_Handler = {
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ShaarliHtml_StartElement, ShaarliHtml_EndElement,
    NULL, ShaarliHtml_Characters,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, // cdata,
    NULL, 0, NULL, NULL, NULL, NULL
};


#pragma mark -

@interface ShaarliStateParseTest : XCTestCase
@end

@implementation ShaarliStateParseTest

#pragma mark State Machine Actions

/** parse form data (token!) from the HTML response: */
-(NSDictionary *)parseShaarliHtml:(NSData *)data error:(NSError **)error
{
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:4];

    MROStateMachine *sm = [[MROStateMachine alloc] initWithTarget:self name:@"Shaarli Html Responses"];
    [sm addTransitionFrom:@"response" to:@"title" guard:nil];
    [sm addTransitionFrom:@"title" to:@"title"];
    [sm addTransitionFrom:@"title" to:@"response"];

    [sm addTransitionFrom:@"response" to:@"form"];
    [sm addTransitionFrom:@"form" to:@"field"];
    [sm addTransitionFrom:@"field" to:@"form"];
    [sm addTransitionFrom:@"form" to:@"response"];

    [sm addTransitionFrom:@"response" to:@"error"];
    [sm addTransitionFrom:@"error" to:@"error"];
    [sm addTransitionFrom:@"error" to:@"logoutNode"];
    [sm addTransitionFrom:@"logoutNode" to:@"response"];
    [sm addTransitionFrom:@"error" to:@"response"];

    [sm addTransitionFrom:@"response" to:@"tagCloud"];
    [sm addTransitionFrom:@"tagCloud" to:@"tagCount"];
    [sm addTransitionFrom:@"tagCount" to:@"tagHref"];
    [sm addTransitionFrom:@"tagCount" to:@"tagCount"];
    [sm addTransitionFrom:@"tagHref" to:@"tagLabel"];
    [sm addTransitionFrom:@"tagLabel" to:@"tagLabel"];
    [sm addTransitionFrom:@"tagLabel" to:@"tagCloud"];
    [sm addTransitionFrom:@"tagCloud" to:@"response"];

    NSError *err = nil;
    [sm buildMachineWithStartState:@"response" error:&err];
    NSParameterAssert(nil == err);
    // MRLogD(@"%@", [sm descriptionDot], nil);
    d[M_STATE_MACHINE] = sm;

    htmlParserCtxtPtr ctxt = htmlCreatePushParserCtxt(&FormField_Handler, (__bridge void *)d, (const char *)[data bytes], (int)data.length, "", XML_CHAR_ENCODING_NONE);
    htmlParseChunk(ctxt, "", 0, YES);
    htmlFreeParserCtxt(ctxt);
    // MRLogD(@"%@", d, nil);
    return d;
}


-(void)transitionError:(MROTransition *)t
{
    ;
}


-(void)transitionField:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


-(void)transitionForm:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


-(void)transitionLogoutNode:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


-(void)transitionResponse:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


-(void)transitionTagCloud:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


-(void)transitionTagCount:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


-(void)transitionTagHref:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


-(void)transitionTagLabel:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


-(void)transitionTitle:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


#pragma mark foo


-(void)_testBanned
{
    NSDictionary *ret = [self parseShaarliHtml:[self dataWithContentsOfFixture:@"banned" withExtension:@"html"] error:nil]; // parseShaarliHtml([self dataWithContentsOfFixture:@"banned" withExtension:@"html"], nil);
    // MRLogD(@"%@", ret, nil);
    XCTAssertEqual(2, ret.count, @"entries' count");
    XCTAssertEqualObjects(@"links.mro", ret[M_TITLE], @"");
    XCTAssertEqualObjects(@"You have been banned from login after too many failed attempts. Try later.", ret[@"headerform"], @"");
    XCTAssertEqual(0, [ret[M_FORM] count], @"entries' count");
}


-(void)_testParseShaarliHtml
{
    {
        NSDictionary *ret = [self parseShaarliHtml:[self dataWithContentsOfFixture:@"testLogin.ok" withExtension:@"html"] error:nil]; // parseShaarliHtml([self dataWithContentsOfFixture:@"testLogin.ok" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(4, ret.count, @"entries' count");
        XCTAssertEqualObjects(@ (1), ret[M_HAS_LOGOUT], @"");
        XCTAssertEqualObjects(@"links.mro", ret[M_TITLE], @"");
        XCTAssertNotNil(ret[@"headerform"], @"");
        XCTAssertEqual(5, [ret[M_FORM] count], @"entries' count");
        XCTAssertEqualObjects(@"20150715_200440", ret[M_FORM][@"edit_link"], @"");
        XCTAssertEqualObjects(@"20150715_200440", ret[M_FORM][@"lf_linkdate"], @"");
        XCTAssertEqualObjects(@"", ret[M_FORM][@"searchtags"], @"");
        XCTAssertEqualObjects(@"", ret[M_FORM][@"searchterm"], @"");
        XCTAssertEqualObjects(@"6ff77552e09da9ef31e0e9d0b717da8933f68975", ret[M_FORM][F_K_TOKEN], @"");
    }
    {
        NSDictionary *ret = [self parseShaarliHtml:[self dataWithContentsOfFixture:@"testLogin.0" withExtension:@"html"] error:nil]; // parseShaarliHtml([self dataWithContentsOfFixture:@"testLogin.0" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(3, ret.count, @"entries' count");
        XCTAssertEqualObjects(@"links.mro", ret[M_TITLE], @"");
        XCTAssertNotNil(ret[@"headerform"], @"");
        XCTAssertEqual(2, [ret[M_FORM] count], @"entries' count");
        XCTAssertEqualObjects(@"http://links.mro.name/", ret[M_FORM][F_K_RETURNURL], @"");
        XCTAssertEqualObjects(@"20119241badf78a3dcfa55ae58eab429a5d24bad", ret[M_FORM][F_K_TOKEN], @"");
    }
    {
        NSDictionary *ret = [self parseShaarliHtml:[self dataWithContentsOfFixture:@"05.addlink-1" withExtension:@"html"] error:nil]; // parseShaarliHtml([self dataWithContentsOfFixture:@"05.addlink-1" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(4, ret.count, @"entries' count");
        XCTAssertEqualObjects(@"links.mro", ret[M_TITLE], @"");
        XCTAssertEqualObjects(@ (YES), ret[M_HAS_LOGOUT], @"");
        XCTAssertNotNil(ret[@"headerform"], @"");
        XCTAssertEqual(0, [ret[M_FORM] count], @"entries' count");
    }
    {
        NSDictionary *ret = [self parseShaarliHtml:[self dataWithContentsOfFixture:@"05.addlink-2" withExtension:@"html"] error:nil]; // parseShaarliHtml([self dataWithContentsOfFixture:@"05.addlink-2" withExtension:@"html"], nil);
        // MRLogD(@"%@", ret, nil);
        XCTAssertEqual(3, ret.count, @"entries' count");
        XCTAssertEqualObjects(@"links.mro", ret[M_TITLE], @"");
        XCTAssertEqualObjects(@ (YES), ret[M_HAS_LOGOUT], @"");
        XCTAssertEqual(8, [ret[M_FORM] count], @"entries' count");
        XCTAssertEqualObjects(@"Cancel", ret[M_FORM][@"cancel_edit"], @"");
        XCTAssertEqualObjects(@"20150719_173950", ret[M_FORM][@"lf_linkdate"], @"");
        XCTAssertEqualObjects(@"", ret[M_FORM][K_F_LF_TAGS], @"");
        XCTAssertEqualObjects(@"Note: ", ret[M_FORM][K_F_LF_TITLE], @"");
        XCTAssertEqualObjects(@"?tgI8rw", ret[M_FORM][K_F_LF_URL], @"");
        XCTAssertEqualObjects(@"http://links.mro.name/?do=login&post=", ret[M_FORM][F_K_RETURNURL], @"");
        XCTAssertEqualObjects(@"Save", ret[M_FORM][@"save_edit"], @"");
        XCTAssertEqualObjects(@"e90b4ab4846c221880872003ba47859183da4e6e", ret[M_FORM][F_K_TOKEN], @"");
    }
}


-(void)_testParseHtmlTags
{
    NSDictionary *ret = [self parseShaarliHtml:[self dataWithContentsOfFixture:@"03.tagcloud" withExtension:@"html"] error:nil]; // parseShaarliHtml([self dataWithContentsOfFixture:@"03.tagcloud" withExtension:@"html"], nil);
    // MRLogD(@"%@", ret, nil);
    XCTAssertEqual(2, ret.count, @"entries' count");
    XCTAssertEqualObjects(@"links.mro", ret[M_TITLE], @"");
    NSArray *tags = ret[@"tags"];
    MRLogD(@"%@", tags, nil);
    XCTAssertEqual(1794, tags.count, @"");
    {
        NSArray *sorted = [tags sortedArrayUsingComparator:^NSComparisonResult (NSDictionary * t1, NSDictionary * t2) {
                               const NSComparisonResult r0 = [t2[@"count"] compare:t1[@"count"]];
                               if( r0 != NSOrderedSame )
                                   return r0;
                               return [t1[@"label"] compare:t2[@"label"] options:0];
                           }
                          ];
        XCTAssertEqualObjects (@"Software", [sorted firstObject][@"label"], @"");
        XCTAssertEqualObjects (@ (170), [sorted firstObject][@"count"], @"");

        XCTAssertEqualObjects (@"§99StGB", [sorted lastObject][@"label"], @"");
        XCTAssertEqualObjects (@ (1), [sorted lastObject][@"count"], @"");
    }
}

@end
