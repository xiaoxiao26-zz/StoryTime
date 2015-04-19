//
//  LocationManager.h
//  ReactiveStorytime
//
//  Created by Alex Xiao on 4/16/15.
//  Copyright (c) 2015 Stever2Startup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "TargetLocation.h"

@interface StoryLocationManager : NSObject

@property (strong, nonatomic) TargetLocation *targetA;
@property (strong, nonatomic) TargetLocation *targetB;

- (RACSignal *)foundLocationSignalWithJson:(NSDictionary *)json;
+ (StoryLocationManager*) sharedManager;
- (RACSignal *)updatedLocationSignal;
- (RACSignal *)fetchStorySignal;

@end
