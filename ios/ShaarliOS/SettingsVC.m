//
// SettingsVC.m
// ShaarliCompanion
//
// Created by Marcus Rohrmoser on 23.07.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "SettingsVC.h"
#import "MainVC.h"

@interface SettingsVC() <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txtEndpoint;
@property (weak, nonatomic) IBOutlet UISwitch *swiSecure;
@property (weak, nonatomic) IBOutlet UITextField *txtUserName;
@property (weak, nonatomic) IBOutlet UITextField *txtPassWord;
@property (weak, nonatomic) IBOutlet UILabel *lblDefaultPrivate;
@property (weak, nonatomic) IBOutlet UISwitch *swiPrivateDefault;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spiLogin;
@end

@implementation SettingsVC


#pragma UIViewController


-(void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSParameterAssert(self.lblTitle);
    NSParameterAssert(self.txtEndpoint);
    NSParameterAssert(self.swiSecure);
    NSParameterAssert(self.txtUserName);
    NSParameterAssert(self.txtPassWord);
    NSParameterAssert(self.swiPrivateDefault);
    NSParameterAssert(self.lblDefaultPrivate);
    NSParameterAssert(self.spiLogin);
    [self.tableView addSubview:self.spiLogin];
}


-(void)viewWillAppear:(BOOL)animated
{
    MRLogD(@"", nil);
    [super viewWillAppear:animated];
    NSParameterAssert(self.shaarli);

    self.lblTitle.text = self.shaarli.title;
    self.lblTitle.textColor = self.lblTitle.text ? self.txtUserName.textColor : [UIColor redColor];
    self.lblTitle.text = self.lblTitle.text ? self.lblTitle.text : NSLocalizedString(@"Not connected yət.", @"SettingsVC.m");

    self.txtEndpoint.text = self.shaarli.endpointStr;
    self.swiSecure.on = self.shaarli.endpointSecure;
    self.txtUserName.text = self.shaarli.userName;
    self.txtPassWord.text = self.shaarli.passWord;
    self.swiPrivateDefault.on = self.shaarli.privateDefault;

    [self.spiLogin stopAnimating];

    self.title = NSLocalizedString(@"Settings", @"SettingsVC");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionCancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionSignIn:)];
}


#pragma UITextFieldDelegate


/** called when 'return' key pressed. return NO to ignore. */
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    MRLogD(@"%@", textField.text, nil);
    if( textField == self.txtEndpoint )
        [self.txtUserName becomeFirstResponder];
    else if( textField == self.txtUserName )
        [self.txtPassWord becomeFirstResponder];
    else if( textField == self.txtPassWord )
        [self actionSignIn:textField];  // dispatch async?
    return YES;
}


#pragma mark Actions


-(IBAction)actionCancel:(id)sender
{
    MRLogD(@"-", nil);
    [self.navigationController popViewControllerAnimated:YES];
}


-(IBAction)actionSignIn:(id)sender
{
    MRLogD(@"-", nil);
    const BOOL wasSetUp = self.shaarli.isSetUp;

    // spinner purposely covers all screen, so all other buttons are blocked meanwhile.
    self.spiLogin.frame = self.tableView.bounds;
    [self.spiLogin startAnimating];
    [self.shaarli updateEndpoint:self.txtEndpoint.text secure:self.swiSecure.on user:self.txtUserName.text pass:self.txtPassWord.text privateDefault:self.swiPrivateDefault.on completion:^(ShaarliM * me, NSError * error) {
         dispatch_async (dispatch_get_main_queue (), ^{
                             MRLogD (@"-", nil);
                             [self.spiLogin stopAnimating];
                             if( error ) {
                                 UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString (@"Connection failed", @"SettingsVC") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                                 [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString (@"Cancel", @"SettingsVC") style:UIAlertActionStyleCancel handler:nil]];
                                 [self presentViewController:alert animated:YES completion:nil];
                             } else if( !wasSetUp && self.shaarli.isSetUp ) {
                                 UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString (@"Setup done", @"SettingsVC") message:[NSString stringWithFormat:NSLocalizedString (@"Nice, now you can activate the extension in 'Activities' and post links to %@.", @"SettingsVC"), self.shaarli.title] preferredStyle:UIAlertControllerStyleAlert];
                                 [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString (@"OK", @"SettingsVC") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                       [self.navigationController popViewControllerAnimated:YES];
                                                   }
                                  ]];
                                 [self presentViewController:alert animated:YES completion:nil];
                                 return;
                             }
                             [self.navigationController popViewControllerAnimated:YES];
                         }
                         );
     }
    ];
}


@end
