//
//  MapViewController.h
//  MySpot
//
//  Created by Iwaki Satoshi on 2015/10/14.
//  Copyright (c) 2015年 Satoshi Iwaki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>
#import <GoogleSignIn/GoogleSignIn.h>

#import "SignInViewController.h"

@interface MapViewController : SignInViewController <UISearchBarDelegate, CLLocationManagerDelegate, GMSMapViewDelegate>

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;

@end

