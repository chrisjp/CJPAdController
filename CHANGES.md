# Changes

##1.2 - 5th September, 2012
* Completely rewrote class - now shares a single instance of ADBannerView's across views, as recommended by Apple.
* Now a subclass of UIViewController - resizing ads when rotating is now done automatically.
* Added the ability to choose where ads are displayed within a view (top or bottom)
* Added a method that can be called to remove ads permanently, for example if your user buys an in-app purchase to remove them. 

##1.1 - 10th August, 2012
* Fixed a couple of issues in iOS 6
* Replaced #define's with const's
* Updated bundled AdMob SDK to version 6.1.4 and replaced some deprecated code
* Added a configuration option (boolean) to specify whether to use AdMob "[Smart Banners](https://developers.google.com/mobile-ads-sdk/docs/admob/smart-banners)" or not.
* Updated this readme with information on configuring.

##1.0 - 7th April, 2012
* Initial release