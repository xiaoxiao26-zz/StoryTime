//
//  LocationManager.m
//  ReactiveStorytime
//
//  Created by Alex Xiao on 4/16/15.
//  Copyright (c) 2015 Stever2Startup. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>


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
    
    
    
    self.locationSubject = [RACSubject subject];
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;
    
    
    
    return self;
}



- (RACSignal *)foundLocationSignal {
    
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

# pragma mark - CLLocationManagerDelegate 



- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [self.locationSubject sendNext:newLocation];
}



- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self.locationSubject sendError:error];

}



@end
