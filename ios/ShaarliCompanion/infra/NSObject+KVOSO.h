//
// NSObject+KVOSO.h
//
// Created by Marcus Rohrmoser on 07.02.14.
// Copyright (c) 2014 Marcus Rohrmoser mobile Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/** https://github.com/objcio/issue-7-lab-color-space-explorer/blob/master/Lab%20Color%20Space%20Explorer/KeyValueObserver.m
 */
@interface NSObject(KVOSO)
-(NSArray *)observerTokensForKeypaths:(id <NSFastEnumeration>)keyPaths ofObject:(id)object;
@end
