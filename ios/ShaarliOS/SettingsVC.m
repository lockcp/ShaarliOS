//
// SettingsVC.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 23.07.15.
// Copyright (c) 2015-2016 Marcus Rohrmoser http://mro.name/me. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "SettingsVC.h"
#import "MainVC.h"
#import "OnePasswordExtension.h"
#import "NSBundle+MroSemVer.h"


@interface SettingsVC() <UITextFieldDelegate, UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txtEndpoint;
@property (weak, nonatomic) IBOutlet UISwitch *swiSecure;
@property (weak, nonatomic) IBOutlet UITextField *txtUserName;
@property (weak, nonatomic) IBOutlet UITextField *txtPassWord;
@property (weak, nonatomic) IBOutlet UILabel *lblDefaultPrivate;
@property (weak, nonatomic) IBOutlet UISwitch *swiPrivateDefault;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UISwitch *swiTags;
@property (weak, nonatomic) IBOutlet UITextField *txtTags;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spiLogin;

// https://github.com/AgileBits/onepassword-app-extension#use-case-1-native-app-login
@property (weak, nonatomic) IBOutlet UIButton *btn1Password;

@property (weak, nonatomic) IBOutlet UITableViewCell *cellAbout;
@property (weak, nonatomic) IBOutlet UIWebView *wwwAbout;
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
    NSParameterAssert(self.swiTags);
    NSParameterAssert(self.txtTags);
    NSParameterAssert(self.wwwAbout.scrollView);
    NSParameterAssert(self.cellAbout);
    NSParameterAssert(self.spiLogin);
    [self.tableView addSubview:self.spiLogin];

    self.wwwAbout.scrollView.scrollEnabled = NO;
    self.wwwAbout.scrollView.bounces = NO;
    [self.wwwAbout loadRequest:[NSURLRequest requestWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"about" withExtension:@"html"]]];

    self.btn1Password.enabled = [[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
    self.btn1Password.alpha = self.btn1Password.enabled ? 1.0 : 0.5;
}


-(void)viewWillAppear:(BOOL)animated
{
    MRLogD(@"", nil);
    [super viewWillAppear:animated];
    NSParameterAssert(self.shaarli);

    self.lblTitle.text = self.shaarli.title;
    self.lblTitle.textColor = self.lblTitle.text ? self.txtUserName.textColor : [UIColor redColor];
    self.lblTitle.text = self.lblTitle.text ? self.lblTitle.text : NSLocalizedString(@"Not connected yət.", @"SettingsVC");

    self.txtEndpoint.text = self.shaarli.endpointStr;
    self.swiSecure.on = self.shaarli.endpointSecure;
    self.swiSecure.enabled = NO;
    self.txtUserName.text = self.shaarli.userName;
    self.txtPassWord.text = self.shaarli.passWord;
    self.swiPrivateDefault.on = self.shaarli.privateDefault;
    self.swiTags.on = self.shaarli.tagsActive;
    self.txtTags.text = self.shaarli.tagsDefault;

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
        [self.txtTags becomeFirstResponder];
    else if( textField == self.txtTags )
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

    if( self.swiTags.on ) {
        NSMutableArray *a = [NSMutableArray arrayWithCapacity:10];
        [self.txtTags.text stringByStrippingTags:a];
        self.txtTags.text = [@"#" stringByAppendingString:[a componentsJoinedByString:@" #"]];
    } else
        self.txtTags.text = @"";

    // spinner purposely covers all screen, so all other buttons are blocked meanwhile.
    self.spiLogin.frame = self.tableView.bounds;
    [self.spiLogin startAnimating];
    [self.shaarli updateEndpoint:self.txtEndpoint.text secure:self.swiSecure.on user:self.txtUserName.text pass:self.txtPassWord.text privateDefault:self.swiPrivateDefault.on tagsActive:self.swiTags.on tagsDefault:self.txtTags.text completion:^(ShaarliM * me, NSError * error) {
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


//
-(IBAction)actionFindLoginFrom1Password:(id)sender
{
    // TODO: lookup may have to be tried 2x as the url scheme (http vs. https) isn't known yet.
    [[OnePasswordExtension sharedExtension] findLoginForURLString:self.txtEndpoint.text forViewController:self sender:sender completion:^(NSDictionary * loginDictionary, NSError * error) {
         if( loginDictionary.count == 0 ) {
             if( error.code != AppExtensionErrorCodeCancelledByUser ) {
                 NSLog (@"Error invoking 1Password App Extension for find login: %@", error);
             }
             return;
         }
         self.txtUserName.text = loginDictionary[AppExtensionUsernameKey];
         self.txtPassWord.text = loginDictionary[AppExtensionPasswordKey];
     }
    ];
}



#pragma mark UIWebViewDelegate


-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    MRLogD(@"%.0f", webView.scrollView.contentSize.height, nil);
    // self.cellAbout.
    NSString *ret = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"injectVersion('%@');", [NSBundle semVer]]];
    NSParameterAssert([@"" isEqualToString:ret]);
    MRLogD(@"%@", ret);
}


-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    MRLogD(@"%@", request, nil);
    NSString *scheme = request.URL.scheme;
    if( NSNotFound != [@[@"file"] indexOfObject:scheme] )
        return YES;
    if( [[UIApplication sharedApplication] canOpenURL:request.URL] )
        [[UIApplication sharedApplication] openURL:request.URL];
    return NO;
}


@end
