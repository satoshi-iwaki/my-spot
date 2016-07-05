//
//  AppDelegate.m
//  MySpot
//
//  Created by Iwaki Satoshi on 2015/10/14.
//  Copyright (c) 2015年 Satoshi Iwaki. All rights reserved.
//

#import "AppDelegate.h"

#import <Google/Core.h>
#import <GoogleMaps/GoogleMaps.h>
#import <GoogleSignIn/GoogleSignIn.h>

#import "Constants.h"

@import Firebase;

@interface AppDelegate ()
{
}

@end

@implementation AppDelegate

#pragma mark Application Life Cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Initialize Google Maps
    NSAssert([GMSServices provideAPIKey:kGoogleMapsApiKey], @"Error configuring Google Maps API key is invalid");

    // Initialize Google Sign-In
    GIDSignIn *signIn = [GIDSignIn sharedInstance];
    signIn.delegate = self;
    signIn.clientID = kGoogleClientID;
    if ([signIn hasAuthInKeychain]) {
        [signIn signInSilently];
    }
    
    // Initialize Firebase
    [FIRApp configure];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark URL Scheme Handler

// iOS 8
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:sourceApplication
                                      annotation:annotation];
}

// iOS 9 and later
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options {
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                      annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

#pragma mark Push Notification

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:deviceToken forKey:kDeviceTokenKey];
    [userDefaults synchronize];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Error in registering for remote notifications. Error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
}

#pragma mark GIDSignInDelegate

// The sign-in flow has finished and was successful if |error| is |nil|.
- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    if (error) {
        NSLog(@"Error :%@", error.localizedDescription);
        UIAlertController *viewController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                message:[error localizedDescription]
                                                                         preferredStyle:UIAlertControllerStyleAlert];
        [viewController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil]];
        [self.window.rootViewController presentViewController:viewController animated:YES completion:nil];
        return;
    }
    NSLog(@"Did SignIn");
    [self printGoogleUser:user];
    [self didSignInForGoogleUser:user];
}


// Finished disconnecting |user| from the app successfully if |error| is |nil|.
- (void)signIn:(GIDSignIn *)signIn didDisconnectWithUser:(GIDGoogleUser *)user withError:(NSError *)error {
    NSLog(@"Did Disconnect");
    if (error) {
        UIAlertController *viewController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                message:[error localizedDescription]
                                                                         preferredStyle:UIAlertControllerStyleAlert];
        [viewController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil]];
        [self.window.rootViewController presentViewController:viewController animated:YES completion:nil];
        return;
    }
    [self printGoogleUser:user];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MyMapDidChangeSignInStatusNotification
                                                        object:user
                                                      userInfo:nil];
}

- (void)didSignInForGoogleUser:(GIDGoogleUser *)user {
    if (!user || !user.authentication || !user.authentication.idToken || !user.authentication.accessToken) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MyMapDidChangeSignInStatusNotification
                                                        object:user
                                                      userInfo:nil];

    
    FIRAuthCredential *credential = [FIRGoogleAuthProvider credentialWithIDToken:user.authentication.idToken
                                                                     accessToken:user.authentication.accessToken];
    [[FIRAuth auth] signInWithCredential:credential completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error :%@", error.localizedDescription);
        }
    }];
}

- (void)printGoogleUser:(GIDGoogleUser *)user {
    NSLog(@"User");
    NSLog(@"User > User ID :%@", user.userID);
    NSLog(@"User > Profile > Email :%@", user.profile.email);
    NSLog(@"User > Profile > Name :%@", user.profile.name);
    NSLog(@"User > Authentication > Cleint ID :%@", user.authentication.clientID);
    NSLog(@"User > Authentication > Access Token :%@", user.authentication.accessToken);
    NSLog(@"User > Authentication > Access Token Expiration Date :%@", user.authentication.accessTokenExpirationDate);
    NSLog(@"User > Authentication > OpenID Connect ID Token :%@", user.authentication.idToken);
    NSLog(@"User > Server Auth Code:%@", user.serverAuthCode);
}

@end
