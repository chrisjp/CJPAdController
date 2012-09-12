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
@synthesize contentController    = _contentController;
@synthesize containerView        = _containerView;
@synthesize showingiAd           = _showingiAd;
@synthesize showingAdMob         = _showingAdMob;
@synthesize adsRemoved           = _adsRemoved;
@synthesize iOS4                 = _iOS4;
@synthesize kADBannerContentSizeIdentifierLandscape;
@synthesize kADBannerContentSizeIdentifierPortrait;

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
        
        // Ads Removed?
        _adsRemoved = [[NSUserDefaults standardUserDefaults] boolForKey:kAdsPurchasedKey];
        
        _contentController = contentController;
        
        // Create a container view to hold both our parent view and the banner view
        // iOS 5+ can use native view containment
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5) {
            _containerView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            [self addChildViewController:_contentController];
            [_containerView addSubview:_contentController.view];
            [_contentController didMoveToParentViewController:self];
            self.view = _containerView;
        }
        // iOS 4+ can't
        else {
            // iOS 4 Support
            // Since iOS 4 does not support view containment, we create a new view that fills the screen
            // We add our contentController's view as a subview to this, as well as an adview
            // We then set this new view as the main view.
            _iOS4 = YES;
            _containerView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
            [_containerView addSubview:_contentController.view];
            self.view = _containerView;
        }
        
        // iOS 4.0/4.1 iAd Support
        kADBannerContentSizeIdentifierPortrait = &ADBannerContentSizeIdentifierPortrait != nil ? ADBannerContentSizeIdentifierPortrait : ADBannerContentSizeIdentifier320x50;
        kADBannerContentSizeIdentifierLandscape = &ADBannerContentSizeIdentifierLandscape != nil ? ADBannerContentSizeIdentifierLandscape : ADBannerContentSizeIdentifier480x32;
        
        if (!_adsRemoved) {
            [self performSelector:@selector(createBanner:) withObject:kDefaultAds afterDelay:kWaitTime];
        }
    }
    return self;
}

- (void)createBanner:(NSString *)adType
{
    
    BOOL inPortrait = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    BOOL isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO;
    
    if(kAdTesting) NSLog(@"Creating %@", adType);
    
    // Create iAd
    if([adType isEqualToString:@"iAd"]){
        _iAdView = [[ADBannerView alloc] initWithFrame:CGRectZero];
        
        _iAdView.requiredContentSizeIdentifiers = [NSSet setWithObjects:kADBannerContentSizeIdentifierPortrait, kADBannerContentSizeIdentifierLandscape, nil];
        
        if (!inPortrait)
            _iAdView.currentContentSizeIdentifier = kADBannerContentSizeIdentifierLandscape;
        else
            _iAdView.currentContentSizeIdentifier = kADBannerContentSizeIdentifierPortrait;
        
        // Set initial frame to be offscreen
        CGRect bannerFrame = _iAdView.frame;
        if([kAdPosition isEqualToString:@"bottom"])
            bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        else if([kAdPosition isEqualToString:@"top"])
            bannerFrame.origin.y = 0 - _iAdView.frame.size.height;
        _iAdView.frame = bannerFrame;
        _iAdView.delegate = self;
        [self.view addSubview:_iAdView];
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
        [_containerView addSubview:_adMobView];
        
        // Request an ad
        GADRequest *adMobRequest = [GADRequest request];
        // Uncomment the following line if you wish to receive test ads (simulator only)
        //adMobRequest.testing = YES;
        [_adMobView loadRequest:adMobRequest];
    }
    
    if(kAdTesting) NSLog(@"%@ added to view.", adType);
}

- (void)removeBanner:(NSString *)adType permanently:(BOOL)permanent
{
    // Hides the banner from view
    // If permanent is set to YES we'll additionally set its view to nil and remove it
    
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
        if (permanent) {
            _adMobView.delegate = nil;
            [_adMobView removeFromSuperview];
            _adMobView = nil;
        }
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutAds];
    }];
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

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [_contentController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // BUG FIX:
    // Since we can't use view containment in iOS 4, creating our own container means the 
    // navigationBar does not get resized on rotation because it is not the rootViewController
    // The following code manually resizes the navBar - not applicable on iPad as the navBar remains the same size anyway
    if (_iOS4) {
        NSArray *subs = _contentController.view.subviews;
        UINavigationBar *navbar = nil;
        for (int i=0; i<subs.count; i++) {
            if ([[subs objectAtIndex:i] isKindOfClass:[UINavigationBar class]]) {
                navbar = [subs objectAtIndex:i];
                break;
            }
        }
        if (navbar && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
            CGRect frame = navbar.frame;
            frame.size.height = UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? 44. : 32.;
            navbar.frame = frame;
        }
        
        if (_showingiAd) _iAdView.hidden = YES;
        else if (_showingAdMob) _adMobView.hidden = YES;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (_iOS4) {
        [UIView animateWithDuration:0.25 animations:^{
            [self layoutAds];
            if (_showingiAd) _iAdView.hidden = NO;
            else if (_showingAdMob) _adMobView.hidden = NO;
        }];
    }
}

- (void)viewDidLayoutSubviews
{
    // This method is called when an ad is received or removed.
    // It will move the ad on/offscreen as necessary.
    // It is iOS5 only, but we can manually call it on iOS4.
    
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    BOOL isPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO;
        
    CGRect contentFrame = self.view.bounds;
    
    if (_iAdView) {
        if (isPortrait) {
            _iAdView.currentContentSizeIdentifier = kADBannerContentSizeIdentifierPortrait;
        } else {
            _iAdView.currentContentSizeIdentifier = kADBannerContentSizeIdentifierLandscape;
        }
        
        CGRect bannerFrame = _iAdView.frame;
        if (_showingiAd) {
            if([kAdPosition isEqualToString:@"bottom"]){
                contentFrame.size.height -= _iAdView.frame.size.height;
                bannerFrame.origin.y = contentFrame.size.height;
            }
            else if([kAdPosition isEqualToString:@"top"]){
                contentFrame.size.height -= _iAdView.frame.size.height;
                contentFrame.origin.y += _iAdView.frame.size.height;
                bannerFrame.origin.y = 0;
            }
        } else {
            if([kAdPosition isEqualToString:@"bottom"]){
                bannerFrame.origin.y = contentFrame.size.height;
            }
            else if([kAdPosition isEqualToString:@"top"]){
                bannerFrame.origin.y = 0 - bannerFrame.size.height;
                contentFrame.origin.y = 0;
            }
        }
        _iAdView.frame = bannerFrame;
    }
    
    if (_adMobView) {
        if (kUseAdMobSmartSize) {
            if (isPortrait) _adMobView.adSize = kGADAdSizeSmartBannerPortrait;
            else _adMobView.adSize = kGADAdSizeSmartBannerLandscape;
        }
        else{
            // Legacy AdMob doesn't have different orientation sizes - we just need to change the X offset so the ad remains centered
            CGRect bannerFrame = _adMobView.frame;
            CGRect screen = [[UIScreen mainScreen] bounds];
            CGFloat screenWidth = isPortrait ? CGRectGetWidth(screen) : CGRectGetHeight(screen);
            GADAdSize adMobSize = isPad ? kGADAdSizeLeaderboard : kGADAdSizeBanner;
            CGSize cgAdMobSize = CGSizeFromGADAdSize(adMobSize);
            CGFloat adMobXOffset = (screenWidth-cgAdMobSize.width)/2;
            bannerFrame.origin.x = adMobXOffset;
            _adMobView.frame = bannerFrame;
        }
        
        CGRect bannerFrame = _adMobView.frame;
        if (_showingAdMob) {
            if([kAdPosition isEqualToString:@"bottom"]){
                contentFrame.size.height -= _adMobView.frame.size.height;
                bannerFrame.origin.y = contentFrame.size.height;
            }
            else if([kAdPosition isEqualToString:@"top"]){
                contentFrame.size.height -= _adMobView.frame.size.height;
                contentFrame.origin.y += _adMobView.frame.size.height;
                bannerFrame.origin.y = 0;
            }
        } else {
            if([kAdPosition isEqualToString:@"bottom"]){
                bannerFrame.origin.y = contentFrame.size.height;
            }
            else if([kAdPosition isEqualToString:@"top"]){
                bannerFrame.origin.y = 0 - bannerFrame.size.height;
                contentFrame.origin.y = 0;
            }
        }
        _adMobView.frame = bannerFrame;
    }
    
    _contentController.view.frame = contentFrame;
}

- (void)layoutAds
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    if(_iOS4) [self viewDidLayoutSubviews];
}

#pragma mark -
#pragma mark iAd Delegate Methods

- (void)bannerViewWillLoadAd:(ADBannerView *)banner
{
    // Shouldn't need to execute any code before an iAd
    // is about to be displayed
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
    
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutAds];
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
    
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutAds];
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