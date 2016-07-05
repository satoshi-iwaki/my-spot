//
//  AmazonClientManager.h
//  MySpot
//
//  Created by Iwaki Satoshi on 2015/10/20.
//  Copyright (c) 2015年 Satoshi Iwaki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSCore/AWSCore.h>
//#import <GooglePlus/GooglePlus.h>
//#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GoogleSignIn/GoogleSignIn.h>

@class AWSCognitoCredentialsProvider;
@class AWSCognito;
@class BFTask;

@interface AmazonClientManager : NSObject <GIDSignInDelegate>

- (BOOL)isConfigured;
- (BOOL)isLoggedIn;
- (void)logoutWithCompletionHandler:(BFContinuationBlock)completionHandler;
- (void)loginFromView:(UIView *)theView withCompletionHandler:(BFContinuationBlock)completionHandler;

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

- (void)resumeSessionWithCompletionHandler:(BFContinuationBlock)completionHandler;

+ (AmazonClientManager *)sharedInstance;

@end