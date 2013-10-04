//
//  RootViewController.m
//  CJPAdControllerDemo
//
//  Created by Chris Phillips on 06/04/2012.
//  Copyright (c) 2012 ChrisJP. All rights reserved.
//

#import "RootViewController.h"
#import "CJPAdController.h"
#import "AnotherExample.h"

@interface RootViewController ()

@end

@implementation RootViewController

@synthesize scrollView = _scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.title = @"CJPAdController Demo";
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    // Let's put everything in a ScrollView
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:self.scrollView];
    
    // TextView describing basic functionality
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 320)];
    textView.text = @"After a couple of seconds you should see ads appear at the bottom of this view.\nYou can rotate your device any way you want; the ad will automatically resize and/or reposition itself.\n\nTap the button below to push another view. You'll notice the ad remains in position across views as advised by Apple.";
    textView.autoresizingMask =  UIViewAutoresizingFlexibleWidth;
    textView.backgroundColor = [UIColor clearColor];
    textView.editable = NO;
    textView.scrollEnabled = NO;
    textView.font = [UIFont systemFontOfSize:16.0];
    textView.textColor = [UIColor darkTextColor];
    [self.scrollView addSubview:textView];
    CGRect textFrame = textView.frame;
    textFrame.size.height = textView.contentSize.height;
    textView.frame = textFrame;
    
    // Button to push another view
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(0, textView.frame.size.height+10, 200, 40);
    button.center = CGPointMake(self.view.frame.size.width/2, button.center.y);
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [button setTitle:@"Push Another View" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(anotherExample) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:button];
    if ([self.parentViewController.parentViewController isKindOfClass:[UITabBarController class]]) button.hidden = YES;
    
    // Button to remove ads temporarily
    UIButton *buttonRAT = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    buttonRAT.frame = CGRectMake(0, button.frame.origin.y+button.frame.size.height+10, 200, 40);
    buttonRAT.center = CGPointMake(self.view.frame.size.width/2, buttonRAT.center.y);
    buttonRAT.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [buttonRAT setTitle:@"Remove Ads Temporarily" forState:UIControlStateNormal];
    [buttonRAT addTarget:self action:@selector(removeAdsTemporarily) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:buttonRAT];
    
    // Button to remove ads permanently
    UIButton *buttonRAP = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    buttonRAP.frame = CGRectMake(0, buttonRAT.frame.origin.y+buttonRAT.frame.size.height+10, 200, 40);
    buttonRAP.center = CGPointMake(self.view.frame.size.width/2, buttonRAP.center.y);
    buttonRAP.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [buttonRAP setTitle:@"Remove Ads Permanently" forState:UIControlStateNormal];
    [buttonRAP addTarget:self action:@selector(removeAdsPermanently) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:buttonRAP];
    
    // Button to restore ad
    UIButton *buttonRestore = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    buttonRestore.frame = CGRectMake(0, buttonRAP.frame.origin.y+buttonRAP.frame.size.height+10, 200, 40);
    buttonRestore.center = CGPointMake(self.view.frame.size.width/2, buttonRestore.center.y);
    buttonRestore.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [buttonRestore setTitle:@"Restore Ads" forState:UIControlStateNormal];
    [buttonRestore addTarget:self action:@selector(restoreAds) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:buttonRestore];
    
    // Set scrollview content size
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, buttonRestore.frame.size.height+buttonRestore.frame.origin.y+10);
}

- (void)anotherExample
{
    AnotherExample *example = [[AnotherExample alloc] init];
    [self.navigationController pushViewController:example animated:YES];
}

- (void)removeAdsPermanently
{
    [[CJPAdController sharedManager] removeBanner:@"iAd" permanently:YES];
    [[CJPAdController sharedManager] removeBanner:@"AdMob" permanently:YES];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ads Removed" message:@"Ads will NOT show again until restored." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    
    // Or if this was from an in-app purchase, you could simply call the following
    // which would save a boolean in UserDefaults so the app remembers not to create ads
    // next time it starts up.
    //[[CJPAdController sharedManager] removeAllAdsForever];
}

- (void)removeAdsTemporarily
{
    [[CJPAdController sharedManager] removeBanner:@"iAd" permanently:NO];
    [[CJPAdController sharedManager] removeBanner:@"AdMob" permanently:NO];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ads Removed" message:@"Ads will be hidden off-screen until the next ad request fires (usually within 1-5 minutes)." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (void)restoreAds
{
    // NOTE: restoreBanner's parameter can be left blank - if you're using multiple ad networks and have presumably removed any and all instances from your view before calling this, this will then create a new banner of your default ad type.
    [[CJPAdController sharedManager] restoreBanner:@""];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
