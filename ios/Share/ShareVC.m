//
// ShareViewController.m
// Share
//
// Created by Marcus Rohrmoser on 18.03.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "ShareVC.h"
#import "NSUserDefaults+Share.h"
#import "ShaarliM.h"

@interface ShareVC() <UITextFieldDelegate, UITextViewDelegate, NSURLSessionDelegate>
@property (readonly, strong, nonatomic) ShaarliM *shaarli;

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
    if( !self.shaarli ) {
        _shaarli = [[ShaarliM alloc] init];
        [self.shaarli load];
        NSParameterAssert(self.shaarli.title);
    }
}


-(void)viewWillAppear:(BOOL)animated
{
    MRLogD(@"%@", [NSUserDefaults shaarliDefaults], nil);
    [super viewWillAppear:animated];
    self.view.tintColor = [UIColor colorWithRed:128 / 255.0f green:173 / 255.0f blue:72 / 255.0f alpha:1.0f];
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

    NSParameterAssert(1 == self.extensionContext.inputItems.count);
    NSExtensionItem *i = self.extensionContext.inputItems[0];
    for( NSItemProvider *ip in i.attachments ) {
        MRLogD(@"%@", ip.registeredTypeIdentifiers, nil);
    }

    NSString *confName = [[[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:@"CFBundleIdentifier"] stringByAppendingString:@".backgroundpost"];
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:confName];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:conf delegate:self delegateQueue:nil];

    // [self.shaarli postURL:<#(NSURL *)#> title:<#(NSString *)#> tags:<#(id<NSFastEnumeration>)#> description:<#(NSString *)#> private:<#(BOOL)#> session:session completion:<#^(ShaarliM *me, NSError *error)completion#>]

    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
}


-(void)didSelectCancel
{
    MRLogD(@"-", nil);
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    [self.extensionContext cancelRequestWithError:error];
}


-(NSArray *)configurationItems
{
    MRLogD(@"-", nil);
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.

    SLComposeSheetConfigurationItem *tags = [[SLComposeSheetConfigurationItem alloc] init];
    tags.title = @"Tags";
    tags.value = @"t1 t2 t3 t4 t5 t6 t7 t8 t9";
    [tags setTapHandler:^(void) {
        MRLogD (@"", nil);
    }
     ];

    SLComposeSheetConfigurationItem *priva = [[SLComposeSheetConfigurationItem alloc] init];
    [priva setTitle:@"Private"];
    [priva setValue:@"Public"];
    [priva setTapHandler:^(void) {
         MRLogD (@"", nil);
     }
    ];

    SLComposeSheetConfigurationItem *sha = [[SLComposeSheetConfigurationItem alloc] init];
    sha.title = @"Shaarli";
    sha.value = self.shaarli.title;
    NSParameterAssert(self.shaarli);
    NSParameterAssert(self.shaarli.title);
    NSParameterAssert(sha.value);
    [sha setTapHandler:^(void) {
    }
     ];

    return @[tags, priva, sha];
}


#pragma mark NSURLSessionDelegate


-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    MRLogD(@"", nil);
}


@end
