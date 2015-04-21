//
//  MapViewController.m
//  ReactiveStorytime
//
//  Created by Alex Xiao on 4/20/15.
//  Copyright (c) 2015 Stever2Startup. All rights reserved.
//

#import "MapViewController.h"
#import "StoryLocationManager.h"
#import <MapKit/MapKit.h>


@interface MapViewController () <MKMapViewDelegate>


@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation MapViewController

CLLocationDistance const LAT_RADIUS = 5000;
CLLocationDistance const LON_RADIUS = 5000;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateAnnotations];
    self.title = self.target.name;

    [[[[[StoryLocationManager sharedManager] updatedLocationSignal] replayLast] take:1]
    subscribeNext:^(CLLocation *loc) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc.coordinate, LAT_RADIUS, LON_RADIUS);
        [self.mapView setRegion:region animated:NO];
    }];
    
}

- (void)updateAnnotations
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotation:self.target];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
         
    MKPinAnnotationView *pinView = [[MKPinAnnotationView alloc] init];
    pinView.annotation = annotation;
    pinView.pinColor = MKPinAnnotationColorGreen;
    pinView.animatesDrop = YES;
    pinView.canShowCallout = YES;
    return pinView;
}

- (void)mapView:(MKMapView *)aMapView didUpdateUserLocation:(MKUserLocation *)aUserLocation {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(aUserLocation.coordinate, LAT_RADIUS, LON_RADIUS);
    [self.mapView setRegion:region animated:YES];
}


@end
