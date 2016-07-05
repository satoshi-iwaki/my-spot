//
//  MapViewController.m
//  MySpot
//
//  Created by Iwaki Satoshi on 2015/10/14.
//  Copyright (c) 2015年 Satoshi Iwaki. All rights reserved.
//

#import "MapViewController.h"

#import <GoogleSignIn/GoogleSignIn.h>

#import "Constants.h"
#import "MarkerViewController.h"
#import "SignInViewController.h"

@import Firebase;

@interface MapViewController () {
    CLLocationManager *_locationManager;
    GMSPlacesClient *_placesClient;
    GMSMarker *_marker;
    NSMutableArray *_markers;
}

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"My Spot";
    
    _placesClient = [[GMSPlacesClient alloc] init];
    _markers = [NSMutableArray array];

    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    [_locationManager requestWhenInUseAuthorization];
    
    // Initialize Google Maps
    if (_locationManager.location) {
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:_locationManager.location.coordinate
                                                                   zoom:6];
        self.mapView.camera = camera;
    }
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = YES;
    
    [self loadMarkers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_placesClient currentPlaceWithCallback:^(GMSPlaceLikelihoodList *placeLikelihoodList, NSError *error) {
        if (error) {
            NSLog(@"Pick Place error %@", [error localizedDescription]);
            return;
        }
        
        if (placeLikelihoodList) {
            for (GMSPlaceLikelihood *likelihood in [placeLikelihoodList likelihoods]) {
                GMSPlace *place = likelihood.place;
                if (place) {
                    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:place.coordinate zoom:self.mapView.camera.zoom];
                    self.mapView.camera = camera;
                    
                    GMSMarker *marker = [[GMSMarker alloc] init];
                    marker.position = place.coordinate;
                    marker.title = place.name;
                    marker.snippet = [NSString stringWithFormat:@"%@, %@", place.website, place.phoneNumber];
                    marker.appearAnimation = kGMSMarkerAnimationPop;
                    marker.draggable = NO;
                    marker.map = self.mapView;
                }
            }
        }
    }];
}

#pragma mark CLLocationManager

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (0 < locations.count) {
        CLLocation *location = locations[0];
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:location.coordinate
                                                                   zoom:self.mapView.camera.zoom];
        self.mapView.camera = camera;
    }
}


#pragma mark GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:coordinate zoom:self.mapView.camera.zoom];
    self.mapView.camera = camera;
}

- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:coordinate zoom:self.mapView.camera.zoom];
    self.mapView.camera = camera;
    
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = camera.target;
    marker.title = [NSString stringWithFormat:@"%f, %f", marker.position.latitude, marker.position.longitude];
    marker.snippet = @"Hello World";
    marker.appearAnimation = kGMSMarkerAnimationPop;
    marker.draggable = YES;
    marker.map = self.mapView;
    
    _marker.map = nil;
    _marker = marker;
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker {
    MarkerViewController *viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MarkerViewController"];
    viewController.marker = marker;
    
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark Private Methods

- (IBAction)syncButtonClicked:(id)sender {
    
}

- (void)loadMarkers {

}

- (void)saveMarkers {
    FIRDatabaseReference *ref = [[FIRDatabase database] reference];

    for (GMSMarker *marker in _markers) {
        NSDictionary *JSONObject = @{@"title" : marker.title,
                                     @"snippet" : marker.snippet,
                                     @"position" : @{
                                             @"latitude" : @(marker.position.latitude),
                                             @"longitude" : @(marker.position.longitude),
                                             },
                                     };

        [[[ref child:@"markers"] childByAutoId] setValue:JSONObject];
        
    }
}

@end
