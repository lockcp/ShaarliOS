//
// StateMachine.h
// ShaarliOS
//
// Created by Marcus Rohrmoser on 31.01.14.
// Copyright (c) 2014-2016 Marcus Rohrmoser http://mro.name/me. All rights reserved.
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

#import <Foundation/Foundation.h>


@class MROTransition;

/** Mostly opaque type for a state.
 */
@interface MROState : NSObject
@property (nonatomic, readonly, strong) NSString *name;

/** Callback fired ''AFTER'' entering this state. */
@property (nonatomic, copy) void (^didEnter)(MROTransition *, id context);

/** Callback fired ''BEFORE'' leaving this state. */
@property (nonatomic, copy) void (^willLeave)(MROTransition *, id context);
@end


@class MROStateMachine;

/** Mostly opaque type for a state transion.
 */
@interface MROTransition : NSObject
@property (nonatomic, readonly, weak) MROState *fromState;
@property (nonatomic, readonly, weak) MROState *toState;
@property (nonatomic, readonly, weak) MROStateMachine *fsm;

@property (nonatomic, readonly, strong) NSPredicate *guard;

-(NSString *)descriptionDot;
@end


/** Simple [state machine](https://en.wikipedia.org/wiki/State_machine) helper class.
 *
 * Focus is easy setup and self-documentation (i.e. creates [graphivz](http://graphivz.org/) description) - so
 * e.g.
 * - states have to be strings,
 * - transitions have to be selectors (so graphviz has something to print) and
 * - guards are NSPredicates.
 *
 * Blocks, however, can be used for MROState::didEnter and MROState::willLeave. But to avoid confusion,
 * those **must not be re-assigned** once set. This is enforced by `NSAssert`s.
 *
 * @section mrostate_tasks Tasks
 *
 * @subsection mrostate_tasks_setup Setup
 *
 *     MROStateMachine* sm = [[MROStateMachine alloc] initWithTarget:self name:@"My State Machine"];
 *     [sm addTransitionFrom:@"foo" to:@"*bar"];
 *     [sm addTransitionFrom:@"*bar" to:@"foo"];
 *     [sm buildMachineWithStartState:@"*bar" error:nil];
 *
 * @see MROStateMachine::initWithName:target:
 * @see MROStateMachine::addTransitionFrom:to:
 * @see MROStateMachine::buildMachineWithStartState:error:
 *
 * @subsection mrostate_tasks_use Usage
 *
 *     [sm sendAction:@selector(transitionFoo:)];
 *
 * @see MROStateMachine::sendAction:
 *
 * @subsection mrostate_tasks_dot Graphviz
 *
 *     [sm descriptionDot];
 *
 * @see MROStateMachine::descriptionDot
 *
 * yields such a chart:
 *
 * @dot
 * digraph "My State Machine" {
 * label="My State Machine";
 * labelloc="t";
 * rankdir="LR";
 * node [shape = none];
 *   start;
 * node [shape = doublecircle];
 *   "bar";
 * node [shape = circle];
 *   "start" -> "bar";
 *   "bar" -> "foo" [label="transitionFoo:"];
 *   "foo" -> "bar" [label="transitionBar:"];
 * }
 * @enddot
 *
 * @section mrostate_similar Similar
 *
 * on [stackoverflow](http://stackoverflow.com/questions/1110572/finite-state-machine-in-objective-c) or
 * [github](https://github.com/search?l=Objective-C&o=desc&q=state+machine&s=stars&source=c&type=Repositories):
 *
 * - https://github.com/luisobo/StateMachine
 * - https://github.com/est1908/SimpleStateMachine
 * - https://github.com/blakewatters/TransitionKit
 * - https://github.com/mmower/statec
 */
@interface MROStateMachine : NSObject

/** Convenience for MROStateMachine::initWithTarget:name: */
-(instancetype)initWithTarget:(id)target;

/** Constructor.
 *
 * @param target object to provide the action methods.
 * @param name name of the state machine (documentation only). Defaults to `[target class]` if `nil`.
 */
-(instancetype)initWithTarget:(id)target name:(NSString *)name;

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, assign) id target;

/** Convenience wrapper for MROStateMachine::addTransitionFrom:to:guard: with guard `nil`. */
-(MROTransition *)addTransitionFrom:(NSString *)from to:(NSString *)to;

/** Convenience wrapper for MROStateMachine::addTransitionAction:from:to:guard: with action `nil`. */
-(MROTransition *)addTransitionFrom:(NSString *)from to:(NSString *)to guard:(NSPredicate *)guard;

/** Add a transition.
 *
 * @param action selector with single parameter MROTransition. Default (if `nil`): `transition<ToStateName>:(MROTransition*)t`
 * @param from state name, prefix `*` marks an accepting state.
 * @param to state name, prefix `*` marks an accepting state.
 * @param guard optional NSPredicate.
 */
-(MROTransition *)addTransitionAction:(SEL)action from:(NSString *)from to:(NSString *)to guard:(NSPredicate *)guard;

-(BOOL)buildMachineWithStartState:(NSString *)startState error:(NSError **)error;

@property (nonatomic, readonly, strong) MROState *currentState;
-(MROState *)stateByName:(NSString *)name;
-(BOOL)isCurrentStateName:(NSString *)name;

/** Convenience wrapper for MROStateMachine::sendAction:context: with context `nil`. */
-(MROTransition *)sendAction:(SEL)action;

/** Send the given action.
 * - iterates all MROTransition matching the action on the current state,
 * - checks the MROTransition::guard conditions until a match,
 * - fires MROState::willLeave on MROStateMachine::currentState,
 * - changes MROStateMachine::currentState,
 * - performs `action`,
 * - fires MROState::didEnter,
 */
-(MROTransition *)sendAction:(SEL)action context:(id)context;

/** [graphviz](http://graphviz.org/) chart of the state machine.
 */
-(NSString *)descriptionDot;
@end
