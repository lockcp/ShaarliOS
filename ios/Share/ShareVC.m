//
// ShareViewController.m
// Share
//
// Created by Marcus Rohrmoser on 18.03.15.
// Copyright (c) 2015 Marcus Rohrmoser. All rights reserved.
//

#import "ShareVC.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "ShaarliM.h"


@interface ShareVC() <UITextFieldDelegate, UITextViewDelegate, ShaarliPostDelegate> {
    SLComposeSheetConfigurationItem *itemTitle;
    SLComposeSheetConfigurationItem *itemAudience;
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
        // NSParameterAssert(self.shaarli.title);
    }
}


-(NSArray *)configurationItems
{
    MRLogD(@"-", nil);
    itemTitle = [[SLComposeSheetConfigurationItem alloc] init];
    itemTitle.title = NSLocalizedString(@"Title", @"ShaareVC");
    itemTitle.value = self.contentText;

    itemAudience = [[SLComposeSheetConfigurationItem alloc] init];
    [itemAudience setTitle:NSLocalizedString(@"Audience", @"ShaareVC")];
    itemAudience.value = self.shaarli.privateDefault ? NSLocalizedString(@"Private 🔐", @"ShaareVC") : NSLocalizedString(@"Public 🔓", @"ShaareVC");
    __weak typeof(itemAudience) wr = itemAudience;
    __weak typeof(self) ws = self;

    [itemAudience setTapHandler:^(void) {
         wr.value = !ws.postPrivate ? NSLocalizedString (@"Private 🔐", @"ShaareVC"):NSLocalizedString (@"Public 🔓", @"ShaareVC");
     }
    ];

    return @[itemTitle, itemAudience];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.view.tintColor = [UIColor colorWithRed:128 / 255.0f green:173 / 255.0f blue:72 / 255.0f alpha:1.0f];
    NSParameterAssert(self.shaarli);
    NSParameterAssert(itemTitle);

    self.title = self.shaarli.title;
    itemTitle.value = self.contentText;
    if( self.shaarli.tagsActive && self.shaarli.tagsDefault.length > 0 )
        self.textView.text = [self.contentText stringByAppendingFormat:@"\n%@ ", self.shaarli.tagsDefault];
}


-(void)viewDidAppear:(BOOL)animated
{
    MRLogD(@"-", nil);
    [super viewDidAppear:animated];
    if( !self.shaarli.isSetUp ) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No Shaarli", @"Share") message:NSLocalizedString(@"There is no Shaarli account configured. You can add one in the ShaarliOS in-app settings.", @"Share") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Share") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                              [self cancel];
                          }
         ]];
        dispatch_async (dispatch_get_main_queue (), ^{
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                        );
        return;
    }
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
    NSURLSession *session = [self.shaarli postSession];

    NSParameterAssert(1 == self.extensionContext.inputItems.count);
    NSExtensionItem *item = self.extensionContext.inputItems[0];
    for( NSItemProvider *itemProvider in item.attachments ) {
        // see predicate from http://stackoverflow.com/a/27932776
        NSString *t = @"public.url"; // (__bridge NSString *)kUTTypeText;
        if( [itemProvider hasItemConformingToTypeIdentifier:t] )
            [itemProvider loadItemForTypeIdentifier:t options:nil completionHandler:^(NSURL * url, NSError * error) {
                 [self.shaarli postUrl:url title:itemTitle.value description:self.contentText session:session delegate:self];
             }
            ];
    }
#if 0
    NSError *e = [NSError errorWithDomain:SHAARLI_ERROR_DOMAIN code:-1 userInfo:@ { NSLocalizedDescriptionKey:NSLocalizedString (@"Found no item to share.", @"ShareVC") }
                 ];
    [self shaarli:nil didFinishPostWithError:e];
#endif
}


-(void)didSelectCancel
{
    MRLogD(@"-", nil);
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    [self.extensionContext cancelRequestWithError:error];
}


#pragma mark ShaarliPostDelegate


-(BOOL)postPrivate
{
    return ![NSLocalizedString (@"Public 🔓", @"Shaare") isEqualToString:itemAudience.value];
}


-(void)shaarli:(ShaarliM *)shaarli didFinishPostWithError:(NSError *)error
{
    if( error ) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Shaarlying failed", @"ShareVC") message:[NSString stringWithFormat:NSLocalizedString(@"%@\n\nFailing call was %@", @"ShareVC"), error.localizedDescription, error.userInfo[NSURLErrorKey]] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"ShareVC") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                              // http://www.pixeldock.com/blog/ios8-share-extension-completionhandler-for-loaditemfortypeidentifier-is-never-called/
                              // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
                              [super cancel];
                          }
         ]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    // http://www.pixeldock.com/blog/ios8-share-extension-completionhandler-for-loaditemfortypeidentifier-is-never-called/
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [super didSelectPost];
}


@end
