//
//  SignInViewController.h
//  MySpot
//
//  Created by Iwaki Satoshi on 2015/11/25.
//  Copyright © 2015年 Satoshi Iwaki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleSignIn/GoogleSignIn.h>

@interface SignInViewController : UIViewController <GIDSignInUIDelegate>

//@property (weak, nonatomic) IBOutlet GIDSignInButton *signInButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *signInButton;

@end
