//
//  SignInViewController.m
//  MySpot
//
//  Created by Iwaki Satoshi on 2015/11/25.
//  Copyright © 2015年 Satoshi Iwaki. All rights reserved.
//

#import "SignInViewController.h"
#import "Constants.h"

@import Firebase;

@interface SignInViewController ()

@end

@implementation SignInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Sign In";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeSignInStatusNotification:)
                                                 name:MyMapDidChangeSignInStatusNotification object:nil];
    
    GIDSignIn *signIn = [GIDSignIn sharedInstance];
    signIn.uiDelegate = self;
    
    [[FIRAuth auth] addAuthStateDidChangeListener:^(FIRAuth * _Nonnull auth, FIRUser * _Nullable user) {
        if (user) {
            // User is signed in.
        } else {
            // No user is signed in.
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateSignInStatus];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark GIDSignInUIDelegate

// The sign-in flow has finished selecting how to proceed, and the UI should no longer display
// a spinner or other "please wait" element.
- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error {
    // [myActivityIndicator stopAnimating];
    if (error) {
        UIAlertController *viewController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                message:[error localizedDescription]
                                                                         preferredStyle:UIAlertControllerStyleAlert];
        [viewController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil]];
        [self presentViewController:viewController animated:YES completion:nil];
        return;
    }
}

// If implemented, this method will be invoked when sign in needs to display a view controller.
// The view controller should be displayed modally (via UIViewController's |presentViewController|
// method, and not pushed unto a navigation controller's stack.
- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
}

// If implemented, this method will be invoked when sign in needs to dismiss a view controller.
// Typically, this should be implemented by calling |dismissViewController| on the passed
// view controller.
- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark Private Methods

- (IBAction)signInButtonClicked:(id)sender {
    GIDSignIn *signIn = [GIDSignIn sharedInstance];
    if ([signIn hasAuthInKeychain]) {
        [signIn signOut];
        [self updateSignInStatus];
    } else {
        [signIn signIn];
    }
}

- (void)updateSignInStatus {
    GIDSignIn *signIn = [GIDSignIn sharedInstance];
    if ([signIn hasAuthInKeychain]) {
        self.signInButton.title = @"Sign out";
    } else {
        self.signInButton.title = @"Sign In";
    }
}

- (void)didChangeSignInStatusNotification:(NSNotification *)notification {
    [self updateSignInStatus];
}

@end
