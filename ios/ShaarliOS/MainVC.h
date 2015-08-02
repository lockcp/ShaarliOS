//
// ViewController.h
// ShaarliOS
//
// Created by Marcus Rohrmoser on 18.03.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShaarliM.h"

@interface MainVC : UIViewController
    /** Dependency injection */
@property (strong, nonatomic) ShaarliM *shaarli;
@property (assign, nonatomic) BOOL settingsEnabled;
@end
