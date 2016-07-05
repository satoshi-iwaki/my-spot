//
//  MarkerViewController.h
//  MySpot
//
//  Created by Iwaki Satoshi on 2015/11/20.
//  Copyright © 2015年 Satoshi Iwaki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>

@interface MarkerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) GMSMarker *marker;

@end
