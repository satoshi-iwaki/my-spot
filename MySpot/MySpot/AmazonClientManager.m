//
//  AmazonClientManager.m
//  MySpot
//
//  Created by Iwaki Satoshi on 2015/10/20.
//  Copyright (c) 2015年 Satoshi Iwaki. All rights reserved.
//

#import "AmazonClientManager.h"

//#import <GoogleUtilities/GoogleUtilites.h>

#import "AWSCredentialsProvider.h"
#import "AWSLogging.h"
#import "Constants.h"
#import "BFTask.h"
#import "UICKeyChainStore.h"
#import <AWSCognito/AWSCognito.h>
#import "DeveloperAuthenticatedIdentityProvider.h"
#import "DeveloperAuthenticationClient.h"

#define FB_PROVIDER             @"Facebook"
#define GOOGLE_PROVIDER         @"Google"
#define AMZN_PROVIDER           @"Amazon"
#define TWITTER_PROVIDER        @"Twitter"
#define DIGITS_PROVIDER         @"Digits"
#define BYOI_PROVIDER           @"DeveloperAuth"

@interface AmazonClientManager()

@property (nonatomic, strong) AWSCognitoCredentialsProvider *credentialsProvider;
@property (atomic, copy) BFContinuationBlock completionHandler;
@property (nonatomic, strong) UICKeyChainStore *keychain;
@property (nonatomic, strong) DeveloperAuthenticationClient *devAuthClient;

@property (strong, nonatomic) GTMOAuth2Authentication *googleAuth;

@end

@implementation AmazonClientManager

+ (AmazonClientManager *)sharedInstance
{
    static AmazonClientManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [AmazonClientManager new];
        sharedInstance.keychain = [UICKeyChainStore keyChainStoreWithService:[NSString stringWithFormat:@"%@.%@", [NSBundle mainBundle].bundleIdentifier, [AmazonClientManager class]]];
        sharedInstance.devAuthClient = [[DeveloperAuthenticationClient alloc] initWithAppname:DeveloperAuthAppName endpoint:DeveloperAuthEndpoint];
    });
    return sharedInstance;
}

- (BOOL)isConfigured {
    return !([CognitoIdentityPoolId isEqualToString:@"YourCognitoIdentityPoolId"] || CognitoRegionType == AWSRegionUnknown);
}

- (BOOL)isLoggedInWithGoogle {
    BOOL loggedIn = NO;
#if GOOGLE_LOGIN
    loggedIn = self.googleAuth != nil;
#endif
    return self.keychain[GOOGLE_PROVIDER] != nil && loggedIn;
}

- (BOOL)isLoggedIn
{
    return [self isLoggedInWithGoogle];
}

- (BFTask *)initializeClients:(NSDictionary *)logins {
    NSLog(@"initializing clients...");
    [AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
    
    id<AWSCognitoIdentityProvider> identityProvider = [[DeveloperAuthenticatedIdentityProvider alloc] initWithRegionType:CognitoRegionType
                                                                                                              identityId:nil
                                                                                                          identityPoolId:CognitoIdentityPoolId
                                                                                                                  logins:logins
                                                                                                            providerName:DeveloperAuthProviderName
                                                                                                              authClient:self.devAuthClient];
    
    self.credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:CognitoRegionType
                                                                        identityProvider:identityProvider
                                                                           unauthRoleArn:nil
                                                                             authRoleArn:nil];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:CognitoRegionType
                                                                         credentialsProvider:self.credentialsProvider];
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
    return [self.credentialsProvider getIdentityId];
}

- (void)wipeAll
{
    self.credentialsProvider.logins = nil;
    
    [[AWSCognito defaultCognito] wipe];
    [self.credentialsProvider clearKeychain];
}

- (void)logoutWithCompletionHandler:(BFContinuationBlock)completionHandler
{
    if ([self isLoggedInWithGoogle]) {
        [self GoogleLogout];
    }
    [self.devAuthClient logout];
    
    [self wipeAll];
    [[BFTask taskWithResult:nil] continueWithBlock:completionHandler];
}


- (void)loginFromView:(UIView *)theView withCompletionHandler:(BFContinuationBlock)completionHandler
{
    self.completionHandler = completionHandler;
    [[AmazonClientManager loginSheet] showInView:theView];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    // Handle Google+ sign-in button URL.
    if ([GIDURLHandler handleURL:url
               sourceApplication:sourceApplication
                      annotation:annotation]) {
        return YES;
    }
    return NO;
}

- (void)resumeSessionWithCompletionHandler:(BFContinuationBlock)completionHandler
{
    self.completionHandler = completionHandler;
    
    if (self.keychain[GOOGLE_PROVIDER]) {
        [self reloadGSession];
    }

    if (self.credentialsProvider == nil) {
        [self completeLogin:nil];
    }
}

- (void)completeLogin:(NSDictionary *)logins {
    BFTask *task;
    if (self.credentialsProvider == nil) {
        task = [self initializeClients:logins];
    }
    else {
        NSMutableDictionary *merge = [NSMutableDictionary dictionaryWithDictionary:self.credentialsProvider.logins];
        [merge addEntriesFromDictionary:logins];
        self.credentialsProvider.logins = merge;
        // Force a refresh of credentials to see if we need to merge
        task = [self.credentialsProvider refresh];
    }
    
    [[task continueWithBlock:^id(BFTask *task) {
        if(!task.error){
            //if we have a new device token register it
            __block NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            __block NSData *currentDeviceToken = [userDefaults objectForKey:DeviceTokenKey];
            __block NSString *currentDeviceTokenString = (currentDeviceToken == nil)? nil : [currentDeviceToken base64EncodedStringWithOptions:0];
            if(currentDeviceToken != nil && ![currentDeviceTokenString isEqualToString:[userDefaults stringForKey:CognitoDeviceTokenKey]]){
                [[[AWSCognito defaultCognito] registerDevice:currentDeviceToken] continueWithBlock:^id(BFTask *task) {
                    if(!task.error){
                        [userDefaults setObject:currentDeviceTokenString forKey:CognitoDeviceTokenKey];
                        [userDefaults synchronize];
                    }
                    return nil;
                }];
            }
        }
        return task;
    }] continueWithBlock:self.completionHandler];
}

#pragma mark - UI Helpers

+ (UIActionSheet *)loginSheet
{
    return [[UIActionSheet alloc] initWithTitle:@"Choose Identity Provider"
                                       delegate:[AmazonClientManager sharedInstance]
                              cancelButtonTitle:@"Cancel"
                         destructiveButtonTitle:nil
                              otherButtonTitles:FB_PROVIDER, GOOGLE_PROVIDER, AMZN_PROVIDER, TWITTER_PROVIDER, DIGITS_PROVIDER, BYOI_PROVIDER, nil];
}

+ (UIAlertView *)errorAlert:(NSString *)message
{
    return [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"Cancel"]) {
        [[BFTask taskWithResult:nil] continueWithBlock:self.completionHandler];
        return;
    }
    else if ([buttonTitle isEqualToString:BYOI_PROVIDER]) {
        [self BYOILogin];
    }

    else if ([buttonTitle isEqualToString:GOOGLE_PROVIDER]) {
        [self GoogleLogin];
    }
    else {
        [[AmazonClientManager errorAlert:@"Provider not implemented"] show];
        [[BFTask taskWithResult:nil] continueWithBlock:self.completionHandler];
    }
}

#pragma mark - BYOI
- (void)reloadBYOISession {
    [self completeLogin:@{DeveloperAuthProviderName: self.keychain[BYOI_PROVIDER]}];
}

- (void)BYOILogin
{
    UIAlertView *loginView = [[UIAlertView alloc] initWithTitle:@"Enter Credentials" message:nil delegate:self cancelButtonTitle:@"Login" otherButtonTitles:nil];
    loginView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [loginView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *username = [alertView textFieldAtIndex:0].text;
    NSString *password = [alertView textFieldAtIndex:1].text;
    if ([username length] == 0 || [password length] == 0) {
        username = nil;
        password = nil;
    }
    
    if (username && password) {
        [[self.devAuthClient login:username password:password] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
            if (task.cancelled) {
                [[AmazonClientManager errorAlert:@"Login canceled."] show];
            }
            else if (task.error) {
                [[AmazonClientManager errorAlert:@"Login failed. Check your username and password."] show];
                [[BFTask taskWithError:task.error] continueWithBlock:self.completionHandler];
            }
            else {
                self.keychain[BYOI_PROVIDER] = username;
                [self completeLogin:@{DeveloperAuthProviderName: username}];
            }
            return nil;
        }];
    }
    else {
        [[BFTask taskWithResult:nil] continueWithBlock:self.completionHandler];
    }
}

#pragma mark - Google
- (GIDSignIn *)getGPlusLogin
{
    GIDSignIn *signIn = [GIDSignIn sharedInstance];
    signIn.delegate = self;
    signIn.clientID = GoogleClientID;
    signIn.scopes = [NSArray arrayWithObjects:GoogleClientScope, GoogleOIDCScope, nil];
    return signIn;
}

- (void)GoogleLogin
{
    GIDSignIn *signIn = [self getGPlusLogin];
    [signIn authenticate];
}

- (void)GoogleLogout
{
    GIDSignIn *signIn = [self getGPlusLogin];
    [signIn disconnect];
    self.googleAuth = nil;
    self.keychain[GOOGLE_PROVIDER] = nil;
}

- (void)reloadGSession
{
    GIDSignIn *signIn = [self getGPlusLogin];
    [signIn trySilentAuthentication];
}

- (void)finishedWithAuth: (GTMOAuth2Authentication *)auth
                   error: (NSError *) error
{
    if (self.auth == nil) {
        self.googleAuth = auth;
        
        if (error != nil) {
            [[AmazonClientManager errorAlert:[NSString stringWithFormat:@"Error logging in with Google: %@", error.description]] show];
        }
        else {
            [self CompleteGLogin];
        }
    }
}

-(void)CompleteGLogin
{
    NSString *idToken = [self.googleAuth.parameters objectForKey:@"id_token"];
    
    self.keychain[GOOGLE_PROVIDER] = @"YES";
    [self completeLogin:@{@"accounts.google.com": idToken}];
}

@end
