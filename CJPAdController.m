//
//  CJPAdController.m
//  ChrisJP
//
//  Created by Chris Phillips on 19/11/2011.
//  Copyright (c) 2011 ChrisJP. All rights reserved.
//

#import "CJPAdController.h"

static CJPAdController *CJPSharedManager = nil;

@implementation CJPAdController

@synthesize iAdView              = _iAdView;
@synthesize adMobView            = _adMobView;
@synthesize containerView        = _containerView;
@synthesize parentView           = _parentView;
@synthesize parentViewController = _parentViewController;
@synthesize previousView         = _previousView;
@synthesize showingiAd           = _showingiAd;
@synthesize showingAdMob         = _showingAdMob;
@synthesize adsRemoved           = _adsRemoved;

#pragma mark -
#pragma mark Class Methods

+ (CJPAdController *)sharedManager
{
    @synchronized(self) {
        if (CJPSharedManager == nil){
            CJPSharedManager = [[self alloc] init];
        }
    }
    return CJPSharedManager;
}

- (id)init
{
    if (self = [super init]) {
        self.iAdView = nil;
        self.adMobView = nil;
        self.containerView = nil;
        self.parentView = nil;
        self.parentViewController = nil;
        self.previousView = nil;
        self.adsRemoved = [[NSUserDefaults standardUserDefaults] boolForKey:kAdsPurchasedKey];
        self.showingiAd = NO;
        self.showingAdMob = NO;
    }
    return self;
}

#pragma mark -
#pragma mark Ad Methods

- (void)addBannerToViewController:(UIViewController *)viewController
{    
    if(!self.adsRemoved){
        self.parentViewController = viewController;
        
        // Loop through subviews and check if we already have adviews created here
        // If we do, give it back to iAdView and/or adMobView
        BOOL alreadyHaveiAd = NO;
        BOOL alreadyHaveAdMob = NO;
        for (int i=0; i<viewController.view.subviews.count; i++) {
            if([[viewController.view.subviews objectAtIndex:i] isKindOfClass:[ADBannerView class]]){
                self.iAdView = [viewController.view.subviews objectAtIndex:i];
                alreadyHaveiAd=YES;
            }
            if([[viewController.view.subviews objectAtIndex:i] isKindOfClass:[GADBannerView class]]){
                self.adMobView = [viewController.view.subviews objectAtIndex:i];
                alreadyHaveAdMob=YES;
            }
        }
        
        if(self.previousView == self.containerView){
            // We've gone back to the previous view, set these variables to NO
            // so that our rotation/fix methods are definitely called
            // (if they are YES the rotation methods will assume they're already on screen and won't adjust the view)
            self.showingiAd=NO;
            self.showingAdMob=NO;
        }
        
        // If we already have our container set up, all we need to do is make sure the ad is in the correct orientation
        if (alreadyHaveiAd || alreadyHaveAdMob) {
            if(kAdTesting) NSLog(@"Container view already exists. Fixing current ad view's orientation and size");
            self.containerView = viewController.view;
            self.parentView = [viewController.view.subviews objectAtIndex:0];
            if (alreadyHaveiAd){
                if(kAdTesting) NSLog(@"iAd already exists in this view.");
                self.showingiAd=YES;
            }
            if (alreadyHaveAdMob){
                if(kAdTesting) NSLog(@"AdMob already exists in this view.");
                self.showingAdMob=YES;
            }
            [self rotateAdToInterfaceOrientation:viewController.interfaceOrientation];
            [self fixAdViewAfterRotation];
        }
        // Otherwise we'll set up our container and request an ad
        else{
            if(kAdTesting) NSLog(@"Creating container view to hold parent view and banner view.");
            self.parentView = viewController.view;
            self.iAdView=nil;
            self.adMobView=nil;
            
            // Create a container view to hold both our parent view and the banner view
            self.containerView = [[UIView alloc] initWithFrame:viewController.view.frame];
            self.containerView.backgroundColor = self.parentView.backgroundColor;
            self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
            // add the parent view as a subview
            [self.containerView addSubview:viewController.view];
            // Set the active view to be this new container we've created
            self.parentViewController.view = self.containerView;
            
            [self performSelector:@selector(createBanner:) withObject:kDefaultAds afterDelay:kWaitTime];
        }
        self.previousView = viewController.view;
    }
}

- (void)createBanner:(NSString *)adType
{
    
    BOOL inPortrait = UIInterfaceOrientationIsPortrait(self.parentViewController.interfaceOrientation);
    BOOL isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO;
    
    if(kAdTesting) NSLog(@"Creating %@", adType);
    
    // Create iAd
    if([adType isEqualToString:@"iAd"]){
        self.iAdView = [[ADBannerView alloc] initWithFrame:CGRectZero];
        
        self.iAdView.requiredContentSizeIdentifiers = [NSSet setWithObjects:ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil];
        
        if (!inPortrait) self.iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
        else self.iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
        
        // Set initial frame to be offscreen
        CGRect bannerFrame = self.iAdView.frame;
        bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        self.iAdView.backgroundColor = [UIColor clearColor];
        self.iAdView.frame = bannerFrame;
        self.iAdView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        self.iAdView.delegate = self;
        [self.containerView addSubview:self.iAdView];
        if(kAdTesting) NSLog(@"%@ added to view.", adType);
    }
    
    // Create AdMob
    else if([adType isEqualToString:@"AdMob"]){
        // Create a view of the standard size at the bottom of the screen.
        
        if (kUseAdMobSmartSize) {
            GADAdSize adMobSize;
            if (!inPortrait) adMobSize = kGADAdSizeSmartBannerLandscape;
            else adMobSize = kGADAdSizeSmartBannerPortrait;
            self.adMobView = [[GADBannerView alloc] initWithAdSize:adMobSize];
        }else{
            // Legacy AdMob ad sizes don't fill the full width of the device screen apart from iPhone when in portrait view
            // We need to offset the x position so the ad appears centered - Calculation: (View width - Ad width) / 2
            // Problem is that getting the width of the bounds doesn't take into account the current orientation
            // As a workaround, if we're in landscape, we'll simply get the height instead
            CGRect screen = [[UIScreen mainScreen] bounds];
            CGFloat screenWidth = inPortrait ? CGRectGetWidth(screen) : CGRectGetHeight(screen);
            GADAdSize adMobSize = isIPad ? kGADAdSizeLeaderboard : kGADAdSizeBanner;
            CGSize cgAdMobSize = CGSizeFromGADAdSize(adMobSize);
            CGFloat adMobXOffset = (screenWidth-cgAdMobSize.width)/2;
            self.adMobView = [[GADBannerView alloc] initWithFrame:CGRectMake(adMobXOffset, self.parentViewController.view.frame.size.height - cgAdMobSize.height, cgAdMobSize.width, cgAdMobSize.height)];
        }
        
        // Specify the ad's "unit identifier." This is your AdMob Publisher ID.
        self.adMobView.adUnitID = kAdMobID;
        
        // Set initial frame to be off screen
        CGRect bannerFrame = self.adMobView.frame;
        bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        self.adMobView.backgroundColor = [UIColor clearColor];
        self.adMobView.frame = bannerFrame;
        self.adMobView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        // Let the runtime know which UIViewController to restore after taking
        // the user wherever the ad goes and add it to the view hierarchy.
        self.adMobView.rootViewController = self.parentViewController;
        self.adMobView.delegate = self;
        [self.containerView addSubview:self.adMobView];
        if(kAdTesting) NSLog(@"%@ added to view.", adType);
        
        // Request an ad
        GADRequest *adMobRequest = [GADRequest request];
        // Uncomment the following line if you wish to receive test ads (simulator only)
        //adMobRequest.testing = YES;
        [self.adMobView loadRequest:adMobRequest];
    }
}

- (void)removeBanner:(NSString *)adType permanently:(BOOL)permanent
{
    // Hides the banner from view
    // If permanent is set to YES we'll additionally set its view to nil and remove it from superview
    
    // Hide the ad
    [self resizeViewForAdType:adType showOrHide:@"hide" afterRotation:NO];
    
    // iAd
    if ([adType isEqualToString:@"iAd"] && permanent) {
        self.iAdView.delegate = nil;
        self.iAdView = nil;
        [self.iAdView removeFromSuperview];
    }
    
    // AdMob
    if ([adType isEqualToString:@"AdMob"] && permanent) {
        self.adMobView.delegate = nil;
        self.adMobView = nil;
        [self.adMobView removeFromSuperview];
    }
}

- (void)resizeViewForAdType:(NSString *)adType showOrHide:(NSString *)showHide afterRotation:(BOOL)isAfterRotation
{
    // We always need to resize the view if handling a rotation
    if (!isAfterRotation && ((self.showingiAd && [adType isEqualToString:@"iAd"]) || (self.showingAdMob && [adType isEqualToString:@"AdMob"])) && [showHide isEqualToString:@"show"]) {
        if(kAdTesting) NSLog(@"already showing %@ in this orientation, nothing to do.", adType);
    }
    else {
        if(kAdTesting) NSLog(@"resizing view to %@ %@", showHide, adType);
        
        CGRect bannerFrame;
        if([adType isEqualToString:@"iAd"]) bannerFrame = self.iAdView.frame;
        else if([adType isEqualToString:@"AdMob"]) bannerFrame = self.adMobView.frame;
                
        CGRect parentFrame = self.parentView.frame;
        // If we're bringing a banner on screen...
        if ([showHide isEqualToString:@"show"]) {
            // If the banner is off screen let's move it on
            // Also reduce the height of parentView so it's contents don't go behind the ad view
            CGFloat adHeight = bannerFrame.size.height;
            if([adType isEqualToString:@"AdMob"]) adHeight = CGSizeFromGADAdSize(self.adMobView.adSize).height;
            bannerFrame.origin.y = self.containerView.frame.size.height-adHeight;   // make sure ad is at the bottom of the view
            parentFrame.size.height = self.containerView.frame.size.height - adHeight;
            self.parentView.frame = parentFrame;
            
            if([adType isEqualToString:@"iAd"]){
                self.adMobView.hidden = YES;
                self.iAdView.hidden = NO;
                bannerFrame.origin.x = 0; // fixes a bug in iOS 6
                self.iAdView.frame = bannerFrame;
            }
            else if([adType isEqualToString:@"AdMob"]){
                self.iAdView.hidden = YES;
                self.adMobView.hidden = NO;
                if(kUseAdMobSmartSize) bannerFrame.origin.x = 0; // fixes a bug in iOS 6
                self.adMobView.frame = bannerFrame;
            }
        }
        // Or if we're pushing a banner off screen to hide it
        else {
            // Set the parentView's frame to take up the whole container
            parentFrame.size.height = self.containerView.frame.size.height;
            self.parentView.frame = parentFrame;
            
            // Set the y origin of the bannerFrame to the fullViewHeight
            // This causes it to be pushed down just below the screen bounds
            bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
            if([adType isEqualToString:@"iAd"]){
                self.iAdView.hidden = YES;
                self.iAdView.frame = bannerFrame;
            }
            else if([adType isEqualToString:@"AdMob"]){
                self.adMobView.hidden = YES;
                self.adMobView.frame = bannerFrame;
            }
        }
    }
}

- (void)rotateAdToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    // Resize the view depending on which ad type is currently being displayed
    if(!self.adsRemoved){
        BOOL toPortrait = UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
        BOOL isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO;
        
        if(kAdTesting && toPortrait) NSLog(@"Device being rotated. Changing ad orientation to portrait.");
        else if(kAdTesting && !toPortrait) NSLog(@"Device being rotated. Changing ad orientation to landscape.");
        
        // If we've got an iAd
        if (self.iAdView != nil) {
            if (toPortrait) self.iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
            else self.iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
        }
        
        // And if we've got an AdMob
        if (self.adMobView != nil){
            if (kUseAdMobSmartSize) {
                if (toPortrait) self.adMobView.adSize = kGADAdSizeSmartBannerPortrait;
                else self.adMobView.adSize = kGADAdSizeSmartBannerLandscape;
            }
            else{
                // Legacy AdMob doesn't have different orientation sizes - we just need to change the X offset so the ad remains centered
                CGRect bannerFrame = self.adMobView.frame;
                CGRect screen = [[UIScreen mainScreen] bounds];
                CGFloat screenWidth = toPortrait ? CGRectGetWidth(screen) : CGRectGetHeight(screen);
                GADAdSize adMobSize = isIPad ? kGADAdSizeLeaderboard : kGADAdSizeBanner;
                CGSize cgAdMobSize = CGSizeFromGADAdSize(adMobSize);
                CGFloat adMobXOffset = (screenWidth-cgAdMobSize.width)/2;
                bannerFrame.origin.x = adMobXOffset;
                self.adMobView.frame = bannerFrame;
            }
        }
    }
}

- (void)fixAdViewAfterRotation
{
    if(!self.adsRemoved){
        // Resize the view depending on which ad type is currently being displayed
        if (self.showingiAd) {
            if(kAdTesting) NSLog(@"Device rotated. Resizing view for iAd.");
            [self resizeViewForAdType:@"iAd" showOrHide:@"show" afterRotation:YES];
        }
        else if (self.showingAdMob) {
            if(kAdTesting) NSLog(@"Device rotated. Resizing view for AdMob.");
            [self resizeViewForAdType:@"AdMob" showOrHide:@"show" afterRotation:YES];
        }
    }
}


#pragma mark -
#pragma mark iAd Delegate Methods

// Unused iAd delegate method - no need to do anything here
//- (void)bannerViewWillLoadAd:(ADBannerView *)banner
//{
//    
//}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if(kAdTesting) NSLog(@"New iAd received.");
    if(!self.showingiAd){
        // Ensure AdMob is hidden
        if (self.showingAdMob) {
            // If we're preferring iAd then we should remove AdMob rather than simply hiding it
            if ([kDefaultAds isEqualToString:@"iAd"]) {
                [self removeBanner:@"AdMob" permanently:YES];
            }
            else {
                [self removeBanner:@"AdMob" permanently:NO];
            }
            self.showingAdMob = NO;
        }
        
        // Show iAd
        [self resizeViewForAdType:@"iAd" showOrHide:@"show" afterRotation:NO];
    }else{
        if(kAdTesting) NSLog(@"iAdView already on screen, no need to resize/rotate.");
    }
    self.showingiAd = YES;
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if(kAdTesting) NSLog(@"Failed to receive iAd. %@", error.localizedDescription);
    
    // Ensure iAd is hidden
    if (self.iAdView.frame.origin.y>=0 && self.iAdView.frame.origin.y < self.containerView.frame.size.height){
        [self removeBanner:@"iAd" permanently:NO];
    }
    self.showingiAd = NO;
    
    // Create AdMob (if not already created)
    if(kAdTesting && kUseAdMob) NSLog(@"Trying AdMob instead...");
    if(self.adMobView==nil && kUseAdMob){
        if(kAdTesting) NSLog(@"adMobView doesn't exist. Creating view.");
        [self createBanner:@"AdMob"];
    }
    else if(kUseAdMob){
        if(kAdTesting) NSLog(@"adMobView already exists. Requesting new ad.");
        [self.adMobView loadRequest:[GADRequest request]];
    }
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

// Another unused iAd delegate method
// Do stuff after a user has finished interacting with an ad
//- (void)bannerViewActionDidFinish:(ADBannerView *)banner
//{
//    
//}

#pragma mark -
#pragma mark AdMob Delegate Methods

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
    if(kAdTesting) NSLog(@"New AdMob ad received.");
    
    if(!self.showingAdMob){
        // Ensure iAd is hidden, then show AdMob
        if (self.showingiAd) {
            // If we're preferring AdMob then we should remove iAd rather than simply hiding it
            if ([kDefaultAds isEqualToString:@"AdMob"]) {
                [self removeBanner:@"iAd" permanently:YES];
            }
            else if (self.iAdView.isBannerLoaded) {
                [self removeBanner:@"iAd" permanently:NO];
            }
            self.showingiAd = NO;
        }
        
        [self resizeViewForAdType:@"AdMob" showOrHide:@"show" afterRotation:NO];
    }else{
        if(kAdTesting) NSLog(@"adMobView already on screen, no need to resize/rotate.");
    }
    self.showingAdMob = YES;
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    // Ensure AdMob is hidden
    if (self.adMobView.frame.origin.y>=0 && self.adMobView.frame.origin.y < self.containerView.frame.size.height){
        [self removeBanner:@"AdMob" permanently:NO];
    }
    self.showingAdMob = NO;
    
    if(kAdTesting) NSLog(@"Failed to receive AdMob. %@", error.localizedDescription);
    
    // Request iAd if we haven't already created one.
    if (self.iAdView==nil && kUseiAd){
        if(kAdTesting) NSLog(@"iAd view doesn't exist. Creating view...");
        [self createBanner:@"iAd"];
    }
    else{
        // Nothing to do here...
        // If iAds are enabled, delegate methods will continue firing and eventually restart the whole process.
    }
}

// Unused AdMob delegate methods
//- (void)adViewWillPresentScreen:(GADBannerView *)bannerView
//{
//    
//}

//- (void)adViewDidDismissScreen:(GADBannerView *)bannerView
//{
//    
//}

//- (void)adViewWillLeaveApplication:(GADBannerView *)bannerView
//{
//    
//}


@end