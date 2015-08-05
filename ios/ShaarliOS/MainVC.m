//
// ViewController.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 18.03.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "MainVC.h"
#import "SettingsVC.h"
#import "NSBundle+MroSemVer.h"
#import "ShareVC.h"

@implementation NSLayoutConstraint(ChangeMultiplier)

// visal form center http://stackoverflow.com/a/13148012/349514
-(NSLayoutConstraint *)constraintWithMultiplier:(CGFloat)multiplier
{
    return [NSLayoutConstraint constraintWithItem:self.firstItem attribute:self.firstAttribute relatedBy:self.relation toItem:self.secondItem attribute:self.secondAttribute multiplier:multiplier constant:self.constant];
}


@end

@interface MainVC() <UITextFieldDelegate, UITextViewDelegate, ShaarliPostDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerY;
@property (weak, nonatomic) IBOutlet UILabel *lblVersion;
@property (weak, nonatomic) IBOutlet UIView *vContainer;
@property (weak, nonatomic) IBOutlet UIButton *btnPetal;

@property (weak, nonatomic) IBOutlet UIView *viewPost;
@property (weak, nonatomic) IBOutlet UIButton *btnShaare;
@property (weak, nonatomic) IBOutlet UILabel *lblShaare;
@property (weak, nonatomic) IBOutlet UITextView *txtDescr;
@property (weak, nonatomic) IBOutlet UITextField *txtTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnAudience;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constrPostHeight;

@end

@implementation MainVC

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if( self = [super initWithCoder:aDecoder] ) {
        // register for Keyboard visibility events
        // https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html#//apple_ref/doc/uid/TP40009542-CH5-SW7
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidAppear:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillAppear:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDisappear:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidDisappear:) name:UIKeyboardDidHideNotification object:nil];
    }
    return self;
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}


#pragma mark UIViewController


-(void)viewDidLoad
{
    MRLogD(@"", nil);
    [super viewDidLoad];
    NSParameterAssert(self.vContainer);
    NSParameterAssert(self.centerY);
    NSParameterAssert(self.btnPetal);

    NSParameterAssert(self.viewPost);
    NSParameterAssert(self.btnShaare);
    NSParameterAssert(self.btnPetal);
    NSParameterAssert(self.lblShaare);
    NSParameterAssert(self.txtDescr);
    NSParameterAssert(self.txtTitle);
    NSParameterAssert(self.btnAudience);

    NSParameterAssert(self.constrPostHeight);
}


-(void)viewWillAppear:(BOOL)animated
{
    MRLogD(@"-", nil);
    NSParameterAssert(self.shaarli);
    [super viewWillAppear:animated];
    self.title = self.shaarli.title;
    self.lblVersion.text = [NSBundle semVer];
    self.lblVersion.alpha = 0;
    self.viewPost.alpha = 0;

    [self actionCancel:nil]; // clear
}


-(void)viewDidAppear:(BOOL)animated
{
    MRLogD(@"-", nil);
    [super viewDidAppear:animated];
    // animate logo to bottom
    [UIView animateWithDuration:0.5f animations:^{
         self.vContainer.alpha = 0.5;
         self.lblVersion.alpha = 1.0;
         self.viewPost.alpha = 1.0;

         NSLayoutConstraint *c = [self.centerY constraintWithMultiplier:0.75];
         [self.view removeConstraint:self.centerY];
         [self.view addConstraint:self.centerY = c];
         [self.view layoutIfNeeded];
     }
    ];

    if( !self.shaarli.isSetUp ) {
        [self performSegueWithIdentifier:NSStringFromClass([SettingsVC class]) sender:self];
        return;
    }
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


#pragma mark Post a Note (via ShareVC)


-(IBAction)actionPetal:(id)sender
{
    MRLogD(@"-", nil);
    NSParameterAssert(NO);
    ShareVC *svc = [[ShareVC alloc] init];
    [self presentViewController:svc animated:YES completion:nil];
}


#pragma mark Post a Note (via viewPost)



-(IBAction)btnAudience:(id)sender
{
    MRLogD(@"-", nil);
    self.btnAudience.selected = !self.btnAudience.selected;
    self.btnAudience.highlighted = NO;
    NSParameterAssert(!self.btnAudience.highlighted);
}


-(IBAction)actionCancel:(id)sender
{
    MRLogD(@"-", nil);
    self.txtDescr.text = self.shaarli.tagsActive ? [NSString stringWithFormat:@"%@ \n", self.shaarli.tagsDefault] : @"";
    self.txtTitle.text = NSLocalizedString(@"A new Note", @"MainVC");
    self.btnAudience.selected = self.shaarli.privateDefault;
    [self.txtDescr resignFirstResponder];
    [self.txtTitle resignFirstResponder];
    self.btnShaare.enabled = YES;
}


-(IBAction)actionPost:(id)sender
{
    MRLogD(@"-", nil);

    NSURLSession *session = [self.shaarli postSession];
    self.btnShaare.enabled = NO;
    [self.shaarli postUrl:nil title:self.txtTitle.text description:self.txtDescr.text session:session delegate:self];
}


#pragma mark UITextViewDelegate


#pragma mark UITextFieldDelegate


/** called when 'return' key pressed. return NO to ignore. */
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    MRLogD(@"%@", textField.text, nil);
    if( textField == self.txtTitle )
        [self actionPost:textField];
    return YES;
}


#pragma mark Keyboard

// http://www.think-in-g.net/ghawk/blog/2012/09/practicing-auto-layout-an-example-of-keyboard-sensitive-layout/
-(void)keyboardWillAppear:(NSNotification *)notification
{
    MRLogD(@"-", nil);
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    const NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSParameterAssert(kbFrame);
    const CGRect keyboardFrame = [kbFrame CGRectValue];

    self.constrPostHeight.constant = keyboardFrame.origin.y - 1;
    [self.view layoutIfNeeded];
    return;
}


/** @todo Animation dynamics bug but at least yields proper frame (for now).
 * Should rather sit on WillAppear but interferes with autolayout.
 */
-(void)keyboardDidAppear:(NSNotification *)notification
{
    MRLogD(@"-", nil);
}


-(void)keyboardWillDisappear:(NSNotification *)notification
{
    MRLogD(@"-", nil);
    self.constrPostHeight.constant = 283;
    [self.view setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
}


/** @todo Animation dynamics bug but at least yields proper frame (for now).
 * Should rather sit on WillDisappear but interferes with autolayout.
 */
-(void)keyboardDidDisappear:(NSNotification *)notification
{
    MRLogD(@"-", nil);
}


#pragma mark ShaarliPostDelegate


-(BOOL)postPrivate
{
    return self.btnAudience.selected;
}


-(void)shaarli:(ShaarliM *)shaarli didFinishPostWithError:(NSError *)error
{
    if( error ) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Shaarlying failed", @"ShareVC") message:[NSString stringWithFormat:NSLocalizedString(@"%@\n\nFailing call was %@", @"ShareVC"), error.localizedDescription, error.userInfo[NSURLErrorKey]] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"ShareVC") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                              // clear form
                              dispatch_async (dispatch_get_main_queue (), ^{
                                                  [self actionCancel:nil];
                                              }
                                              );
                          }
         ]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    // clear form
    dispatch_async (dispatch_get_main_queue (), ^{
                        [self actionCancel:nil];
                    }
                    );
}

@end
