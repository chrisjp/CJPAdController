//
//  RootViewController.m
//  CJPAdControllerDemo
//
//  Created by Chris Phillips on 06/02/2015.
//  Copyright (c) 2015 Midnight Labs. All rights reserved.
//

#import "RootViewController.h"
#import "AnotherViewController.h"
#import "CJPAdController.h"

@interface RootViewController ()

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, strong) IBOutlet UIButton *btnPush;
@property (nonatomic, strong) IBOutlet UIButton *btnRemoveTemp;
@property (nonatomic, strong) IBOutlet UIButton *btnRemovePerm;
@property (nonatomic, strong) IBOutlet UIButton *btnRestore;

- (IBAction)removeAdsPermanently:(id)sender;
- (IBAction)removeAdsTemporarily:(id)sender;
- (IBAction)restoreAds:(id)sender;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"CJPAdController Demo";
    
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)removeAdsPermanently:(id)sender
{
    // In production, you might call this when someone makes an IAP to remove ads for example. In such a case, you'll want to set andRemember to NO so that it is remembered across future app launches.
    [[CJPAdController sharedInstance] removeAdsAndMakePermanent:YES andRemember:NO];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ads Removed" message:@"Ads will NOT show again until restored." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)removeAdsTemporarily:(id)sender
{
    [[CJPAdController sharedInstance] removeAds];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ads Removed" message:@"Ads will be hidden off-screen until the next ad request fires (usually within 1-5 minutes)." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)restoreAds:(id)sender
{
    // NOTE: restoreBanner's parameter can be left blank - if you're using multiple ad networks and have presumably removed any and all instances from your view before calling this, this will then create a new banner of your default ad type.
    [[CJPAdController sharedInstance] restartAds];
}

@end
