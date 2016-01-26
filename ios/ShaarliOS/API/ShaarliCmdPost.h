//
// ShaarliCmdPost.h
// ShaarliOS
//
// Created by Marcus Rohrmoser on 12.10.15.
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

#import "ShaarliCmd.h"

@protocol ShaarliCmdPostDelegate <NSObject>
-(void)didPostLoginForm:(NSMutableDictionary *)form toURL:(NSURL *)url error:(NSError *)error;
-(void)didFinishPostFormToURL:(NSURL *)dst error:(NSError *)error;
@end

@interface ShaarliCmdPost : ShaarliCmd

@property (nonatomic, readwrite, strong) NSURLSession *session;
@property (nonatomic, readwrite, strong) NSURL *endpointURL;
@property (nonatomic, readwrite, assign) id <ShaarliCmdPostDelegate> delegate;

-(void)startPostForURL:(NSURL *)url title:(NSString *)title desc:(NSString *)desc;
-(void)finishPostForm:(NSMutableDictionary *)form toURL:(NSURL *)url;

@end
