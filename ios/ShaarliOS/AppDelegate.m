//
// AppDelegate.m
// ShaarliOS
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

#import "AppDelegate.h"
#import "NSBundle+MroSemVer.h"
#import "MainVC.h"

@interface AppDelegate()
@property (assign, readonly, nonatomic) MainVC *vc;
@end

@implementation AppDelegate

-(MainVC *)vc
{
    NSParameterAssert([self.window.rootViewController isKindOfClass:[UINavigationController class]]);
    UINavigationController *nvc = (UINavigationController *)self.window.rootViewController;
    MainVC *vc = (MainVC *)nvc.viewControllers[0];
    return vc;
}


-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    MRLogD(@"%@", [NSBundle semVer], nil);
    {
        NSDictionary *d = [[NSBundle mainBundle] infoDictionary];
        // MRLogD(@"%@", [d valueForKeyPath:@"CFBundleURLTypes.CFBundleURLSchemes.@firstObject"], nil);
        NSParameterAssert([SELF_URL_PREFIX isEqualToString:d[@"CFBundleURLTypes"][0][@"CFBundleURLSchemes"][0]]);
        NSParameterAssert([BUNDLE_ID isEqualToString:d[@"CFBundleIdentifier"]]);
    }
    ShaarliM *s = [[ShaarliM alloc] init];
    [s load];
    self.vc.shaarli = s;
    // [s postTest];
    return YES;
}


-(void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


-(void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


-(void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


-(void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


-(void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:( void (^)() )completionHandler
{
    MRLogE(@"%@", identifier, nil);
    completionHandler();
    // NSParameterAssert(NO);
}


@end
