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

#define POST_STEP_1 @"step-1"
#define POST_STEP_2 @"step-2"
#define POST_STEP_3 @"step-3"
#define POST_STEP_4 @"step-4"

#define POST_SOURCE @"http://app.mro.name/ShaarliOS"

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

    NSString *confName = BUNDLE_ID @".backgroundpost";
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:confName];
    conf.sharedContainerIdentifier = @"group." BUNDLE_ID; // http://stackoverflow.com/a/26319143
    conf.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:conf delegate:self delegateQueue:nil];
    session.sessionDescription = @"Shaarli Post";
    NSParameterAssert(session.configuration.HTTPCookieStorage);
    NSParameterAssert(session.configuration.HTTPCookieStorage == [NSHTTPCookieStorage sharedHTTPCookieStorage]);
    NSParameterAssert(NSHTTPCookieAcceptPolicyAlways == session.configuration.HTTPCookieAcceptPolicy);
    NSParameterAssert(session.configuration.HTTPShouldSetCookies);
    NSParameterAssert(self == session.delegate);
    for( NSHTTPCookie *cook in session.configuration.HTTPCookieStorage.cookies ) {
        MRLogD(@"deleteCookie %@", cook, nil);
        [session.configuration.HTTPCookieStorage deleteCookie:cook];
    }

    NSParameterAssert(1 == self.extensionContext.inputItems.count);
    NSExtensionItem *item = self.extensionContext.inputItems[0];
    for( NSItemProvider *itemProvider in item.attachments ) {
        NSString *t = @"public.url"; // (__bridge NSString *)kUTTypeText;
        if( [itemProvider hasItemConformingToTypeIdentifier:t] )
            [itemProvider loadItemForTypeIdentifier:t options:nil completionHandler:^(NSURL * url, NSError * error) {
                 const BOOL priv = ![NSLocalizedString (@"Public", @"Shaare") isEqualToString:itemPrivate.value];
                 // @todo itemTags !
                 NSString *par = [@"?post=" stringByAppendingString:[url.absoluteString stringByAddingPercentEscapesForHttpFormUrl]];
                 par = [par stringByAppendingFormat:@"&%@=%@", @"title", [itemTitle.value stringByAddingPercentEscapesForHttpFormUrl]];
                 par = [par stringByAppendingFormat:@"&%@=%@", @"description", [self.contentText stringByAddingPercentEscapesForHttpFormUrl]];
                 par = [par stringByAppendingFormat:@"&%@=%@", @"source", [POST_SOURCE stringByAddingPercentEscapesForHttpFormUrl]];

                 NSURL *cmd = [NSURL URLWithString:par relativeToURL:self.shaarli.endpointUrl];
                 NSURLSessionTask *dt = [session downloadTaskWithURL:cmd];
                 dt.taskDescription = POST_STEP_1;
                 MRLogD (@"%@ %@ %@", dt.taskDescription, dt.currentRequest.HTTPMethod, dt.currentRequest.URL, nil);
                 [dt resume];

                 // http://www.pixeldock.com/blog/ios8-share-extension-completionhandler-for-loaditemfortypeidentifier-is-never-called/
                 // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
                 /*
                  * [self.extensionContext completeRequestReturningItems:@[item] completionHandler:^(BOOL expired) {
                  *    MRLogD (@"expired: %s", expired ? "yes":"no", nil);
                  * }
                  * ];
                  */
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
    MRLogD(@"%@, %@", session.sessionDescription, error, nil);
}


-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    MRLogD(@"%@", session.sessionDescription, nil);
}


#pragma mark NSURLSessionTaskDelegate


/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    MRLogD(@"'%@' task-%d '%@' %@ %@", session.sessionDescription, task.taskIdentifier, task.taskDescription, error, nil);
    MRLogD(@"'%@' task-%d ORIGINAL: %@ %@ %@", session.sessionDescription, task.taskIdentifier, task.originalRequest.HTTPMethod, task.originalRequest.URL, nil);
    if( [@"POST" isEqualToString:task.originalRequest.HTTPMethod] ) {
        MRLogD(@"%@", [[NSString alloc] initWithData:task.originalRequest.HTTPBody encoding:NSUTF8StringEncoding], nil);
    }
    MRLogD(@"'%@' task-%d CURRENT : %@ %@ %@", session.sessionDescription, task.taskIdentifier, task.currentRequest.HTTPMethod, task.currentRequest.URL, nil);
}


#pragma mark NSUrlSessionDataDelegate


/* The task has received a response and no further messages will be
 * received until the completion block is called. The disposition
 * allows you to cancel a request or to turn a data task into a
 * download task. This delegate message is optional - if you do not
 * implement it, you can get the response as a property of the task.
 *
 * This method will not be called for background upload tasks (which cannot be converted to download tasks).
 */
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:( void (^)(NSURLSessionResponseDisposition disposition) )completionHandler
{
    MRLogD(@"'%@' task-%d '%@'", session.sessionDescription, dataTask.taskIdentifier, dataTask.taskDescription, nil);
    completionHandler(NSURLSessionResponseBecomeDownload);
}


/* Notification that a data task has become a download task.  No
 * future messages will be sent to the data task.
 */
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    MRLogD(@"'%@' task-%d '%@' -> task-%d '%@'", session.sessionDescription, dataTask.taskIdentifier, dataTask.taskDescription, downloadTask.taskIdentifier, downloadTask.taskDescription, nil);
}


/* Sent when data is available for the delegate to consume.  It is
 * assumed that the delegate will retain and not copy the data.  As
 * the data may be discontiguous, you should use
 * [NSData enumerateByteRangesUsingBlock:] to access it.
 */
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    MRLogD(@"'%@' task-%d '%@' ORIGINAL: %@ %@", session.sessionDescription, dataTask.taskIdentifier, dataTask.taskDescription, dataTask.originalRequest.HTTPMethod, dataTask.originalRequest.URL, nil);
    if( [@"POST" isEqualToString:dataTask.originalRequest.HTTPMethod] )
        MRLogD(@"%@", [[NSString alloc] initWithData:dataTask.originalRequest.HTTPBody encoding:NSUTF8StringEncoding], nil);
    MRLogD(@"'%@' task-%d '%@' CURRENT : %@ %@", session.sessionDescription, dataTask.taskIdentifier, dataTask.taskDescription, dataTask.currentRequest.HTTPMethod, dataTask.currentRequest.URL, nil);
    MRLogD(@"'%@' task-%d %@", session.sessionDescription, dataTask.taskIdentifier, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], nil);
}


/* Invoke the completion routine with a valid NSCachedURLResponse to
 * allow the resulting data to be cached, or pass nil to prevent
 * caching. Note that there is no guarantee that caching will be
 * attempted for a given resource, and you should not rely on this
 * message to receive the resource data.
 */
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse
   completionHandler:( void (^)(NSCachedURLResponse * cachedResponse) )completionHandler
{
    MRLogD(@"'%@' task-%d '%@'", session.sessionDescription, dataTask.taskIdentifier, dataTask.taskDescription, nil);
}


#pragma mark NSURLSessionDownloadDelegate


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    MRLogD(@"'%@' task-%d '%@' ORIGINAL: %@ %@", session.sessionDescription, downloadTask.taskIdentifier, downloadTask.taskDescription, downloadTask.originalRequest.HTTPMethod, downloadTask.originalRequest.URL, nil);
    MRLogD(@"'%@' task-%d '%@' CURRENT : %@ %@", session.sessionDescription, downloadTask.taskIdentifier, downloadTask.taskDescription, downloadTask.currentRequest.HTTPMethod, downloadTask.currentRequest.URL, nil);
    NSArray *cookies = [session.configuration.HTTPCookieStorage cookiesForURL:downloadTask.currentRequest.URL];
    MRLogD(@"cookies %@", cookies, nil);

    NSData *data = [NSData dataWithContentsOfURL:location];
    NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *ret = [self.shaarli parseHtmlData:data error:nil];
    MRLogD(@"task-%d %@", downloadTask.taskIdentifier, ret, nil);
    NSString *token = ret[M_FORM][F_TOKEN];
    if( !token ) {
        MRLogD(@"NO TOKEN! @todo add a error to NSUserDefaults Error queue.", nil);
        MRLogD(@"%@\n%@", downloadTask.currentRequest.URL.absoluteURL, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], nil);
        return;
    }
    NSParameterAssert(40 == token.length);
    if( [POST_STEP_1 isEqualToString:downloadTask.taskDescription] ) {
        if( ![ret[M_HAS_LOGOUT] boolValue] ) {
            NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:downloadTask.currentRequest.URL];
            req.HTTPMethod = @"POST";

            NSDictionary *cd = [session.configuration.URLCredentialStorage credentialsForProtectionSpace:[req.URL protectionSpace]];
            NSParameterAssert(1 == cd.count);
            NSURLCredential *cre = [[cd objectEnumerator] nextObject];

            NSDictionary *post = @ {
                @"login" : cre.user, @"password" : cre.password, F_TOKEN : token, @"returnurl" : downloadTask.originalRequest.URL.absoluteString
            };
            req.HTTPBody = [post postData];
            NSURLSessionTask *dt = [session downloadTaskWithRequest:req];
            dt.taskDescription = POST_STEP_2;
            MRLogD(@"%@ %@ %@", dt.taskDescription, dt.currentRequest.HTTPMethod, dt.currentRequest.URL.absoluteURL, nil);
            MRLogD(@"POST DATA %@", [[NSString alloc] initWithData:dt.currentRequest.HTTPBody encoding:NSUTF8StringEncoding]);
            [dt resume];
        } else {
            MRLogD(@"task-%d %@", downloadTask.taskIdentifier, ret, nil);
        }
        return;
    }
    if( [POST_STEP_2 isEqualToString:downloadTask.taskDescription] ) {
        if( [ret[M_HAS_LOGOUT] boolValue] ) {
            MRLogD(@"task-%d YIPPIE !!!!!", downloadTask.taskIdentifier, nil);
        } else {
            MRLogD(@"ENDE", nil);
        }
    }
    MRLogD(@"task-%d Fallthrough", downloadTask.taskIdentifier, nil);
    // NSParameterAssert(NO);
    [super didSelectPost];
}


-(void)URLSession:(NSURLSession *)session
   downloadTask:(NSURLSessionDownloadTask *)downloadTask
   didWriteData:(int64_t)bytesWritten
   totalBytesWritten:(int64_t)totalBytesWritten
   totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    MRLogD(@"'%@' task-%d '%@' %lld", session.sessionDescription, downloadTask.taskIdentifier, downloadTask.taskDescription, totalBytesWritten, nil);
}


@end
