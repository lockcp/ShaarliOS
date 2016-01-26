//
// ShaarliOSTests.m
// ShaarliOSTests
//
// Created by Marcus Rohrmoser on 18.03.15.
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

#import "XCTestCase+Tools.h"
#import "MROStateMachine.h"

@interface ShaarliOSTests : XCTestCase
@property (nonatomic, readwrite, strong) NSString *scheme;
@property (nonatomic, readwrite, assign) BOOL authMissing;
@end

@implementation ShaarliOSTests

-(void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}


-(void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


#pragma mark - Many states, explicit state 'scheme'

-(void)testUpdateEndpointFSMVerbose
{
    MROStateMachine *sm = [[MROStateMachine alloc] initWithTarget:self name:@"Connect Endpoint"];
    [sm addTransitionFrom:@"HttpAuth" to:@"error"];
    [sm addTransitionFrom:@"HttpAuth" to:@"GetHttpLogin" guard:[NSPredicate predicateWithFormat:@"scheme = 'http'", nil]];
    [sm addTransitionFrom:@"HttpAuth" to:@"GetHttpsLogin" guard:[NSPredicate predicateWithFormat:@"scheme = 'https'", nil]];
    [sm addTransitionFrom:@"GetHttpLogin" to:@"HttpAuth" guard:[NSPredicate predicateWithFormat:@"YES = authMissing", nil]];
    [sm addTransitionFrom:@"GetHttpLogin" to:@"error"];
    [sm addTransitionFrom:@"GetHttpLogin" to:@"PostHttpLogin" guard:[NSPredicate predicateWithFormat:@"NO = authMissing"]];
    [sm addTransitionFrom:@"GetHttpsLogin" to:@"HttpAuth"];
    [sm addTransitionFrom:@"GetHttpsLogin" to:@"error"];
    [sm addTransitionFrom:@"GetHttpsLogin" to:@"GetHttpLogin" guard:[NSPredicate predicateWithFormat:@"NO = authMissing"]];
    [sm addTransitionFrom:@"GetHttpsLogin" to:@"PostHttpsLogin" guard:[NSPredicate predicateWithFormat:@"NO = authMissing"]];
    [sm addTransitionFrom:@"PostHttpLogin" to:@"error"];
    [sm addTransitionFrom:@"PostHttpLogin" to:@"success"];
    [sm addTransitionFrom:@"PostHttpsLogin" to:@"success"];
    [sm addTransitionFrom:@"PostHttpsLogin" to:@"error"];
    [sm buildMachineWithStartState:@"GetHttpsLogin" error:nil];
    MRLogD(@"%@", [sm descriptionDot], nil);

    XCTAssertEqualObjects(@"GetHttpsLogin", sm.currentState.name, @"foo", nil);
    self.scheme = HTTP_HTTP;
    [sm sendAction:@selector(transitionHttpAuth:)];
    [sm sendAction:@selector(transitionGetHttpLogin:)];
    // XCTAssertEqualObjects(@"HttpAuth", sm.currentState.name, @"foo", nil);
}


-(void)transitionGetHttpLogin:(MROTransition *)t
{
    ;
}


-(void)transitionGetHttpsLogin:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


-(void)transitionPostHttpLogin:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


-(void)transitionPostHttpsLogin:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


#pragma mark - Few states, additional state 'scheme'

-(void)testUpdateEndpointFSMTerse
{
    MROStateMachine *sm = [[MROStateMachine alloc] initWithTarget:self name:@"Connect Endpoint"];
    [sm addTransitionFrom:@"GetLogin" to:@"error"];
    [sm addTransitionFrom:@"GetLogin" to:@"HttpAuth" guard:[NSPredicate predicateWithFormat:@"YES = authMissing"]];
    [sm addTransitionAction:@selector(transitionDowngradeHttps:) from:@"GetLogin" to:@"GetLogin" guard:[NSPredicate predicateWithFormat:@"NO = authMissing AND scheme = 'https'"]];
    [sm addTransitionFrom:@"GetLogin" to:@"PostLogin" guard:[NSPredicate predicateWithFormat:@"NO = authMissing"]];
    [sm addTransitionFrom:@"HttpAuth" to:@"error"];
    [sm addTransitionFrom:@"HttpAuth" to:@"GetLogin"];
    [sm addTransitionFrom:@"PostLogin" to:@"error"];
    [sm addTransitionFrom:@"PostLogin" to:@"success"].toState.didEnter =^(MROTransition *a, id b) {
        MRLogD (@"%@", b, nil);
    };
    [sm buildMachineWithStartState:@"GetLogin" error:nil];
    MRLogD (@"%@", [sm descriptionDot], nil);

    XCTAssertEqualObjects (@"GetLogin", sm.currentState.name, @"foo", nil);
    self.scheme = HTTP_HTTPS;
    self.authMissing = YES;
    [sm sendAction:@selector(transitionHttpAuth:)];
    [sm sendAction:@selector(transitionGetLogin:)];
    [sm sendAction:@selector(transitionHttpAuth:)];
    [sm sendAction:@selector(transitionGetLogin:)];
    [sm sendAction:@selector(transitionPostLogin:)];
    [sm sendAction:@selector(transitionSuccess:)];
    // XCTAssertEqualObjects(@"HttpAuth", sm.currentState.name, @"foo", nil);
}

-(void)transitionDowngradeHttps:(MROTransition *)t
{
    self.scheme = HTTP_HTTP;
}


-(void)transitionError:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


-(void)transitionGetLogin:(MROTransition *)t
{}


-(void)transitionHttpAuth:(MROTransition *)t
{
    if( [HTTP_HTTPS isEqualToString:self.scheme] )
        self.scheme = HTTP_HTTP;
    else
        self.authMissing = NO;
}


-(void)transitionPostLogin:(MROTransition *)t
{
    ;
}


-(void)transitionSuccess:(MROTransition *)t
{
    ;
}


#pragma mark - Few states

-(void)testStatesPost
{
    MROStateMachine *sm = [[MROStateMachine alloc] initWithTarget:self name:@"Post Link"];
    [sm addTransitionFrom:@"GetLogin" to:@"PostLogin" guard:[NSPredicate predicateWithFormat:@"NO = authMissing", nil]];
    [sm addTransitionFrom:@"GetLogin" to:@"HttpAuth" guard:[NSPredicate predicateWithFormat:@"YES = authMissing", nil]];
    [sm addTransitionFrom:@"GetLogin" to:@"error"];
    [sm addTransitionFrom:@"HttpAuth" to:@"error"];
    [sm addTransitionFrom:@"PostLogin" to:@"*PostLink"];
    [sm addTransitionFrom:@"PostLogin" to:@"error"];
    [sm addTransitionFrom:@"*PostLink" to:@"success"];
    [sm addTransitionFrom:@"*PostLink" to:@"error"];
    [sm addTransitionFrom:@"HttpAuth" to:@"GetLogin"];
    [sm buildMachineWithStartState:@"GetLogin" error:nil];
    MRLogD(@"%@", [sm descriptionDot], nil);
}


-(void)transitionPostLink:(MROTransition *)t
{
    NSAssert(NO, @"Not implemented yet.", nil);
}


#pragma mark -

-(void)testExample
{
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}


-(void)testPerformanceExample
{
    // This is an example of a performance test case.
    [self measureBlock:^{
         // Put the code you want to measure the time of here.
     }
    ];
}


@end
