//
//  StoryManager.h
//  ReactiveStorytime
//
//  Created by Alex Xiao on 3/16/15.
//  Copyright (c) 2015 Stever2Startup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface StoryManager : NSObject

- (RACSignal *)storySignalWithStory:(NSString *)story;
+ (instancetype)sharedManager;


@end
