//
//  LocationManager.m
//  ReactiveStorytime
//
//  Created by Alex Xiao on 4/16/15.
//  Copyright (c) 2015 Stever2Startup. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <AFNetworking-RACExtensions/RACAFNetworking.h>

#import <MapKit/MapKit.h>
#import "StoryLocationManager.h"
#import "Globals.h"
#import "TargetLocation.h"


@interface StoryLocationManager() <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) RACSubject *locationSubject;
@property (readwrite, nonatomic) int numberOfLocationSubscribers;
@property (strong, nonatomic) NSDictionary *json;

@end



@implementation StoryLocationManager

NSUInteger const RADIUS_OF_DETECTION = 50;
NSUInteger const LAST_CHAPTER = 5;
NSString * const STORY_URL = @"apjaffe.res.cmu.edu:8080/story?";

+ (instancetype) sharedManager {
    
    static StoryLocationManager *sharedLocationManager;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        sharedLocationManager = [[StoryLocationManager alloc] init];
        
    });
    
    return sharedLocationManager;
}



- (id)init {
    
    self = [super init];
    
    if(!self) return nil;
    
    
    
    _locationSubject = [RACSubject subject];
    
    _locationManager = [[CLLocationManager alloc] init];
    
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager requestAlwaysAuthorization];    
    
    return self;
}


- (RACSignal *)updatedLocationSignal {
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @synchronized(self) {
            
            if(self.numberOfLocationSubscribers == 0) {
                
                [self.locationManager startUpdatingLocation];
                
            }
            
            ++self.numberOfLocationSubscribers;
            
        }
        
        [self.locationSubject subscribe:subscriber];
        
        return [RACDisposable disposableWithBlock:^{
            
            @synchronized(self) {
                
                --self.numberOfLocationSubscribers;
                
                if(self.numberOfLocationSubscribers == 0) {                    
                    [self.locationManager stopUpdatingLocation];
                }
            }
            
        }];
    }];
}

- (BOOL)locationInRange:(CLLocation *)location
{
    return [self location:location inRangeOf:self.targetA] ||
            [self location:location inRangeOf:self.targetB];
}

- (BOOL)location:(CLLocation *)location inRangeOf:(TargetLocation *)target
{
    CLLocation *targetLoc = [[CLLocation alloc] initWithLatitude:@(target.lat).doubleValue
                                                       longitude:@(target.lng).doubleValue];
    if ([location distanceFromLocation:targetLoc] < RADIUS_OF_DETECTION) {
        return YES;
    }
    return NO;
}

- (NSNumber *)aOrBResponseFromLocation:(CLLocation *)location {
    return [self location:location inRangeOf:self.targetA] ? @(YES) : @(NO);
}

- (TargetLocation *)getReachedTargetFromLocation:(CLLocation *)location {
    return [self location:location inRangeOf:self.targetA] ? self.targetA : self.targetB;
}

- (RACSignal *)foundLocationSignalWithJson:(NSDictionary *)json {
    self.json = json[@"json"];
    
    NSArray *targets = [json valueForKeyPath:kTargetKey];
    self.targetA = [[TargetLocation alloc] initWithDictionary:targets[0]];
    self.targetB = [[TargetLocation alloc] initWithDictionary:targets[1]];

    return [[[self updatedLocationSignal]
            filter:^BOOL(CLLocation *newLocation) {
                return [self locationInRange:newLocation];
            }]
            map:^id(CLLocation *newLocation) {
                return RACTuplePack(@([self reachedDestination]),
                                    [self fetchNextStorySignalFromLocation:newLocation],
                                    [self getReachedTargetFromLocation:newLocation]);
            }];
}

- (BOOL)reachedDestination
{
    return ((NSNumber *) self.json[@"clueCount"]).intValue >= LAST_CHAPTER;
}

- (RACSignal *)fetchNextStorySignalFromLocation:(CLLocation *)loc {
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] init];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    NSDictionary *params = @{@"lat":@(loc.coordinate.latitude),
                             @"lng":@(loc.coordinate.longitude),
                             @"a_or_b":[self aOrBResponseFromLocation:loc],
                             @"json":[self jsonToString:self.json]};
    return [manager rac_GET:STORY_URL parameters:params];
}

- (RACSignal *)fetchStorySignal {

    return [[[self updatedLocationSignal]
             take:1]
            flattenMap:^(CLLocation *loc) {
                AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] init];
                manager.responseSerializer = [AFJSONResponseSerializer serializer];
                NSDictionary *params = @{@"lat":@(loc.coordinate.latitude),
                                         @"lng":@(loc.coordinate.longitude)};
                return [manager rac_GET:STORY_URL parameters:params];
            }];
}

- (NSString *)jsonToString:(NSDictionary *)json
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}


# pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self.locationSubject sendNext:[locations lastObject]];
}



- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self.locationSubject sendError:error];

}



@end
