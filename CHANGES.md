# Changes

####1.5.2 - 2014-03-13
* Fixed all Xcode warnings about methods deprecated since iOS 6. Achieved by using the newer iAd sizing methods introduced in iOS 6. The older iOS 5 methods have been kept in conditionally and will only be used if you target < iOS 6.
* Fixed a rare UI bug that could occur on iPads if you were displaying ads at the top of your views and a certain chain of events happened. Could cause a 24px gap after an AdMob ad was replaced with an iAd.
* In the header file you can now specify a comma-separated string of device ID's that should receive test ads for AdMob, so you no longer need to edit the .m file to do add these.

####1.5.1 - 2014-03-12
* Fixed `shouldAutorotate`, `prefersStatusBarHidden` and `preferredStatusBarStyle` methods not being respected when set in your view controllers. This should reduce the need to modify CJPAdController.m to fix possible rotation and/or status bar issues you may have had.
* Cleaned up some AdMob code to remove need for GADAdMobExtras.h import.

####1.5 - 2013-10-05
* Fixed ads appearing behind status bar in iOS 7. ([#9](https://github.com/chrisjp/CJPAdController/issues/9))
* Improved iOS 7 support in general (regarding status bar preferences).
* Added support for specifying AdMob ads as "child-directed", for COPPA compliance (see [AdMob docs](https://developers.google.com/mobile-ads-sdk/docs/admob/additional-controls#ios-coppa) for more info).
* Removed support for iOS 4 due to lack of time and ability to test.

####1.4.3 - 2013-05-18
* Fix bug introduced in 1.4.2 where ads may be untappable when using a UITabBarController.

####1.4.2 - 2013-05-17
* Fix for ads sliding up over TabBar (now slide up from underneath it).

####1.4.1 - 2013-05-16
* Better support for use within apps using a UITabBarController - ads positioned at "bottom" can now be set to appear above or below the TabBar.
 * A very basic TabBar example is included in the demo app (change the `useTabBar` BOOL to YES in AppDelegate.m to see it in action).

####1.4 - 2013-04-07
* Updated bundled AdMob library to 6.3.0.
* iOS 4.3 is now the minimum supported version of iOS. This is due to Apple dropping support for the armv6 architecture.
* Removed deprecated code that was needed for iOS 4.0/4.1.
* Added a method to enable you to restore ads to your view after removing them.
* Updated the demo project to reflect the updated behaviour in removing and restoring ads, also added iPhone 5 support.

####1.3 - 2012-09-12
* Fixed iOS 4 compatibility. Now works on iOS 4.0+ (was 4.2+ before).

####1.2 - 2012-09-05
* Completely rewrote class - now shares a single instance of ADBannerView's across views, as recommended by Apple.
* Now a subclass of UIViewController - resizing ads when rotating is now done automatically.
* Added the ability to choose where ads are displayed within a view (top or bottom)
* Added a method that can be called to remove ads permanently, for example if your user buys an in-app purchase to remove them.

####1.1 - 2012-08-10
* Fixed a couple of issues in iOS 6
* Replaced #define's with const's
* Updated bundled AdMob SDK to version 6.1.4 and replaced some deprecated code
* Added a configuration option (boolean) to specify whether to use AdMob "[Smart Banners](https://developers.google.com/mobile-ads-sdk/docs/admob/smart-banners)" or not.
* Updated this readme with information on configuring.

####1.0 - 2012-04-07
* Initial release