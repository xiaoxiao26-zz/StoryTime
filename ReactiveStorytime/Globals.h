//
//  Globals.h
//  ReactiveStorytime
//
//  Created by Alex Xiao on 4/16/15.
//  Copyright (c) 2015 Stever2Startup. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Globals : NSObject

extern NSString * const kStoryKey;
extern NSString * const kJsonKey;
extern NSString * const kTargetKey;
extern NSString * const kStoryErrorDomain;


typedef enum StoryErrorCode : NSUInteger {
    StoryErrorEmpty = 0
} StoryErrorCode;

@end
