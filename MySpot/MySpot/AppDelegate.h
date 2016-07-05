//
//  AppDelegate.h
//  MySpot
//
//  Created by Iwaki Satoshi on 2015/10/14.
//  Copyright (c) 2015年 Satoshi Iwaki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleSignIn/GoogleSignIn.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, GIDSignInDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

