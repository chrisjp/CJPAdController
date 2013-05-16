# Changes

####1.4.2 - 17th May, 2013
* Fix for ads sliding up over TabBar (now slide up from underneath it)
 
####1.4.1 - 16th May, 2013
* Better support for use within apps using a UITabBarController - ads positioned at "bottom" can now be set to appear above or below the TabBar
 * A very basic TabBar example is included in the demo app (change the `useTabBar` BOOL to YES in AppDelegate.m to see it in action)

####1.4 - 7th April, 2013
* Updated bundled AdMob library to 6.3.0.
* iOS 4.3 is now the minimum supported version of iOS. This is due to Apple dropping support for the armv6 architecture.
* Removed deprecated code that was needed for iOS 4.0/4.1.
* Added a method to enable you to restore ads to your view after removing them.
* Updated the demo project to reflect the updated behaviour in removing and restoring ads, also added iPhone 5 support.

####1.3 - 12th September, 2012
* Fixed iOS 4 compatibility. Now works on iOS 4.0+ (was 4.2+ before).

####1.2 - 5th September, 2012
* Completely rewrote class - now shares a single instance of ADBannerView's across views, as recommended by Apple.
* Now a subclass of UIViewController - resizing ads when rotating is now done automatically.
* Added the ability to choose where ads are displayed within a view (top or bottom)
* Added a method that can be called to remove ads permanently, for example if your user buys an in-app purchase to remove them. 

####1.1 - 10th August, 2012
* Fixed a couple of issues in iOS 6
* Replaced #define's with const's
* Updated bundled AdMob SDK to version 6.1.4 and replaced some deprecated code
* Added a configuration option (boolean) to specify whether to use AdMob "[Smart Banners](https://developers.google.com/mobile-ads-sdk/docs/admob/smart-banners)" or not.
* Updated this readme with information on configuring.

####1.0 - 7th April, 2012
* Initial release