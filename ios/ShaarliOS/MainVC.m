//
// ViewController.m
// ShaarliOS
//
// Created by Marcus Rohrmoser on 18.03.15.
// Copyright (c) 2015 Marcus Rohrmoser http://mro.name/me. All rights reserved.
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

@interface MainVC() <UITextFieldDelegate, UITextViewDelegate, ShaarliPostDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerY;
@property (weak, nonatomic) IBOutlet UILabel *lblVersion;
@property (weak, nonatomic) IBOutlet UIView *vContainer;
@property (weak, nonatomic) IBOutlet UIButton *btnPetal;

@property (weak, nonatomic) IBOutlet UIView *viewShaare;
@property (weak, nonatomic) IBOutlet UIButton *btnShaare;
@property (weak, nonatomic) IBOutlet UITextView *txtDescr;
@property (weak, nonatomic) IBOutlet UITextField *txtTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnAudience;

// http://spin.atomicobject.com/2014/03/05/uiscrollview-autolayout-ios/
@property (weak, nonatomic) UIView *activeField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@end

@implementation MainVC

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if( self = [super initWithCoder:aDecoder] ) {
        // register for Keyboard visibility events
        // https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html#//apple_ref/doc/uid/TP40009542-CH5-SW7
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


#pragma mark UIViewController


-(void)viewDidLoad
{
    MRLogD(@"", nil);
    [super viewDidLoad];
    NSParameterAssert(self.vContainer);
    NSParameterAssert(self.centerY);
    NSParameterAssert(self.btnPetal);

    NSParameterAssert(self.viewShaare);
    NSParameterAssert(self.btnShaare);
    NSParameterAssert(self.btnPetal);
    NSParameterAssert(self.txtDescr);
    NSParameterAssert(self.txtTitle);
    NSParameterAssert(self.btnAudience);
}


-(void)viewWillAppear:(BOOL)animated
{
    MRLogD(@"-", nil);
    NSParameterAssert(self.shaarli);
    [super viewWillAppear:animated];
    self.title = self.shaarli.title;
    self.lblVersion.text = [NSBundle semVer];
    self.lblVersion.alpha = 0;
    self.viewShaare.alpha = 0;
}


-(void)viewDidAppear:(BOOL)animated
{
    MRLogD(@"-", nil);
    [super viewDidAppear:animated];
    // animate logo to bottom
    [UIView animateWithDuration:0.5f animations:^{
         self.vContainer.alpha = 0.5;
         self.lblVersion.alpha = 1.0;

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
    // start with note form ready..
    [self actionShowShaare:nil];
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


-(IBAction)actionShowShaare:(id)sender
{
    MRLogD(@"-", nil);
    self.btnShaare.enabled = YES;
    self.txtDescr.text = self.shaarli.tagsActive ? [NSString stringWithFormat:@"%@ ", self.shaarli.tagsDefault] : @"";
    self.txtTitle.text = @"";
    self.btnAudience.selected = self.shaarli.privateDefault;

    self.viewShaare.alpha = 0;
    self.viewShaare.hidden = NO;
    [UIView animateWithDuration:0.5 animations:^{
         self.viewShaare.alpha = 1;
     }
     completion:^(BOOL finished) {
         [self.txtDescr becomeFirstResponder];
     }
    ];
}


-(IBAction)actionHideShaare:(id)sender
{
    MRLogD(@"-", nil);
    [self.txtDescr resignFirstResponder];
    [self.txtTitle resignFirstResponder];
    [UIView animateWithDuration:0.5 animations:^{
         self.viewShaare.alpha = 0;
     }
     completion:^(BOOL finished) {
         self.viewShaare.hidden = YES;
     }
    ];
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
    [self actionHideShaare:sender];
}


-(IBAction)actionPost:(id)sender
{
    MRLogD(@"-", nil);
    self.btnShaare.enabled = NO;
    [self.txtDescr resignFirstResponder];
    [self.txtTitle resignFirstResponder];
    NSURLSession *session = [self.shaarli postSession];
    [self.shaarli postUrl:nil title:self.txtTitle.text description:self.txtDescr.text session:session delegate:self];
}


#pragma mark UITextViewDelegate

-(void)textViewDidBeginEditing:(UITextView *)sender
{
    self.activeField = sender;
}


-(void)textViewDidEndEditing:(UITextView *)sender
{
    self.activeField = nil;
}


#pragma mark UITextFieldDelegate


/** called when 'return' key pressed. return NO to ignore. */
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    MRLogD(@"%@", textField.text, nil);
    if( textField == self.txtTitle )
        [self actionPost:textField];
    return YES;
}


-(void)textFieldDidBeginEditing:(UITextField *)sender
{
    self.activeField = sender;
}


-(void)textFieldDidEndEditing:(UITextField *)sender
{
    self.activeField = nil;
}


#pragma mark Keyboard


// inspired by
// http://spin.atomicobject.com/2014/03/05/uiscrollview-autolayout-ios/
// http://www.think-in-g.net/ghawk/blog/2012/09/practicing-auto-layout-an-example-of-keyboard-sensitive-layout/
-(void)keyboardWillShow:(NSNotification *)notification
{
    UIScrollView *scrollV = self.scrollView;
    UIView *active = self.activeField;
    NSParameterAssert(scrollV);

    {
        NSDictionary *info = [notification userInfo];
        // const NSTimeInterval dt = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        const CGRect keyboardRaw = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

        const CGFloat marginY = 2;
        UIView *refViw = scrollV.superview; // the view that can be moved up until frame.origin.y = marginY
        NSParameterAssert(refViw);
        const CGRect keyboard = [refViw convertRect:keyboardRaw fromView:nil];

        // Test if scrollV and keyboard collide - if NO we're fine.
        const CGRect scrollBounds0 = [scrollV convertRect:scrollV.bounds toView:refViw];
        const CGRect overlap0 = CGRectIntersection(scrollBounds0, keyboard);
        if( CGRectIsNull(overlap0) )
            return;

        {
            // if colliding, move up
            CGRect f = refViw.frame;
            f.origin.y = MAX( marginY, f.origin.y - CGRectGetMaxY(overlap0) );
            refViw.frame = f;
        }
        {
            // if still colliding, add inset to scrollView.
            const CGRect scrollBounds1 = [scrollV convertRect:scrollV.bounds toView:refViw];
            const CGRect overlap1 = CGRectIntersection(scrollBounds1, keyboard);
            if( CGRectIsNull(overlap1) )
                return;
            const UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0f, 0.0f, overlap1.size.height, 0.0f);
            scrollV.contentInset = scrollV.scrollIndicatorInsets = contentInsets;
        }
    }

    NSParameterAssert(active);
    // finally scroll to top of active input field:
    CGRect visible = [active convertRect:CGRectIntersection(active.bounds, scrollV.bounds) toView:scrollV];
    // MRLogD(@"%.0f,%.0f %.0fx%.0f", visible.origin.x, visible.origin.y, visible.size.width, visible.size.height, nil);
    visible.size.height = 1;
    [scrollV scrollRectToVisible:visible animated:YES];
}


-(void)keyboardWillHide:(NSNotification *)notification
{
    MRLogD(@"-", nil);
    // back to original insets and view frame:
    self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset = UIEdgeInsetsZero;
    [self.scrollView.superview.superview setNeedsLayout];
    [self.scrollView.superview.superview layoutIfNeeded];
}


#pragma mark ShaarliPostDelegate


-(BOOL)postPrivate
{
    return self.btnAudience.selected;
}


-(NSString *)postDescription
{
    return self.txtDescr.text;
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
    // success, clear form
    dispatch_async (dispatch_get_main_queue (), ^{
                        [self actionHideShaare:nil];
                    }
                    );
}

@end
