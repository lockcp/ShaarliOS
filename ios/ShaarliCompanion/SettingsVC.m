//
// SettingsVC.m
// ShaarliCompanion
//
// Created by Marcus Rohrmoser on 23.07.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "SettingsVC.h"
#import "MainVC.h"

@interface SettingsVC() <UINavigationControllerDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *endpoint;
@property (weak, nonatomic) IBOutlet UISwitch *secure;
@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UITextField *passWord;
@end

@implementation SettingsVC


-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma UIViewController


-(void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSParameterAssert(self.endpoint);
    NSParameterAssert(self.secure);
    NSParameterAssert(self.userName);
    NSParameterAssert(self.passWord);
}


-(void)viewWillAppear:(BOOL)animated
{
    MRLogD(@"", nil);
    [super viewWillAppear:animated];
    NSParameterAssert(self.shaarli);
    self.endpoint.text = self.shaarli.endpointStr;
    self.secure.on = self.shaarli.endpointSecure;
    self.userName.text = self.shaarli.userName;
    self.passWord.text = self.shaarli.passWord;
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.delegate = self;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    MRLogD(@"%@: %@ -> %@", segue, segue.sourceViewController, segue.destinationViewController, nil);
}


#pragma UINavigationControllerDelegate


/**
 * http://stackoverflow.com/a/14256348
 * http://stackoverflow.com/questions/23171906/uinavigationbar-intercept-back-button-and-back-swipe-gesture
 * http://stackoverflow.com/questions/8564924/confirm-back-button-on-uinavigationcontroller
 */
-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(MainVC *)viewController animated:(BOOL)animated
{
    MRLogD(@"%@", viewController, nil);
    navigationController.delegate = nil;
    if( [self.endpoint.text isEqualToString:self.shaarli.endpointStr] && self.secure.on == self.shaarli.endpointSecure && [self.userName.text isEqualToString:self.shaarli.userName] && [self.passWord.text isEqualToString:self.shaarli.passWord] ) {
        return;
    }

    viewController.settingsEnabled = NO;
    [self.shaarli updateEndpoint:self.endpoint.text secure:self.secure.on user:self.userName.text pass:self.passWord.text completion:^(ShaarliM * me, NSError * error) {
         MRLogD (@"", nil);
         viewController.settingsEnabled = YES;
         if( error ) {
             UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString (@"Connection failed", @"SettingsVC") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
             [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString (@"Cancel", @"SettingsVC") style:UIAlertActionStyleCancel handler:nil]];
             [viewController presentViewController:alert animated:animated completion:nil];
         }
     }
    ];
}


#pragma UITextFieldDelegate


/** called when 'return' key pressed. return NO to ignore. */
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    MRLogD(@"%@", textField.text, nil);
    if( textField == self.endpoint )
        [self.userName becomeFirstResponder];
    else if( textField == self.userName )
        [self.passWord becomeFirstResponder];
    else if( textField == self.passWord )
        [self.navigationController popViewControllerAnimated:YES];
    return YES;
}


@end
