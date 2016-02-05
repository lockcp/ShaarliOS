//
// ShareViewController.m
// Share
//
// Created by Marcus Rohrmoser on 18.03.15.
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

#import "ShareVC.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "ShaarliM.h"
#import "ShaarliCmdPost.h"


static inline NSString *stringFromPrivacy(const BOOL priv)
{
    return priv ? NSLocalizedString(@"Private 🔐", @"ShaareVC") : NSLocalizedString(@"Public 🔓", @"ShaareVC");
}


static inline const BOOL privacyFromString(NSString *s)
{
    return ![stringFromPrivacy (NO) isEqualToString:s];
}


@interface ShareVC() <UITextFieldDelegate, UITextViewDelegate, ShaarliCmdPostDelegate> {
    SLComposeSheetConfigurationItem *itemTitle;
    SLComposeSheetConfigurationItem *itemAudience;
}
@property (readonly, strong, nonatomic) ShaarliM *shaarli;
@property (readwrite, strong, nonatomic) ShaarliCmdPost *post;
@property (readwrite, assign, nonatomic) BOOL wasTouched;

@property (readwrite, strong, nonatomic) NSMutableDictionary *postForm; // maybe move to ShaarliCmdPost ?
@property (readwrite, strong, nonatomic) NSURL *postURL; // maybe move to ShaarliCmdPost ?
@end


@implementation ShareVC

-(void)viewDidLoad
{
    MRLogD(@"-", nil);
    [super viewDidLoad];
    if( !self.shaarli ) {
        _shaarli = [[ShaarliM alloc] init];
        [self.shaarli load];
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
    itemAudience.value = stringFromPrivacy(NO);
    __weak typeof(itemAudience) wr = itemAudience;
    __weak typeof(self) weakSelf = self;

    [itemAudience setTapHandler:^(void) {
         wr.value = stringFromPrivacy ( !privacyFromString (wr.value) );
         weakSelf.wasTouched = YES;
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
    self.textView.keyboardType = UIKeyboardTypeTwitter;

    self.wasTouched = NO;
    itemTitle.value = self.contentText;
    NSString *tagsDefault = self.shaarli.tagsActive ? self.shaarli.tagsDefault : @"";
    {
        NSString *txt = @"🔄";
        if( 0 < tagsDefault.length )
            txt = [[tagsDefault stringByAppendingString:@" "] stringByAppendingString:txt];
        self.textView.text = txt;
    }
    itemAudience.value = stringFromPrivacy(self.shaarli.privateDefault);

    if( !self.shaarli.isSetUp )
        return;
    NSParameterAssert(self.shaarli.isSetUp);
    ShaarliCmdPost *re = [[ShaarliCmdPost alloc] init];
    re.session = self.shaarli.postSession;
    re.endpointURL = self.shaarli.endpointURL;
    re.delegate = self;
    self.post = re;

    for( NSExtensionItem *item in self.extensionContext.inputItems ) {
        for( NSItemProvider *itemProvider in item.attachments ) {
            // see predicate from http://stackoverflow.com/a/27932776
            NSString *t = (NSString *)kUTTypeURL;
            if( [itemProvider hasItemConformingToTypeIdentifier:t] ) {
                [itemProvider loadItemForTypeIdentifier:t options:nil completionHandler:^(NSURL * url, NSError * error) {
                     MRLogD (@"done. title:%@ url:%@ error:%@", itemTitle.value, url, error, nil);
                     if( !error ) {
                         [re startPostForURL:url title:itemTitle.value desc:nil];
                     } else {
                         MRLogW (@"Error: %@", error, nil);
                     }
                 }
                ];
                return;
            }
        }
    }
}


-(void)viewDidAppear:(BOOL)animated
{
    MRLogD(@"-", nil);
    [super viewDidAppear:animated];
    if( !self.shaarli.isSetUp ) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No Shaarli", @"Share") message:NSLocalizedString(@"There is no Shaarli account configured. You can add one in the Shaarli💫 in-app settings.", @"Share") preferredStyle:UIAlertControllerStyleAlert];
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
    MRLogD(@"-", nil);
}


-(BOOL)isContentValid
{
    MRLogD(@"-", nil);
    self.wasTouched = YES;
    return YES;
}


-(UIView *)loadPreviewView
{
    return nil;
}


-(void)didSelectPost
{
    MRLogD(@"-", nil);

    NSMutableDictionary *form = self.postForm;
    NSURL *dst = self.postURL;
    NSParameterAssert(form);
    NSParameterAssert(dst);

    [form setValue:itemTitle.value forKey:K_F_LF_TITLE]; // in case of text notes: set it again!
    if( self.shaarli.tagsActive ) {
        NSMutableArray *tags = [NSMutableArray arrayWithCapacity:5];
        [form setValue:[self.contentText stringByStrippingTags:tags] forKey:K_F_LF_DESCRIPTION];
        [form setValue:[tags componentsJoinedByString:@" "] forKey:K_F_LF_TAGS];
    } else
        [form setValue:self.contentText forKey:K_F_LF_DESCRIPTION];
    if( privacyFromString(itemAudience.value) )
        [form setValue:HTML_ON forKey:K_F_LF_PRIVATE];
    else
        [form removeObjectForKey:K_F_LF_PRIVATE];

    [self.post finishPostForm:form toURL:dst];
}


-(void)didSelectCancel
{
    MRLogD(@"-", nil);
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    [self.extensionContext cancelRequestWithError:error];
    self.post = nil;
}


-(void)cancelWithError:(NSError *)error
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Shaarlying failed", @"ShareVC") message:[NSString stringWithFormat:NSLocalizedString(@"%@\n\nFailing call was %@", @"ShareVC"), error.localizedDescription, error.userInfo[NSURLErrorKey]] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"ShareVC") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                          // http://www.pixeldock.com/blog/ios8-share-extension-completionhandler-for-loaditemfortypeidentifier-is-never-called/
                          // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
                          [super cancel];
                          self.post = nil;
                      }
     ]];
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark ShaarliCmdPostDelegate


// Update GUI
-(void)form2Gui:(NSDictionary *)form
{
    itemAudience.value = stringFromPrivacy([HTML_ON isEqualToString:form[K_F_LF_PRIVATE]]);
    NSString *txt = form[K_F_LF_DESCRIPTION];
    if( self.shaarli.tagsActive ) {
        NSString *tags = [form[K_F_LF_TAGS] stringByReplacingOccurrencesOfString:@" " withString:@" #"];
        if( 0 < tags.length )
            tags = [@"#" stringByAppendingString:tags];
        else if( 0 == txt.length )
            tags = self.shaarli.tagsDefault;
        else
            tags = @"";
        if( 0 < tags.length )
            tags = [tags stringByAppendingString:@" "];

        txt = [tags stringByAppendingString:txt];
    }
    self.textView.text = txt;
}


-(void)didPostLoginForm:(NSMutableDictionary *)form toURL:(NSURL *)dst error:(NSError *)error
{
    MRLogD(@"%@ %@", form, error, nil);
    if( error ) {
        [self cancelWithError:error];
        return;
    }
    self.postForm = form;
    self.postURL = dst;
    if( !self.wasTouched )
        [self form2Gui:form];
    else {
        MRLogD(@"Evtl. show a hint that there was discarded incoming server data.", nil);
    }
}


-(void)didFinishPostFormToURL:(NSURL *)dst error:(NSError *)error
{
    MRLogD(@"%@ %@", dst, error, nil);
    if( error ) {
        [self cancelWithError:error];
        return;
    }
    // http://www.pixeldock.com/blog/ios8-share-extension-completionhandler-for-loaditemfortypeidentifier-is-never-called/
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [super didSelectPost];
    self.post = nil;
}


@end
