//
// ShaarliParseStateTest.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 02.08.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XCTestCase+Tools.h"
#import "MROStateMachine.h"

@interface ShaarliParseStateTest : XCTestCase

@end

@implementation ShaarliParseStateTest

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


-(void)testExample
{
    MROStateMachine *sm = [[MROStateMachine alloc] initWithTarget:self name:@"My State Machine"];
    [sm addTransitionFrom:@"foo" to:@"*bar"];
    [sm addTransitionFrom:@"*bar" to:@"foo"];
    NSError *err = nil;
    [sm buildMachineWithStartState:@"*bar" error:&err];

    MRLogD(@"%@", [sm descriptionDot], nil);

    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}


-(void)transitionFoo:(id)par
{
    MRLogD(@"%@", par, nil);
}


-(void)transitionBar:(id)par
{
    MRLogD(@"%@", par, nil);
}


@end
