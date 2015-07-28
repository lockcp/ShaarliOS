//
// NSObject+KVOSO.m
//
// Created by Marcus Rohrmoser on 07.02.14.
// Copyright (c) 2014 Marcus Rohrmoser mobile Software. All rights reserved.
//

#import "NSObject+KVOSO.h"
#import "SOKeyValueObserver.h"

@implementation NSObject(KVOSO)
-(NSArray *)observerTokensForKeypaths:(id <NSFastEnumeration>)keyPaths ofObject:(id)object
{
    return [SOKeyValueObserver observeKeyPaths:keyPaths ofObject:object target:self];
}


@end
