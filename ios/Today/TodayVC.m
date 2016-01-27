//
// TodayVC.m
// Today
//
// Created by Marcus Rohrmoser on 27.01.16.
// Copyright (c) 2016-2016 Marcus Rohrmoser http://mro.name/me. All rights reserved.
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

#import "TodayVC.h"
#import <NotificationCenter/NotificationCenter.h>

@interface TodayVC() <NCWidgetProviding>

@end

@implementation TodayVC

-(void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}


-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)widgetPerformUpdateWithCompletionHandler:( void (^)(NCUpdateResult) )completionHandler
{
    // Perform any setup necessary in order to update the view.

    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}


-(IBAction)actionNote:(id)sender
{
    NSURL *url = [NSURL URLWithString:SELF_URL_PREFIX @"://localhost/note/add"];
    [self.extensionContext openURL:url completionHandler:^(BOOL success) {
         MRLogD (@"-", nil);
     }
    ];
}

@end
