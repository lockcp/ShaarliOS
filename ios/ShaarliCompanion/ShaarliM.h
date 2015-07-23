//
// ShaarliM.h
// ShaarliCompanion
//
// Created by Marcus Rohrmoser on 17.07.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShaarliM : NSObject
@property (readonly, strong, nonatomic) NSURL *endpointUrl;
@property (readonly, strong, nonatomic) NSString *endpointStr;
@property (readonly, assign, nonatomic) BOOL endpointSecure;
@property (readonly, strong, nonatomic) NSString *userName;
@property (readonly, strong, nonatomic) NSString *passWord;

@property (readonly, strong, nonatomic) NSString *title;
@property (readonly, assign, nonatomic) BOOL isLoggedIn;


-(void)load;
-(void)save;
-(void)updateEndpoint:(NSString *)endpoint secure:(BOOL)secure user:(NSString *)user pass:(NSString *)pass completion:( void (^)(ShaarliM * me, NSError * error) )completion;

-(void)postURL:(NSURL *)url title:(NSString *)title tags:(id <NSFastEnumeration>)tags description:(NSString *)desc private:
   (BOOL)privat completion:( void (^)(ShaarliM * me, NSError * error) )completion;
-(void)fetchTagCloud:( void (^)(ShaarliM * me, NSError * error) )completion;


-(void)login:( void (^)(ShaarliM * me, NSError * error) )completionHandler;
-(BOOL)logout:(NSError **)err;
-(BOOL)refresh:(NSError **)err;


@end
