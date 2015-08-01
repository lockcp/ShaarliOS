//
// ViewController.m
// ShaarliCompanion
//
// Created by Marcus Rohrmoser on 18.03.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "MainVC.h"
#import "SettingsVC.h"
#import "NSBundle+MroSemVer.h"

@implementation NSLayoutConstraint(ChangeMultiplier)

// visal form center http://stackoverflow.com/a/13148012/349514
-(NSLayoutConstraint *)constraintWithMultiplier:(CGFloat)multiplier
{
    return [NSLayoutConstraint constraintWithItem:self.firstItem attribute:self.firstAttribute relatedBy:self.relation toItem:self.secondItem attribute:self.secondAttribute multiplier:multiplier constant:self.constant];
}


@end

@interface MainVC()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerY;
@property (weak, nonatomic) IBOutlet UILabel *lblVersion;
@property (weak, nonatomic) IBOutlet UIView *vContainer;
@end

@implementation MainVC

-(void)viewDidLoad
{
    MRLogD(@"", nil);
    [super viewDidLoad];
    NSParameterAssert(self.vContainer);
    NSParameterAssert(self.centerY);
}


-(void)viewWillAppear:(BOOL)animated
{
    MRLogD(@"-", nil);
    NSParameterAssert(self.shaarli);
    [super viewWillAppear:animated];
    self.title = self.shaarli.title;
    self.lblVersion.text = [NSBundle semVer];
    self.lblVersion.alpha = 0;
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // animate logo to bottom
    [UIView animateWithDuration:0.5f animations:^{
         self.vContainer.alpha = 0.25;
         self.lblVersion.alpha = 1.0;

         NSLayoutConstraint *c = [self.centerY constraintWithMultiplier:0.75];
         [self.view removeConstraint:self.centerY];
         [self.view addConstraint:self.centerY = c];
         [self.view layoutIfNeeded];
     }
    ];

    if( !self.shaarli.isSetUp )
        [self performSegueWithIdentifier:NSStringFromClass([SettingsVC class]) sender:self];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    MRLogD(@"%@: %@ -> %@", segue, segue.sourceViewController, segue.destinationViewController, nil);
    if( [segue.destinationViewController isKindOfClass:[SettingsVC class]] ) {
        SettingsVC *svc = (SettingsVC *)segue.destinationViewController;
        svc.shaarli = self.shaarli;
        return;
    }
    NSAssert(NO, @"Fallthrough", nil);
}


@end
