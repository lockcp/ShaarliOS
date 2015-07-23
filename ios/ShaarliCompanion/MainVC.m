//
// ViewController.m
// ShaarliCompanion
//
// Created by Marcus Rohrmoser on 18.03.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "MainVC.h"
#import "SettingsVC.h"

@interface MainVC()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsBtn;
@end

@implementation MainVC

-(void)viewDidLoad
{
    MRLogD(@"", nil);
    [super viewDidLoad];
    NSParameterAssert(self.settingsBtn);
}


-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


-(BOOL)settingsEnabled
{
    return self.settingsBtn.enabled;
}


-(void)setSettingsEnabled:(BOOL)value
{
    self.settingsBtn.enabled = value;
}


+(NSSet *)keyPathsForValuesAffectingSettingsEnabled
{
    return [NSSet setWithObject:@"settingsBtn.enabled"];
}


-(void)viewWillAppear:(BOOL)animated
{
    MRLogD(@"", nil);
    NSParameterAssert(self.shaarli);
    [super viewWillAppear:animated];
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
