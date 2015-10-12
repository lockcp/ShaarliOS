//
// ShareViewController.m
// Share
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

#import "ShareVC.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "ShaarliM.h"
#import "ShaarliCmdPost.h"


@interface ShareVC() <UITextFieldDelegate, UITextViewDelegate, ShaarliPostDelegate> {
    SLComposeSheetConfigurationItem *itemTitle;
    SLComposeSheetConfigurationItem *itemAudience;
}
@property (readonly, strong, nonatomic) ShaarliM *shaarli;
@property (readwrite, strong, nonatomic) ShaarliCmdPost *post;
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
    itemAudience.title = NSLocalizedString(@"Audience", @"ShaareVC");
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

    self.textView.keyboardType = UIKeyboardTypeTwitter;
    self.title = self.shaarli.title;
    itemTitle.value = self.contentText;
    if( self.shaarli.tagsActive && self.shaarli.tagsDefault.length > 0 )
        self.textView.text = [@"" stringByAppendingFormat:@"%@ ", self.shaarli.tagsDefault];
    else
        self.textView.text = @"";

    ShaarliCmdPost *re = [[ShaarliCmdPost alloc] init];
    re.session = self.shaarli.postSession;
    re.endpointUrl = self.shaarli.endpointUrl;
    re.delegate = self;
    self.post = re;

    NSParameterAssert(1 == self.extensionContext.inputItems.count);
    NSExtensionItem *item = self.extensionContext.inputItems[0];
    for( NSItemProvider *itemProvider in item.attachments ) {
        // see predicate from http://stackoverflow.com/a/27932776
        NSString *t = @"public.url"; // (__bridge NSString *)kUTTypeText;
        if( [itemProvider hasItemConformingToTypeIdentifier:t] )
            [itemProvider loadItemForTypeIdentifier:t options:nil completionHandler:^(NSURL * url, NSError * error) {
                 if( !error )
                     [re startPostForURL:url title:nil desc:nil];
                 else {
                     MRLogW (@"Error: %@", error, nil);
                 }
             }
            ];
    }
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
    return YES;
}


-(UIView *)loadPreviewView
{
    return nil;
}


-(void)didSelectPost
{
    MRLogD(@"-", nil);
    [self.post finishPostForm:nil toURL:nil];
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


-(NSString *)postDescription
{
    return self.contentText;
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
