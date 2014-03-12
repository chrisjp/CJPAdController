//
//  CJPAdController.m
//  CJPAdController 1.5.1
//
//  Created by Chris Phillips on 19/11/2011.
//  Copyright (c) 2011-2014 Chris Phillips. All rights reserved.
//

#import "CJPAdController.h"

static CJPAdController *CJPSharedManager = nil;

@implementation CJPAdController

@synthesize iAdView              = _iAdView;
@synthesize adMobView            = _adMobView;
@synthesize contentController    = _contentController;
@synthesize containerView        = _containerView;
@synthesize showingiAd           = _showingiAd;
@synthesize showingAdMob         = _showingAdMob;
@synthesize adsRemoved           = _adsRemoved;
@synthesize isTabBar             = _isTabBar;

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

- (id)initWithContentViewController:(UIViewController *)contentController
{
    self = [super init];
    if (self != nil) {
        
        // Warn user about testing mode
        if (kAdTesting) NSLog(@"TESTING MODE ENABLED. Remember to set kAdTesting to NO before building for production to avoid spamming logs.");
        
        // Have ads been removed?
        _adsRemoved = [[NSUserDefaults standardUserDefaults] boolForKey:kAdsPurchasedKey];
        
        // Set the content controller
        _contentController = contentController;
        
        // Is this being used in a tabBarController?
        _isTabBar = [_contentController isKindOfClass:[UITabBarController class]] ? YES : NO;
        
        // Create a container view to hold both our parent view and the banner view
        _containerView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [self addChildViewController:_contentController];
        [_containerView addSubview:_contentController.view];
        [_contentController didMoveToParentViewController:self];
        
        // iOS 7
        if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
        
        // Create a banner if the user hasn't purchased ad removal
        if (!_adsRemoved) {
            [self performSelector:@selector(createBanner:) withObject:kDefaultAds afterDelay:kWaitTime];
        }
        
        // Set the container view as this view
        self.view = _containerView;
    }
    return self;
}

#pragma mark -
#pragma mark Banner Create/Destroy

- (void)createBanner:(NSString *)adType
{
    
    BOOL inPortrait = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    BOOL isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO;
    
    if(kAdTesting) NSLog(@"Creating %@", adType);
    
    // Create iAd
    if([adType isEqualToString:@"iAd"]){
        _iAdView = [[ADBannerView alloc] initWithFrame:CGRectZero];
        
        _iAdView.requiredContentSizeIdentifiers = [NSSet setWithObjects:ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil];
        
        if (!inPortrait)
            _iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
        else
            _iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
        
        // Set initial frame to be offscreen
        CGRect bannerFrame = _iAdView.frame;
        if([kAdPosition isEqualToString:@"bottom"])
            bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        else if([kAdPosition isEqualToString:@"top"])
            bannerFrame.origin.y = 0 - _iAdView.frame.size.height;
        _iAdView.frame = bannerFrame;
        _iAdView.delegate = self;
        _iAdView.hidden = YES;
        [_containerView insertSubview:_iAdView atIndex:0];
    }
    
    // Create AdMob
    else if([adType isEqualToString:@"AdMob"]){
        GADAdSize adMobSize;
        if (kUseAdMobSmartSize) {
            if (!inPortrait)
                adMobSize = kGADAdSizeSmartBannerLandscape;
            else
                adMobSize = kGADAdSizeSmartBannerPortrait;
            _adMobView = [[GADBannerView alloc] initWithAdSize:adMobSize];
        }else{
            // Legacy AdMob ad sizes don't fill the full width of the device screen apart from iPhone when in portrait view
            // We need to offset the x position so the ad appears centered - Calculation: (View width - Ad width) / 2
            // Problem is that getting the width of the bounds doesn't take into account the current orientation
            // As a workaround, if we're in landscape, we'll simply get the height instead
            CGRect screen = [[UIScreen mainScreen] bounds];
            CGFloat screenWidth = inPortrait ? CGRectGetWidth(screen) : CGRectGetHeight(screen);
            adMobSize = isIPad ? kGADAdSizeLeaderboard : kGADAdSizeBanner;
            CGSize cgAdMobSize = CGSizeFromGADAdSize(adMobSize);
            CGFloat adMobXOffset = (screenWidth-cgAdMobSize.width)/2;
            _adMobView = [[GADBannerView alloc] initWithFrame:CGRectMake(adMobXOffset, self.view.frame.size.height - cgAdMobSize.height, cgAdMobSize.width, cgAdMobSize.height)];
        }
        
        // Specify the ad's "unit identifier." This is your AdMob Publisher ID.
        _adMobView.adUnitID = kAdMobID;
        
        // Set initial frame to be off screen
        CGRect bannerFrame = _adMobView.frame;
        if([kAdPosition isEqualToString:@"bottom"])
            bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        else if([kAdPosition isEqualToString:@"top"])
            bannerFrame.origin.y = 0 - _adMobView.frame.size.height;
        _adMobView.frame = bannerFrame;
        
        // Let the runtime know which UIViewController to restore after taking
        // the user wherever the ad goes and add it to the view hierarchy.
        _adMobView.rootViewController = self;
        _adMobView.delegate = self;
        _adMobView.hidden = YES;
        [_containerView insertSubview:_adMobView atIndex:0];
        
        // Request an ad
        GADRequest *adMobRequest = [GADRequest request];
        
        // Device identifier strings that will receive test AdMob ads
        if (kAdTesting) adMobRequest.testDevices = [NSArray arrayWithObjects:GAD_SIMULATOR_ID, nil];
        
        // COPPA
        if ([tagForChildDirectedTreatment isEqualToString:@"0"] || [tagForChildDirectedTreatment isEqualToString:@"1"]) {
            BOOL tagForCOPPA = [tagForChildDirectedTreatment isEqualToString:@"1"] ? YES : NO;
            [adMobRequest tagForChildDirectedTreatment:tagForCOPPA];
        }
        
        [_adMobView loadRequest:adMobRequest];
    }
    
    if(kAdTesting) NSLog(@"%@ added to view.", adType);
}

- (void)removeBanner:(NSString *)adType permanently:(BOOL)permanent
{
    // When `permanently` is NO
    // This method simply hides the banner from view - the banner will show again when the next ad request is fired...
    // ... This can be 1-5 minutes for iAd, and 2 minutes for AdMob (this can be changed in your AdMob account)
    
    // When `permanently` is YES
    // This method will set the banner's view to nil and remove the banner completely from the container view
    // A new banner will not be shown unless you call restoreBanner on it.
    
    // iAd
    if ([adType isEqualToString:@"iAd"]) {
        _showingiAd = NO;
        CGRect bannerFrame = _iAdView.frame;
        if([kAdPosition isEqualToString:@"bottom"]){
            bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        }
        else if([kAdPosition isEqualToString:@"top"]){
            bannerFrame.origin.y = 0 - _iAdView.frame.size.height;
        }
        _iAdView.frame = bannerFrame;
        _iAdView.hidden = YES;
        [_containerView sendSubviewToBack:_iAdView];
        if (permanent) {
            _iAdView.delegate = nil;
            [_iAdView removeFromSuperview];
            _iAdView = nil;
        }
    }
    
    // AdMob
    if ([adType isEqualToString:@"AdMob"]) {
        _showingAdMob = NO;
        CGRect bannerFrame = _adMobView.frame;
        if([kAdPosition isEqualToString:@"bottom"]){
            bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        }
        else if([kAdPosition isEqualToString:@"top"]){
            bannerFrame.origin.y = 0 - _adMobView.frame.size.height;
        }
        _adMobView.frame = bannerFrame;
        _adMobView.hidden = YES;
        [_containerView sendSubviewToBack:_adMobView];
        if (permanent) {
            _adMobView.delegate = nil;
            [_adMobView removeFromSuperview];
            _adMobView = nil;
        }
    }
    
    if(kAdTesting && permanent) NSLog(@"Permanently removed %@ from view.", adType);
    
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutAds];
    }];
}

- (void)restoreBanner:(NSString *)adType
{
    // This method restores ads to the view by creating a new banner, intended to be used after removeBanner permanently is called.
    // NOTE: The boolean _adsRemoved is taken into account.
    
    if (!_adsRemoved) {
        if (adType.length==0) {
            adType = kDefaultAds;
        }
        if(kAdTesting) NSLog(@"Restoring ads to view with new %@.", adType);
        [self performSelector:@selector(createBanner:) withObject:adType afterDelay:0.0];
    }
}

- (void)removeAllAdsForever
{
    // This method is intended to be called when a user has, for example, purchased removal of advertising
    // Assuming you have an in-app purchase to handle that, you can call this method on successful purchase
    
    // Remove all ad banners from the view
    if(_iAdView!=nil) [self removeBanner:@"iAd" permanently:YES];
    if(_adMobView!=nil) [self removeBanner:@"AdMob" permanently:YES];
    
    // Set adsRemoved to YES, and store in UserDefaults for future use
    _adsRemoved = YES;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAdsPurchasedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark -
#pragma mark View Methods

- (void)layoutAds
{
    [self.view setNeedsLayout];
}

// Returns the currently visible view controller from either the UINavigationController or UITabBarController holding the content
- (UIViewController *)currentViewController
{
    if (_isTabBar) {
        UITabBarController *tabBarController = (UITabBarController*)_contentController;
        
        // If the selected view of the tbc has child views (is a UINavigationController) then we need to get the one at the top
        if (tabBarController.selectedViewController.childViewControllers.count > 0)
            return (UIViewController*)[tabBarController.selectedViewController.childViewControllers lastObject];
        
        // If it's some other view then we can just return that
        return tabBarController.selectedViewController;
    }
    
    // Otherwise we must be using a UINavigationController, so just return the top most view controller.
    return (UIViewController*)[_contentController.childViewControllers lastObject];
}

- (BOOL)prefersStatusBarHidden
{
    // Return the application's statusBarHidden if the UIViewControllerBasedStatusBarAppearance key has not been added to Info.plist
    // Otherwise return the prefersStatusBarHidden set by the view controller
    if (![[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"]) {
        return [UIApplication sharedApplication].statusBarHidden;
    }
    else {
        return [self currentViewController].prefersStatusBarHidden;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    // Return the application's statusBarStyle if the UIViewControllerBasedStatusBarAppearance key has not been added to Info.plist
    // Otherwise return the preferredStatusBarStyle set by the view controller
    if (![[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"]) {
        return [UIApplication sharedApplication].statusBarStyle;
    }
    else {
        return [self currentViewController].preferredStatusBarStyle;
    }
}

- (BOOL)shouldAutorotate
{
    return [[self currentViewController] shouldAutorotate];
}

// for iOS 5
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [[self currentViewController] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)viewDidLayoutSubviews
{
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    BOOL isPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO;
    BOOL preiOS7 = [[[UIDevice currentDevice] systemVersion] floatValue] < 7 ? YES : NO;
    UIView *tbcView = nil;
    UIView *tbcTabs = nil;
    float statusBarHeight = [UIApplication sharedApplication].statusBarHidden ? 0 : 20;
    CGRect contentFrame = self.view.bounds;
    CGRect bannerFrame;
    
    // If we're showing ads in a tab bar above the bar itself, get the individual views so we can insert
    // the ad between them
    if (_isTabBar && kAboveTabBar && [kAdPosition isEqualToString:@"bottom"]) {
        tbcView = [_contentController.view.subviews objectAtIndex:0];
        tbcTabs = [_contentController.view.subviews objectAtIndex:1];
        contentFrame.size.height -= tbcTabs.bounds.size.height;
    }
    
    // If either an iAd or AdMob view has been created we'll figure out which views need adjusting
    if (_iAdView || _adMobView) {
        
        // iAd specific stuff
        if (_iAdView) {
            if (isPortrait) _iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
            else            _iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
            
            bannerFrame = _iAdView.frame;
        }
        
        // AdMob specific stuff
        if (_adMobView) {
            if (kUseAdMobSmartSize) {
                if (isPortrait) _adMobView.adSize = kGADAdSizeSmartBannerPortrait;
                else            _adMobView.adSize = kGADAdSizeSmartBannerLandscape;
                
                bannerFrame = _adMobView.frame;
            }
            else{
                // Legacy AdMob doesn't have different orientation sizes - we just need to change the X offset so the ad remains centered
                bannerFrame = _adMobView.frame;
                CGRect screen = [[UIScreen mainScreen] bounds];
                CGFloat screenWidth = isPortrait ? CGRectGetWidth(screen) : CGRectGetHeight(screen);
                GADAdSize adMobSize = isPad ? kGADAdSizeLeaderboard : kGADAdSizeBanner;
                CGSize cgAdMobSize = CGSizeFromGADAdSize(adMobSize);
                CGFloat adMobXOffset = (screenWidth-cgAdMobSize.width)/2;
                bannerFrame.origin.x = adMobXOffset;
                _adMobView.frame = bannerFrame;
            }
        }
        
        // Now if we actually have an ad to display
        if (_showingiAd || _showingAdMob) {
            if(kAdTesting) NSLog(@"AdView has been created and an ad is ready to be shown");
            
            if([kAdPosition isEqualToString:@"bottom"]){
                contentFrame.size.height -= bannerFrame.size.height;
                bannerFrame.origin.y = contentFrame.size.height;
            }
            else if([kAdPosition isEqualToString:@"top"]){
                if (preiOS7) {
                    contentFrame.size.height -= bannerFrame.size.height;
                    contentFrame.origin.y += bannerFrame.size.height;
                    bannerFrame.origin.y = 0;
                }
                else {
                    contentFrame.size.height -= (bannerFrame.size.height + statusBarHeight);
                    contentFrame.origin.y = (bannerFrame.size.height + statusBarHeight);
                    bannerFrame.origin.y = statusBarHeight;
                }
            }
        }
        // Or if we don't...
        else {
            if(kAdTesting) NSLog(@"AdView has been created but there is currently NO ad to be shown");
            if([kAdPosition isEqualToString:@"bottom"]){
                bannerFrame.origin.y = contentFrame.size.height;
            }
            else if([kAdPosition isEqualToString:@"top"]){
                bannerFrame.origin.y = 0 - bannerFrame.size.height;
                
                if (preiOS7){
                    contentFrame.origin.y = 0;
                }
                else {
                    contentFrame.origin.y = statusBarHeight;
                }
            }
        }
        
        if (_showingiAd)        _iAdView.frame = bannerFrame;
        else if (_showingAdMob) _adMobView.frame = bannerFrame;
    }
    
    // If we're on iOS 7 and aren't showing any ads yet, or if they have been removed
    // reset the contentFrame taking into account the height of the status bar
    // This is only necessary when displaying ads at the top of the view as ads displayed
    // at the bottom do not interfere with the unified status/nav bar
    if (!preiOS7 && !_showingiAd && !_showingAdMob && [kAdPosition isEqualToString:@"top"]) {
        contentFrame.origin.y = statusBarHeight;
        contentFrame.size.height -= statusBarHeight;
    }
    
    if (_isTabBar && kAboveTabBar && [kAdPosition isEqualToString:@"bottom"]) {
        tbcView.frame = contentFrame;
    }
    else {
        _contentController.view.frame = contentFrame;
    }
}

#pragma mark -
#pragma mark iAd Delegate Methods

- (void)bannerViewWillLoadAd:(ADBannerView *)banner
{
    // We don't need to execute any code before an iAd is about to be displayed
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if(kAdTesting) NSLog(@"New iAd received.");
    
    if(!_showingiAd){
        // Ensure AdMob is hidden
        if (_showingAdMob) {
            // If we're preferring iAd then we should remove AdMob rather than simply hiding it
            if ([kDefaultAds isEqualToString:@"iAd"]) {
                [self removeBanner:@"AdMob" permanently:YES];
            }
            else {
                [self removeBanner:@"AdMob" permanently:NO];
            }
            _showingAdMob = NO;
        }
    }
    _showingiAd = YES;
    _iAdView.hidden = NO;
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self layoutAds];
                     }
                     completion:^(BOOL finished){
                         // Ensure view isn't behind the container and untappable
                         if (finished) [_containerView bringSubviewToFront:_iAdView];
                     }];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if(kAdTesting) NSLog(@"Failed to receive iAd. %@", error.localizedDescription);
    
    // Ensure iAd is hidden
    if (_iAdView.frame.origin.y>=0 && _iAdView.frame.origin.y < _containerView.frame.size.height){
        [self removeBanner:@"iAd" permanently:NO];
    }
    _showingiAd = NO;
    
    // Create AdMob (if not already created)
    if(kAdTesting && kUseAdMob) NSLog(@"Trying AdMob instead...");
    if(_adMobView==nil && kUseAdMob){
        if(kAdTesting) NSLog(@"adMobView doesn't exist. Creating view.");
        [self createBanner:@"AdMob"];
    }
    else if(kUseAdMob){
        if(kAdTesting) NSLog(@"adMobView already exists. Requesting new ad.");
        [_adMobView loadRequest:[GADRequest request]];
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutAds];
    }];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    //[[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionWillBegin object:self];
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    //[[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionDidFinish object:self];
}

#pragma mark -
#pragma mark AdMob Delegate Methods

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
    if(kAdTesting) NSLog(@"New AdMob ad received.");
    
    if(!_showingAdMob){
        // Ensure iAd is hidden, then show AdMob
        if (_showingiAd) {
            // If we're preferring AdMob then we should remove iAd rather than simply hiding it
            if ([kDefaultAds isEqualToString:@"AdMob"]) {
                [self removeBanner:@"iAd" permanently:YES];
            }
            else if (_iAdView.isBannerLoaded) {
                [self removeBanner:@"iAd" permanently:NO];
            }
            _showingiAd = NO;
        }
    }
    _showingAdMob = YES;
    _adMobView.hidden = NO;
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self layoutAds];
                     }
                     completion:^(BOOL finished){
                         // Ensure view isn't behind the container and untappable
                         if (finished) [_containerView bringSubviewToFront:_adMobView];
                     }];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    // Ensure AdMob is hidden
    if (_adMobView.frame.origin.y>=0 && _adMobView.frame.origin.y < _containerView.frame.size.height){
        [self removeBanner:@"AdMob" permanently:NO];
    }
    _showingAdMob = NO;
    
    if(kAdTesting) NSLog(@"Failed to receive AdMob. %@", error.localizedDescription);
    
    // Request iAd if we haven't already created one.
    if (_iAdView==nil && kUseiAd){
        if(kAdTesting) NSLog(@"iAd view doesn't exist. Creating view...");
        [self createBanner:@"iAd"];
    }
    else{
        // Nothing to do here...
        // If iAds are enabled, delegate methods will continue firing and eventually restart the whole process.
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutAds];
    }];
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