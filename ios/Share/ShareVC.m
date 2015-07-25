//
// ShareViewController.m
// Share
//
// Created by Marcus Rohrmoser on 18.03.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "ShareVC.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "NSUserDefaults+Share.h"
#import "ShaarliM.h"

@interface ShareVC() <UITextFieldDelegate, UITextViewDelegate, NSURLSessionDelegate> {
    SLComposeSheetConfigurationItem *itemTitle;
    SLComposeSheetConfigurationItem *itemTags;
    SLComposeSheetConfigurationItem *itemPrivate;
}
@property (readonly, strong, nonatomic) ShaarliM *shaarli;

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


-(NSArray *)configurationItems
{
    MRLogD(@"-", nil);
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.


    itemTitle = [[SLComposeSheetConfigurationItem alloc] init];
    itemTitle.title = NSLocalizedString(@"Title", @"ShaareVC");
    itemTitle.value = self.contentText;
    [itemTitle setTapHandler:^(void) {
         MRLogD (@"", nil);
     }
    ];

    itemTags = [[SLComposeSheetConfigurationItem alloc] init];
    itemTags.title = NSLocalizedString (@"Tags", @"ShaareVC");
    itemTags.value = @"";
    [itemTags setTapHandler:^(void) {
         MRLogD (@"", nil);
     }
    ];

    itemPrivate = [[SLComposeSheetConfigurationItem alloc] init];
    [itemPrivate setTitle:NSLocalizedString (@"Private", @"ShaareVC")];
    itemPrivate.value = NSLocalizedString (@"Private", @"ShaareVC");
    __weak typeof (itemPrivate)wr = itemPrivate;
    [itemPrivate setTapHandler:^(void) {
         MRLogD (@"", nil);
         const BOOL priv = [NSLocalizedString (@"Private", @"ShaareVC") isEqualToString:wr.value];
         wr.value = priv ? NSLocalizedString (@"Public", @"ShaareVC"):NSLocalizedString (@"Private", @"ShaareVC");
     }
    ];

#if 0
    SLComposeSheetConfigurationItem *itemShaar = [[SLComposeSheetConfigurationItem alloc] init];
    itemShaar.title = NSLocalizedString (@"Shaarə", @"ShaareVC");
    itemShaar.value = self.shaarli.title;
    [itemShaar setTapHandler:^(void) {
         MRLogD (@"", nil);
         NSURL *b = [NSURL URLWithString:SELF_URL_PREFIX @"://command/"];
         NSURL *c = [NSURL URLWithString:@"./https://google.com?q=a&a=b#c" relativeToURL:b];
         [self.extensionContext openURL:c completionHandler:^(BOOL success) {
              MRLogD (@"%d %@", success, c.absoluteString, nil);
          }
         ];
     }
    ];
    return @[itemTitle, itemTags, itemPrivate, itemShaar];
#else
    return @[itemTitle, itemTags, itemPrivate];
#endif
}


-(void)viewWillAppear:(BOOL)animated
{
    MRLogD(@"%@", [NSUserDefaults shaarliDefaults], nil);
    [super viewWillAppear:animated];
    self.view.tintColor = [UIColor colorWithRed:128 / 255.0f green:173 / 255.0f blue:72 / 255.0f alpha:1.0f];
    NSParameterAssert(self.shaarli);

    self.title = @"Shaarə"; // self.shaarli.title;
}


-(void)viewDidAppear:(BOOL)animated
{
    MRLogD(@"-", nil);
    [super viewDidAppear:animated];
    // self.payload[@"title"] = [self.extensionContext.inputItems[0] attributedContentText].string;
    NSParameterAssert(itemTitle);
    itemTitle.value = self.contentText;
    // self.textView.text = @"";
}


-(void)presentationAnimationDidFinish
{
    MRLogD(@"we may need to update the display.", nil);
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
    NSParameterAssert(1 == self.extensionContext.inputItems.count);
    NSExtensionItem *item = self.extensionContext.inputItems[0];
    for( NSItemProvider *itemProvider in item.attachments ) {
        NSString *t = @"public.url"; // (__bridge NSString *)kUTTypeText;
        // MRLogD(@"registeredTypeIdentifiers %@", itemProvider.registeredTypeIdentifiers, nil);
        if( [itemProvider hasItemConformingToTypeIdentifier:t] )
            [itemProvider loadItemForTypeIdentifier:t options:nil completionHandler:^(NSURL * url, NSError * error) {
                 MRLogD (@"SHAARE %@", @ { @"url":url, @"title":itemTitle.value, @"tags":itemTags.value, @"private":itemPrivate.value, @"desc":self.contentText }, nil);
                 NSString *confName = BUNDLE_ID @".backgroundpost";
                 NSURLSessionConfiguration *conf = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:confName];
                 NSURLSession *session = [NSURLSession sessionWithConfiguration:conf delegate:self delegateQueue:nil];

                 const BOOL priv = ![NSLocalizedString (@"Public", @"Shaare") isEqualToString:itemPrivate.value];
                 [self.shaarli postURL:url title:itemTitle.value tags:nil description:self.contentText private:
                  priv session:session completion:^(ShaarliM * me, NSError * error) {
                      // http://www.pixeldock.com/blog/ios8-share-extension-completionhandler-for-loaditemfortypeidentifier-is-never-called/
                      // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
                      [self.extensionContext completeRequestReturningItems:@[item] completionHandler:^(BOOL expired) {
                           MRLogD (@"expired: %s", expired ? "yes":"no", nil);
                       }
                      ];
                  }
                 ];
             }
            ];
    }
}


-(void)didSelectCancel
{
    MRLogD(@"-", nil);
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    [self.extensionContext cancelRequestWithError:error];
}


#pragma mark NSURLSessionDelegate


-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    MRLogD(@"%@, %@", session, error, nil);
}


-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    MRLogD(@"%@", session, nil);
}


@end
