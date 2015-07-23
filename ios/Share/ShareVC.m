//
// ShareViewController.m
// Share
//
// Created by Marcus Rohrmoser on 18.03.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "ShareVC.h"
#import "NSUserDefaults+Share.h"

@interface ShareVC()<UITextFieldDelegate,UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *urlTxt;
@property (weak, nonatomic) IBOutlet UITextField *titleTxt;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTxt;
@property (weak, nonatomic) IBOutlet UITextField *tagsTxt;
@property (weak, nonatomic) IBOutlet UIButton *shaareBtn;
@end

@implementation ShareVC

-(void)viewDidLoad
{
    MRLogD(@"-", nil);
    [super viewDidLoad];
}


-(void)viewWillAppear:(BOOL)animated
{
    MRLogD(@"%@", [NSUserDefaults shaarliDefaults], nil);
    [super viewWillAppear:animated];
}


-(BOOL)isContentValid
{
    MRLogD(@"-", nil);
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}


-(void)didSelectPost
{
    MRLogD(@"-", nil);
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.

    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}


-(NSArray *)configurationItems
{
    MRLogD(@"-", nil);
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}


@end
