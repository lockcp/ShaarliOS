//
// KeyValueObserver.m
// Lab Color Space Explorer
//
// Created by Daniel Eggert on 01/12/2013.
// Copyright (c) 2013 objc.io. All rights reserved.
// https://github.com/objcio/issue-7-lab-color-space-explorer/blob/9551c8b6f67dd46eca91d93c0437d10ff9ee4eed/Lab%20Color%20Space%20Explorer/KeyValueObserver.m
//

#import "SOKeyValueObserver.h"

//
// Created by chris on 7/24/13.
//

#import "SOKeyValueObserver.h"

@interface SOKeyValueObserver()
/** weak is no good, because falls to nil WHILE being cleaned up, so dealloc gets a nil ref and leaves a dangling observer.
 * See NSAssert in dealloc below. */
@property (nonatomic, unsafe_unretained) id observedObject;
@property (nonatomic, copy) NSString *keyPath;
@end

@implementation SOKeyValueObserver

-(id)initWithObject:(id)object keyPath:(NSString *)keyPath target:(id)target selector:(SEL)selector options:(NSKeyValueObservingOptions)options;
{
    NSParameterAssert(object != nil);
    NSParameterAssert(target != nil);
    NSParameterAssert([target respondsToSelector:selector]);
    self = [super init];
    if( self ) {
        self.target = target;
        self.selector = selector;
        self.observedObject = object;
        self.keyPath = keyPath;
        [object addObserver:self forKeyPath:keyPath options:options context:(__bridge void *)(self)];
    }
    return self;
}

+(NSArray *)observeKeyPaths:(const id <NSFastEnumeration>)keyPaths ofObject:(id)object target:(id)target
{
    NSParameterAssert(target);
    NSParameterAssert(object);
    NSParameterAssert(keyPaths);
    NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:10];
    for( NSString *keyPath in keyPaths ) {
        NSMutableString *selectorName = [NSMutableString stringWithCapacity:keyPath.length + 10];
        [selectorName appendString:@"didChange"];
        for( NSString *part in[keyPath componentsSeparatedByString : @"."] ) {
            [selectorName appendString:[[part substringToIndex:1] uppercaseString]];
            [selectorName appendString:[part substringFromIndex:1]];
        }
        [selectorName appendString:@":"];
        const SEL selector = NSSelectorFromString(selectorName);
        NSAssert([target respondsToSelector:selector], @"target %@ must respond to\n-(void)%@(NSDictionary*)change { NSAssert(NO,@\"Not implemented yet.\", nil); }\n", [target class], selectorName);
        const id token = [self observeObject:object keyPath:keyPath target:target selector:selector];
        [outArray addObject:token];
    }
    return [NSArray arrayWithArray:outArray];
}


+(NSObject *)observeObject:(id)object keyPath:(NSString *)keyPath target:(id)target selector:(SEL)selector __attribute__( (warn_unused_result) );

{
    return [self observeObject:object keyPath:keyPath target:target selector:selector options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld];
}

+(NSObject *)observeObject:(id)object keyPath:(NSString *)keyPath target:(id)target selector:(SEL)selector options:(NSKeyValueObservingOptions)options __attribute__( (warn_unused_result) );

{
    return [[self alloc] initWithObject:object keyPath:keyPath target:target selector:selector options:options];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if( context == (__bridge void *)(self) ) {
        [self didChange:change];
    }
}


-(void)didChange:(NSDictionary *)change;
{
    id strongTarget = self.target;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [strongTarget performSelector:self.selector withObject:change];
#pragma clang diagnostic pop
}

-(void)dealloc
{
    // MRLogD(@"%@", self, nil);
    NSAssert(self.observedObject, @"Sorry, but I can't remove observers from nil.", nil);
    [self.observedObject removeObserver:self forKeyPath:self.keyPath];
}


@end
