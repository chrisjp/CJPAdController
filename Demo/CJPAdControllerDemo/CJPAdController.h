//
//  CJPAdController.h
//  ChrisJP
//
//  Created by Chris Phillips on 19/11/2011.
//  Copyright (c) 2011 ChrisJP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <iAd/iAd.h>
#import "GADBannerView.h"

// Choose which ads you want to publish (iAd / AdMob)
#define kUseiAd YES
#define kUseAdMob YES
// Set which ads should be initially displayed and preferred ("iAd" or "AdMob")
#define kDefaultAds @"iAd"
// Your AdMob publisher ID
#define kAdMobID @"a14f255d715fe96"
// Seconds to wait before displaying ad (set to 0.0 to display instantly)
#define kWaitTime 2.0
// Name of UserDefaults key for if ads have been purchased
#define kAdsPurchasedKey @"adRemovalPurchased"
// Testing? Setting to YES will NSLog various events
#define kAdTesting YES

@interface CJPAdController : NSObject <ADBannerViewDelegate, GADBannerViewDelegate>

@property (nonatomic, retain) ADBannerView      *iAdView;
@property (nonatomic, retain) GADBannerView     *adMobView;
@property (nonatomic, retain) UIView            *containerView;
@property (nonatomic, assign) UIView            *parentView;
@property (nonatomic, assign) UIViewController  *parentViewController;
@property (nonatomic, assign) UIView            *previousView;
@property (nonatomic, assign) BOOL              showingiAd;
@property (nonatomic, assign) BOOL              showingAdMob;
@property (nonatomic, assign) BOOL              adsRemoved;


+ (CJPAdController *)sharedManager;
- (void)addBannerToViewController:(UIViewController *)viewController;
- (void)createBanner:(NSString *)adType;
- (void)removeBanner:(NSString *)adType permanently:(BOOL)permanent;
- (void)resizeViewForAdType:(NSString *)adType showOrHide:(NSString *)showHide afterRotation:(BOOL)isAfterRotation;
- (void)rotateAdToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
- (void)fixAdViewAfterRotation;

@end