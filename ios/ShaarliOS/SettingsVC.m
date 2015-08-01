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
@property (weak, nonatomic) IBOutlet UITextField *endpoint;
@property (weak, nonatomic) IBOutlet UISwitch *secure;
@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UITextField *passWord;
@end

@implementation SettingsVC


#pragma UIViewController


-(void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSParameterAssert(self.endpoint);
    NSParameterAssert(self.secure);
    NSParameterAssert(self.userName);
    NSParameterAssert(self.passWord);
    NSParameterAssert(self.lblTitle);
    NSParameterAssert(self.spinner);
    [self.tableView addSubview:self.spinner];
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

    self.lblTitle.text = self.shaarli.title;
    self.lblTitle.textColor = self.lblTitle.text ? self.userName.textColor : [UIColor redColor];
    self.lblTitle.text = self.lblTitle.text ? self.lblTitle.text : NSLocalizedString(@"Not connected yət.", @"SettingsVC.m");

    [self.spinner stopAnimating];

    self.title = NSLocalizedString(@"Settings", @"SettingsVC");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionCancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionSignIn:)];
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
    self.spinner.frame = self.tableView.bounds;
    [self.spinner startAnimating];
    [self.shaarli updateEndpoint:self.endpoint.text secure:self.secure.on user:self.userName.text pass:self.passWord.text completion:^(ShaarliM * me, NSError * error) {
         dispatch_async (dispatch_get_main_queue (), ^{
                             MRLogD (@"-", nil);
                             [self.spinner stopAnimating];
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
