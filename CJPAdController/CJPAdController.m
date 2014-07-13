//
//  CJPAdController.m
//  CJPAdController 1.6
//
//  Created by Chris Phillips on 19/11/2011.
//  Copyright (c) 2011-2014 Midnight Labs. All rights reserved.
//

#import "CJPAdController.h"

// Debug logging
#if defined(DEBUG) && defined(DEBUG_CJPADCONTROLLER)
#define CJPLog(fmt, ...) NSLog((@"%@ [line %u]: " fmt), NSStringFromClass(self.class), __LINE__, ##__VA_ARGS__)
#else
#define CJPLog(...)
#endif

static NSString * const CJPAdsPurchasedKey = @"adRemovalPurchased";

@interface CJPAdController ()

@property (nonatomic, strong) ADBannerView *iAdView;
@property (nonatomic, strong) GADBannerView *adMobView;
@property (nonatomic, strong) UIViewController *contentController;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign) CJPAdNetwork preferredAds;
@property (nonatomic, assign) BOOL showingiAd;
@property (nonatomic, assign) BOOL showingAdMob;
@property (nonatomic, assign) BOOL isTabBar;

- (void)createBanner:(NSNumber *)adID;
- (void)removeBanner:(NSNumber *)adID permanently:(BOOL)permanent;
- (void)layoutAds;
- (UIViewController *)currentViewController;

@end

@implementation CJPAdController

#pragma mark -
#pragma mark Class Methods

+ (CJPAdController *)sharedInstance
{
    static CJPAdController *sharedInstance = nil;
    if (sharedInstance == nil)
    {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

- (id)init
{
    if ((self = [super init]))
    {
        // Have ads been removed?
        _adsRemoved = [[NSUserDefaults standardUserDefaults] boolForKey:CJPAdsPurchasedKey];
        
        // Set defaults
        _adPosition = CJPAdPositionBottom;
        _adNetworks = @[@(CJPAdNetworkiAd), @(CJPAdNetworkAdMob)];
        _preferredAds = (CJPAdNetwork)[[_adNetworks objectAtIndex:0] intValue];
        _initialDelay = 0.0;
        _useAdMobSmartSize = YES;
    }
    return self;
}

// Custom setter for ad networks because we'll set the first one in the array as our preferred ads
- (void)setAdNetworks:(NSArray *)adNetworks
{
    _adNetworks = adNetworks;
    _preferredAds = (CJPAdNetwork)[[_adNetworks objectAtIndex:0] intValue];
}

- (void)startWithViewController:(UIViewController *)contentController
{
    _contentController = contentController;
    
    // Is this being used in a tabBarController?
    _isTabBar = [_contentController isKindOfClass:[UITabBarController class]] ? YES : NO;
    
    // Create a container view to hold our parent view and the banner view
    _containerView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self addChildViewController:_contentController];
    [_containerView addSubview:_contentController.view];
    [_contentController didMoveToParentViewController:self];
    
    // iOS 7+
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    // Set the container view as this view
    self.view = _containerView;
    
    // Now everything is set up, we can create a banner (if the user hasn't purchased ad removal)
    if (!_adsRemoved) {
        [self performSelector:@selector(createBanner:) withObject:@(_preferredAds) afterDelay:_initialDelay];
    }
}

#pragma mark -
#pragma mark Banner Create/Destroy

- (void)createBanner:(NSNumber *)adID
{
    CJPAdNetwork adType = (CJPAdNetwork)[adID intValue];
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    BOOL isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO;
    
    // Create iAd
    if(adType == CJPAdNetworkiAd){
        CJPLog(@"Creating iAd");
        // iOS 6 and above uses a new initializer, which Apple say we should use if available
        if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)]) {
            _iAdView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
        } else {
            // iOS 5 will need to use the old method
            _iAdView = [[ADBannerView alloc] init];
        }
        
        CGRect bannerFrame = CGRectZero;
        
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
        // If configured to support iOS 5, then we need to set the currentContentSizeIdentifier in order to resize the banner properly.
        _iAdView.requiredContentSizeIdentifiers = [NSSet setWithObjects:ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil];
        
        if (isPortrait) _iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
        else            _iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
#else
        // If configured to support iOS >= 6.0 only, then we want to avoid currentContentSizeIdentifier as it is deprecated.
        // Fortunately all we need to do is ask the banner for a size that fits into the layout area we are using.
        // At this point in this method contentFrame=self.view.bounds, so we'll use that size for the layout.
        bannerFrame.size = [_iAdView sizeThatFits:self.view.bounds.size];
#endif
        
        // Set initial frame to be offscreen
        if(_adPosition==CJPAdPositionBottom)
            bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        else if(_adPosition==CJPAdPositionTop)
            bannerFrame.origin.y = 0 - _iAdView.frame.size.height;
        _iAdView.frame = bannerFrame;
        _iAdView.delegate = self;
        _iAdView.hidden = YES;
        [_containerView insertSubview:_iAdView atIndex:0];
        CJPLog(@"Added iAd to view.");
    }
    
    // Create AdMob
    else if(adType == CJPAdNetworkAdMob){
        CJPLog(@"Creating AdMob");
        GADAdSize adMobSize;
        if (_useAdMobSmartSize) {
            if (!isPortrait)
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
            CGFloat screenWidth = isPortrait ? CGRectGetWidth(screen) : CGRectGetHeight(screen);
            adMobSize = isIPad ? kGADAdSizeLeaderboard : kGADAdSizeBanner;
            CGSize cgAdMobSize = CGSizeFromGADAdSize(adMobSize);
            CGFloat adMobXOffset = (screenWidth-cgAdMobSize.width)/2;
            _adMobView = [[GADBannerView alloc] initWithFrame:CGRectMake(adMobXOffset, self.view.frame.size.height - cgAdMobSize.height, cgAdMobSize.width, cgAdMobSize.height)];
        }
        
        // Specify the ad's "unit identifier." This is your AdMob Publisher ID.
        _adMobView.adUnitID = _adMobUnitID;
        
        // Set initial frame to be off screen
        CGRect bannerFrame = _adMobView.frame;
        if(_adPosition==CJPAdPositionBottom)
            bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        else if(_adPosition==CJPAdPositionTop)
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
        // Add Simulator to array of test devices
        if (_testDeviceIDs!=nil) {
            NSMutableArray *testDevicesM = [_testDeviceIDs mutableCopy];
            [testDevicesM addObject:GAD_SIMULATOR_ID];
            _testDeviceIDs = [testDevicesM copy];
        }
        adMobRequest.testDevices = _testDeviceIDs!=nil ? _testDeviceIDs : @[GAD_SIMULATOR_ID];
        
        // COPPA
        if ([_tagForChildDirectedTreatment isEqualToString:@"0"] || [_tagForChildDirectedTreatment isEqualToString:@"1"]) {
            BOOL tagForCOPPA = [_tagForChildDirectedTreatment isEqualToString:@"1"] ? YES : NO;
            [adMobRequest tagForChildDirectedTreatment:tagForCOPPA];
        }
        
        [_adMobView loadRequest:adMobRequest];
        CJPLog(@"Added AdMob to view.");
    }
}

- (void)removeBanner:(NSNumber *)adID permanently:(BOOL)permanent
{
    // When `permanently` is NO
    // This method simply hides the banner from view - the banner will show again when the next ad request is fired...
    // ... This can be 1-5 minutes for iAd, and 2 minutes for AdMob (this can be changed in your AdMob account)
    
    // When `permanently` is YES
    // This method will set the banner's view to nil and remove the banner completely from the container view
    // A new banner will not be shown unless you call restartAds.
    
    CJPAdNetwork adType = (CJPAdNetwork)[adID intValue];
    
    // iAd
    if (adType == CJPAdNetworkiAd) {
        _showingiAd = NO;
        CGRect bannerFrame = _iAdView.frame;
        if(_adPosition==CJPAdPositionBottom){
            bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        }
        else if(_adPosition==CJPAdPositionTop){
            bannerFrame.origin.y = 0 - _iAdView.frame.size.height;
        }
        _iAdView.frame = bannerFrame;
        _iAdView.hidden = YES;
        [_containerView sendSubviewToBack:_iAdView];
        if (permanent && _iAdView.bannerViewActionInProgress==NO) {
            _iAdView.delegate = nil;
            [_iAdView removeFromSuperview];
            _iAdView = nil;
            CJPLog(@"Permanently removed iAd from view.");
        }
        else {
            CJPLog(@"Temporarily hiding iAd off screen.");
        }
    }
    
    // AdMob
    if (adType == CJPAdNetworkAdMob) {
        _showingAdMob = NO;
        CGRect bannerFrame = _adMobView.frame;
        if(_adPosition==CJPAdPositionBottom){
            bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        }
        else if(_adPosition==CJPAdPositionTop){
            bannerFrame.origin.y = 0 - _adMobView.frame.size.height;
        }
        _adMobView.frame = bannerFrame;
        _adMobView.hidden = YES;
        [_containerView sendSubviewToBack:_adMobView];
        if (permanent) {
            _adMobView.delegate = nil;
            [_adMobView removeFromSuperview];
            _adMobView = nil;
            CJPLog(@"Permanently removed AdMob from view.");
        }
        else {
            CJPLog(@"Temporarily hiding AdMob off screen.");
        }
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutAds];
    }];
}

#pragma mark Remove ads from view

- (void)removeAdsAndMakePermanent:(BOOL)permanent andRemember:(BOOL)remember
{
    // Remove all ad banners from the view
    if(_iAdView!=nil) [self removeBanner:@(CJPAdNetworkiAd) permanently:permanent];
    if(_adMobView!=nil) [self removeBanner:@(CJPAdNetworkAdMob) permanently:permanent];
    
    // Set adsRemoved to YES, and store in NSUserDefaults for future reference if remember and permanent both true
    if (permanent && remember) {
        _adsRemoved = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:CJPAdsPurchasedKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)removeAds
{
    [self removeAdsAndMakePermanent:NO andRemember:NO];
}

#pragma mark Restart Ad Serving

- (void)restartAdsAfterDelay:(NSTimeInterval)delay
{
    // This method restores ads to the view by creating a new banner, intended to be used after removeBanner permanently is called.
    // NOTE: The boolean _adsRemoved is taken into account.
    
    if (!_adsRemoved && !_showingiAd && !_showingAdMob) {
        CJPLog(@"Restarting ad serving...");
        [self performSelector:@selector(createBanner:) withObject:@(_preferredAds) afterDelay:delay];
    }
}

- (void)restartAds
{
    [self restartAdsAfterDelay:0.0];
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

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
// for iOS 5
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [[self currentViewController] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}
#endif

- (void)viewDidLayoutSubviews
{
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    BOOL isPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO;
    BOOL preiOS7 = [[[UIDevice currentDevice] systemVersion] floatValue] < 7 ? YES : NO;
    UIView *tbcView = nil;
    UIView *tbcTabs = nil;
    float statusBarHeight = [UIApplication sharedApplication].statusBarHidden ? 0 : 20;
    CGRect contentFrame = self.view.bounds;
    CGRect bannerFrame = CGRectZero;
    CJPAdNetwork adType;
    
    // If we're showing ads in a tab bar above the bar itself, get the individual views so we can insert
    // the ad between them
    if (_isTabBar && _aboveTabBar && _adPosition==CJPAdPositionBottom) {
        tbcView = [_contentController.view.subviews objectAtIndex:0];
        tbcTabs = [_contentController.view.subviews objectAtIndex:1];
        contentFrame.size.height -= tbcTabs.bounds.size.height;
    }
    
    // If either an iAd or AdMob view has been created we'll figure out which views need adjusting
    if (_iAdView || _adMobView) {
        // iAd specific stuff
        if (_iAdView) {
            adType = CJPAdNetworkiAd;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
            // If configured to support iOS 5, then we need to set the currentContentSizeIdentifier in order to resize the banner properly.
            if (isPortrait) _iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
            else            _iAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
            
            bannerFrame = _iAdView.frame;
#else
            // If configured to support iOS >= 6.0 only, then we want to avoid currentContentSizeIdentifier as it is deprecated.
            // Fortunately all we need to do is ask the banner for a size that fits into the layout area we are using.
            // At this point in this method contentFrame=self.view.bounds, so we'll use that size for the layout.
            bannerFrame.size = [_iAdView sizeThatFits:contentFrame.size];
#endif
        }
        
        // AdMob specific stuff
        if (_adMobView) {
            adType = CJPAdNetworkAdMob;
            if (_useAdMobSmartSize) {
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
            CJPLog(@"AdView exists and ad is being shown.");
            
            if(_adPosition==CJPAdPositionBottom){
                contentFrame.size.height -= bannerFrame.size.height;
                bannerFrame.origin.y = contentFrame.size.height;
            }
            else if(_adPosition==CJPAdPositionTop){
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
            CJPLog(@"AdView exists but there is currently no ad to be shown. Waiting for new ad...");
            if(_adPosition==CJPAdPositionBottom){
                bannerFrame.origin.y = contentFrame.size.height;
            }
            else if(_adPosition==CJPAdPositionTop){
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
    if (!preiOS7 && !_showingiAd && !_showingAdMob && _adPosition==CJPAdPositionTop) {
        contentFrame.origin.y = statusBarHeight;
        contentFrame.size.height -= statusBarHeight;
    }
    
    if (_isTabBar && _aboveTabBar && _adPosition==CJPAdPositionBottom) {
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
    CJPLog(@"New iAd received.");
    
    if(!_showingiAd){
        // Ensure AdMob is hidden
        if (_showingAdMob || _adMobView!=nil) {
            // If we're preferring iAd then we should remove AdMob rather than simply hiding it
            if (_preferredAds==CJPAdNetworkiAd) {
                [self removeBanner:@(CJPAdNetworkAdMob) permanently:YES];
            }
            else {
                [self removeBanner:@(CJPAdNetworkAdMob) permanently:NO];
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
    CJPLog(@"Failed to receive iAd. %@", error.localizedDescription);
    
    // Ensure view is hidden off screen
    if (_iAdView.frame.origin.y>=0 && _iAdView.frame.origin.y < _containerView.frame.size.height){
        [self removeBanner:@(CJPAdNetworkiAd) permanently:NO];
    }
    _showingiAd = NO;
    
    // Create AdMob (if not already created)
    if ([_adNetworks containsObject:@(CJPAdNetworkAdMob)]) {
        CJPLog(@"Trying AdMob instead...");
        if(_adMobView==nil){
            CJPLog(@"adMobView doesn't exist. Creating view.");
            [self createBanner:@(CJPAdNetworkAdMob)];
        }
        else{
            CJPLog(@"adMobView already exists. Requesting new ad.");
            [_adMobView loadRequest:[GADRequest request]];
        }
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutAds];
    }];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    CJPLog(@"Tapped on an iAd.");
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    CJPLog(@"Finished viewing iAd.");
    // Nothing to do here
}

#pragma mark -
#pragma mark AdMob Delegate Methods

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
    CJPLog(@"New AdMob ad received.");
    
    if(!_showingAdMob){
        // Ensure iAd is hidden, then show AdMob
        if (_showingiAd || _iAdView!=nil) {
            // If we're preferring AdMob then we should remove iAd rather than simply hiding it
            if (_preferredAds==CJPAdNetworkAdMob) {
                [self removeBanner:@(CJPAdNetworkiAd) permanently:YES];
            }
            else if (_iAdView.isBannerLoaded) {
                [self removeBanner:@(CJPAdNetworkiAd) permanently:NO];
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
    // Ensure view is hidden off screen
    if (_adMobView.frame.origin.y>=0 && _adMobView.frame.origin.y < _containerView.frame.size.height){
        [self removeBanner:@(CJPAdNetworkAdMob) permanently:NO];
    }
    _showingAdMob = NO;
    
    CJPLog(@"Failed to receive AdMob. %@", error.localizedDescription);
    
    // Request iAd if we haven't already created one.
    if ([_adNetworks containsObject:@(CJPAdNetworkiAd)]) {
        CJPLog(@"Trying iAd instead...");
        if(_iAdView==nil){
            CJPLog(@"iAdView doesn't exist. Creating view.");
            [self createBanner:@(CJPAdNetworkiAd)];
        }
        else{
            CJPLog(@"iAdView already exists. Nothing to do. A new ad will appear momentarily.");
        }
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