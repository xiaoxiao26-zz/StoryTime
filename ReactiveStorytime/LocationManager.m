//
//  LocationManager.m
//  ReactiveStorytime
//
//  Created by Alex Xiao on 4/16/15.
//  Copyright (c) 2015 Stever2Startup. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <AFNetworking-RACExtensions/RACAFNetworking.h>


#import "LocationManager.h"

@interface LocationManager() <CLLocationManagerDelegate>



@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) RACSubject *locationSubject;

@property (readwrite, nonatomic) int numberOfLocationSubscribers;



@end



@implementation LocationManager



+ (LocationManager*) sharedManager {
    
    static LocationManager *_locationManager;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        _locationManager = [[LocationManager alloc] init];
        
    });
    
    return _locationManager;
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
    return YES;
}

- (NSNumber *)foundDestination
{
    return @(NO);
}

- (RACSignal *)foundLocationSignalWithTargets:(NSDictionary *)targets {
    return [[[self updatedLocationSignal]
            filter:^BOOL(CLLocation *newLocation) {
                return [self locationInRange:newLocation];
            }]
            map:^id(CLLocation *newLocation) {
                return RACTuplePack([self foundDestination], [self fetchNextStorySignal]);
            }];
}

- (RACSignal *)fetchNextStorySignal {
    NSString *url = @"http://localhost:8080/story";
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] init];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    NSDictionary *params = @{@"lat":@"37.4292", @"lng":@"-122.13181"};
    return [manager rac_GET:url parameters:params];
    
}


# pragma mark - CLLocationManagerDelegate 



- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [self.locationSubject sendNext:newLocation];
}



- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self.locationSubject sendError:error];

}



@end
