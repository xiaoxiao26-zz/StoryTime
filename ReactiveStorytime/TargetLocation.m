//
//  TargetLocation.m
//  ReactiveStorytime
//
//  Created by Alex Xiao on 4/18/15.
//  Copyright (c) 2015 Stever2Startup. All rights reserved.
//

#import "TargetLocation.h"

@implementation TargetLocation

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        _lat = ((NSNumber *) dict[@"lat"]).doubleValue;
        _lng = ((NSNumber *) dict[@"lng"]).doubleValue;
        _name = dict[@"name"];
    }
    return self;
}

@end
