//
// StateMachine.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 31.01.14.
// Copyright (c) 2014 Marcus Rohrmoser mobile Software. All rights reserved.
//

#import "MROStateMachine.h"

/** @todo escape names for graphviz.
 */
static inline NSString *esc2dot(NSString *s)
{
    return s;
}


@class MROStateMachine;

@interface MROState()
@property (nonatomic, readonly, assign) BOOL accepting;
@property (nonatomic, readonly, strong) NSMutableDictionary *actionNamesToTransitionNums;
@property (nonatomic, readwrite, weak) MROStateMachine *fsm;
@property (nonatomic, readwrite, assign) NSInteger num;
@end

@implementation MROState : NSObject

+(NSString *)stateNameForTmp:(NSString *)tmp isAccepting:(BOOL *)ptr
{
    const BOOL accepting = [tmp hasPrefix:@"*"];
    if( ptr )
        *ptr = accepting;
    return accepting ? [tmp substringFromIndex:1] : tmp;
}


+(SEL)defaultToActionForStateName:(NSString *)tmp
{
    tmp = [self stateNameForTmp:tmp isAccepting:NULL];
    NSString *sel = [NSString stringWithFormat:@"transition%@%@:", [[tmp substringToIndex:1] uppercaseString], [tmp substringFromIndex:1], nil];
    return NSSelectorFromString(sel);
}


-(instancetype)initWithTmpName:(NSString *)name
{
    if( self = [super init] ) {
        _name = [[self class] stateNameForTmp:name isAccepting:&_accepting];
        _actionNamesToTransitionNums = [NSMutableDictionary dictionaryWithCapacity:2];
    }
    return self;
}


-(void)setDidEnter:( void (^)(MROTransition *, id) )value
{
    NSAssert(_didEnter == NULL, @"Overwriting not allowed.", nil);
    _didEnter = value;
}


-(void)setWillLeave:( void (^)(MROTransition *, id) )value
{
    NSAssert(_willLeave == NULL, @"Overwriting not allowed.", nil);
    _willLeave = value;
}


-(NSString *)descriptionDot
{
    NSMutableString *ret = [[NSMutableString alloc] initWithCapacity:100];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-non-iso"
    [ret appendFormat:@"\"%1$@\" [label=\"%1$@", esc2dot(self.name), nil];
#pragma clang diagnostic pop
    if( self.didEnter )
        [ret appendString:@"\\n^didEnter()"];
    if( self.willLeave )
        [ret appendString:@"\\n^willLeave()"];
    [ret appendString:@"\"];"];
    return [NSString stringWithString:ret];
}


@end

@interface MROTransition()
@property (nonatomic, readwrite, strong) NSString *fromTmp;
@property (nonatomic, readwrite, strong) NSString *toTmp;

@property (nonatomic, readwrite, strong) NSPredicate *guard;

@property (nonatomic, readwrite, weak) MROStateMachine *fsm;

@property (nonatomic, readwrite, assign) NSInteger fromNum;
@property (nonatomic, readwrite, assign) NSInteger toNum;

@property (nonatomic, readwrite, assign) SEL action;
@end

@interface MROStateMachine()
@property (nonatomic, readonly, assign) BOOL isBuilt;
@property (nonatomic, readwrite, strong) NSMutableArray *tempTransitions;

@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readonly, strong) NSMutableArray *states;
@property (nonatomic, readonly, strong) NSMutableDictionary *statesNum;
@property (nonatomic, readwrite, strong) NSArray *transitions;
@property (nonatomic, readonly, strong) NSMutableSet *missingSelectors;

@property (nonatomic, readwrite, assign) NSInteger currentStateInteger;
@property (nonatomic, readwrite, assign) NSInteger startStateInteger;
@end


@implementation MROTransition : NSObject
-(instancetype)init
{
    if( self = [super init] ) {
        self.fromNum = self.toNum = -1;
    }
    return self;
}


-(MROState *)fromState
{
    return self.fsm.states[self.fromNum];
}


-(MROState *)toState
{
    return self.fsm.states[self.toNum];
}


-(NSString *)description
{
    return [NSString stringWithFormat:@"<Transition:%@>", self.descriptionDot, nil];
}


-(NSString *)descriptionDot
{
    NSMutableString *ret = [[NSMutableString alloc] initWithCapacity:100];
    [ret appendFormat:@"\"%@\" -> \"%@\" [label=\"%@", esc2dot(self.fromState.name), esc2dot(self.toState.name), esc2dot( NSStringFromSelector(self.action) ), nil];
    if( self.guard )
        [ret appendFormat:@"\\n[ %@ ]", self.guard, nil];
    [ret appendString:@"\"];"];
    return [NSString stringWithString:ret];
}


@end


@implementation MROStateMachine

-(instancetype)init
{
    NSParameterAssert(NO);
    return nil;
}


-(instancetype)initWithTarget:(id)target
{
    NSParameterAssert(target);
    return [self initWithTarget:target name:nil];
}


-(instancetype)initWithTarget:(id)target name:(NSString *)name
{
    if( self = [super init] ) {
        _target = target;
        _name = name ? name : NSStringFromClass([target class]);
        self.tempTransitions = [NSMutableArray arrayWithCapacity:100];
        _statesNum = [NSMutableDictionary dictionaryWithCapacity:10];
        _states = [NSMutableArray arrayWithCapacity:10];
        _missingSelectors = [NSMutableSet setWithCapacity:10];
    }
    return self;
}


-(BOOL)isBuilt
{
    return self.tempTransitions == nil;
}


-(MROTransition *)addTransitionFrom:(NSString *)from to:(NSString *)to
{
    return [self addTransitionFrom:from to:to guard:NULL];
}


-(MROTransition *)addTransitionFrom:(NSString *)from to:(NSString *)to guard:(NSPredicate *)guard
{
    return [self addTransitionAction:nil from:from to:to guard:guard];
}


-(MROTransition *)addTransitionAction:(SEL)action from:(NSString *)from to:(NSString *)to guard:(NSPredicate *)guard
{
    NSParameterAssert(!self.isBuilt);
    // check action - fail eagerly
    if( !action )
        action = [MROState defaultToActionForStateName:to];
    if( ![self.target respondsToSelector:action] )
        [self.missingSelectors addObject:[NSString stringWithFormat:@"-(void)%@(%@ *)t { NSAssert(NO, @\"Not implemented yet.\", nil); }", NSStringFromSelector(action), [MROTransition class]]];
    MROTransition *t = [[MROTransition alloc] init];
    t.action = action;
    t.fromTmp = from;
    t.toTmp = to;
    t.guard = guard;
    t.fsm = self;
    {
        // 'from' state
        MROState *fromState = [self lookupOrCreateState:t.fromTmp];
        NSAssert(fromState, @"Ouch", nil);
        t.fromTmp = nil;
        t.fromNum = fromState.num;

        NSString *actionName = NSStringFromSelector(t.action);
        NSMutableArray *tr = fromState.actionNamesToTransitionNums[actionName];
        if( tr == nil )
            fromState.actionNamesToTransitionNums[actionName] = tr = [NSMutableArray arrayWithCapacity:1];
        [tr addObject:@ (self.tempTransitions.count)];
    }
    {
        // 'to' state
        MROState *toState = [self lookupOrCreateState:t.toTmp];
        NSAssert(toState, @"Ouch", nil);
        t.toTmp = nil;
        t.toNum = toState.num;
    }
    [self.tempTransitions addObject:t];
    // MRLogD(@"%@", t, nil);
    return t;
}


-(MROState *)lookupOrCreateState:(NSString *)tmpName
{
    NSParameterAssert(!self.isBuilt);
    MROState *ret = [self stateByName:tmpName];
    if( ret )
        return ret;
    ret = [[MROState alloc] initWithTmpName:tmpName];
    // MRLogD(@"%@", ret.name, nil);
    ret.fsm = self;
    ret.num = self.states.count;
    [self.states addObject:ret];
    self.statesNum[ret.name] = @ (ret.num);
    NSAssert(self.states.count == self.statesNum.count, @"Ouch", nil);
    NSAssert(ret == self.states[ret.num], @"Ouch", nil);
    NSAssert([self.statesNum[ret.name] integerValue] == ret.num, @"Ouch", nil);
    return ret;
}


/** Finalize transition LUT.
 *
 * @todo check and warn about obsolete selectors (transitionXXX:)
 */
-(BOOL)buildMachineWithStartState:(NSString *)initialState error:(NSError **)error
{
    NSParameterAssert(!self.isBuilt);
    NSAssert(self.missingSelectors.count == 0, @"Selectors missing: \n%@\n", [[self.missingSelectors.allObjects sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@"\n"], nil);
    _missingSelectors = nil;
    // @todo obsolete transitionXXX: selectors on target.
    self.transitions = [NSArray arrayWithArray:self.tempTransitions];
    self.tempTransitions = nil;
    self.currentStateInteger = self.startStateInteger = [self stateByName:initialState].num;
    return YES;
}


-(MROState *)startState
{
    NSParameterAssert(self.isBuilt);
    return self.states[self.startStateInteger];
}


+(NSSet *)keyPathsForValuesAffectingCurrentState
{
    return [NSSet setWithObject:@"currentStateInteger"];
}


-(MROState *)currentState
{
    NSParameterAssert(self.isBuilt);
    return self.states[self.currentStateInteger];
}


/** Fire **No** callbacks. */
-(void)setCurrentState:(MROState *)currentState
{
    NSParameterAssert(self.isBuilt);
    if( currentState == nil )
        currentState = self.startState;
    self.currentStateInteger = currentState.num;
}


-(MROState *)stateByName:(NSString *)tmpName
{
    // NSAssert(self.isBuilt, @"foo", nil);
    NSString *name = [MROState stateNameForTmp:tmpName isAccepting:nil];
    NSNumber *num = self.statesNum[name];
    NSParameterAssert(!self.isBuilt || num != nil);
    if( !num )
        return nil;
    const NSInteger idx = [num integerValue];
    MROState *ret = (idx < 0 || idx >= self.states.count) ? nil : self.states[idx];
    NSParameterAssert(ret);
    return ret;
}


-(BOOL)isCurrentStateName:(NSString *)name
{
    return [self.currentState isEqual:[self stateByName:name]];
}


/** Convenience wrapper. @see MROStateMachine::sendAction:context: */
-(MROTransition *)sendAction:(SEL)action
{
    return [self sendAction:action context:nil];
}


-(MROTransition *)sendAction:(SEL)action context:(id)context
{
    NSParameterAssert(self.isBuilt);
    NSString *actionName = NSStringFromSelector(action);
    for( NSNumber *num in self.currentState.actionNamesToTransitionNums[actionName] ) {
        const NSInteger tnum = [num integerValue];
        NSParameterAssert(num);
        NSParameterAssert(tnum >= 0);
        NSParameterAssert(tnum < self.transitions.count);
        MROTransition *t = self.transitions[tnum];
        NSParameterAssert([NSStringFromSelector (t.action) isEqualToString:actionName]);
        if( t.guard && ![t.guard evaluateWithObject:self.target] ) {
            MRLogD(@"guard missed: %@", t, nil);
            continue;
        }
        MRLogD(@"hit %@", t, nil);
        if( self.currentState.willLeave )
            self.currentState.willLeave(t, context);
        self.currentState = t.toState;
        if( self.currentState.didEnter )
            self.currentState.didEnter(t, context);
        if( self.target && t.action ) {
            // http://stackoverflow.com/a/7933931
#pragma clang diagnostic push
                   #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self.target performSelector:t.action withObject:t];
#pragma clang diagnostic pop
        }
        return t;
    }
    NSAssert(NO, @"No such action: \"%@\" -> \"%@\" [label=\"%@\"]", self.currentState.name, @"?", actionName, nil);
    return nil; // keep compiler happy.
}


-(NSString *)descriptionDot
{
    NSParameterAssert(self.isBuilt);
    NSMutableString *ret = [NSMutableString stringWithCapacity:1000];
    [ret appendFormat:@"digraph \"%@\" {\n", esc2dot(self.name), nil];
    [ret appendFormat:@"label=\"%@\";\n", esc2dot(self.name), nil];
    [ret appendString:@"labelloc=\"t\";\n"];
    [ret appendString:@"rankdir=\"LR\";\n"];
    [ret appendString:@"node [shape = none];\n"];
    [ret appendFormat:@"  \"%@\";\n", esc2dot(@"start"), nil];
    [ret appendString:@"node [shape = doublecircle];\n"];
    for( MROState *s in self.states ) {
        if( s.accepting )
            [ret appendFormat:@"  %@\n", [s descriptionDot], nil];
    }
    [ret appendString:@"node [shape = circle];\n"];
    for( MROState *s in self.states ) {
        if( !s.accepting )
            [ret appendFormat:@"  %@\n", [s descriptionDot], nil];
    }
    [ret appendFormat:@"  \"%@\" -> \"%@\";\n", esc2dot(@"start"), esc2dot(self.startState.name), nil];
    for( MROTransition *t in self.transitions )
        [ret appendFormat:@"  %@\n", t.descriptionDot, nil];
    [ret appendString:@"}\n"];
    return [NSString stringWithString:ret];
}


@end
