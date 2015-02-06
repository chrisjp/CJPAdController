# CJPAdController 1.6.3

CJPAdController is a singleton class allowing easy implementation of iAds and Google AdMob ads in your iOS app. It supports all devices and orientations, and works on iOS 5.0+

## Features
* Supports iPhone, iPod touch and iPad in any orientation
* Choose whether to show both iAd and AdMob, or just one of them
* Choose whether iAd or AdMob is your default ads, falling back to the other if your default is unable to load an ad
* Ability to choose where ads are displayed within a view (top or bottom)
* Specify a time delay for when to start showing ads in a view
* Automatically hides from view if there are no ads to display
* Support for hiding ads from users who have purchased a "Remove Ads" In-App Purchase (assumes you store a boolean value for this in `NSUserDefaults`)

## iOS Version Support / Compatibility
CJPAdController supports versions of iOS >= 6.x. It is compatible with iOS 5.x too and should work just fine, but do bear in mind I can no longer test on any devices running iOS 5.

## Screenshots

[![CJPAdController screenshot](http://i.imgur.com/6PMvwBom.png)](http://i.imgur.com/6PMvwBo.png) [![CJPAdController screenshot](http://i.imgur.com/hLGgUkZm.png)](http://i.imgur.com/hLGgUkZ.png)

[![CJPAdController screenshot](http://i.imgur.com/c0mvCv2m.png)](http://i.imgur.com/c0mvCv2.png) [![CJPAdController screenshot](http://i.imgur.com/MFXBdskm.png)](http://i.imgur.com/MFXBdsk.png)

## Adding to your project

### Method 1 - CocoaPods

[CocoaPods](http://cocoapods.org) is the simplest way to get started. Just add `pod 'CJPAdController'` to your podfile and run `pod install`.

### Method 2 - Old School

**1.** Drop the `CJPAdController` and `GoogleMobileAdsSdk` folders into your project. NOTE: You may wish to check if there is a newer [**AdMob SDK**](https://developers.google.com/mobile-ads-sdk/download#downloadios) available, at least version 6.12.0 is recommended. NOTE 2: You don't need to include any of the "Add-ons" bundled with the SDK.

**2.** Add the following frameworks to your project:

For iAd:

  1. `iAd.framework`
  2. `AdSupport.framework` (Weak link if targeting iOS 5.x)

For AdMob:

  1. `AudioToolbox.framework`
  2. `AVFoundation.framework`
  3. `CoreGraphics.framework`
  4. `CoreTelephony.framework`
  5. `MessageUI.framework`
  6. `StoreKit.framework`
  7. `SystemConfiguration.framework`
  8. `EventKit.framework`
  9. `EventKitUI.framework`

**3.** For AdMob to work you'll need to add `-ObjC` to the **Other Linker Flags** in your project ([**read this guide**](https://developers.google.com/mobile-ads-sdk/docs/) if you don't know how to do this).

## Usage

CJPAdController will automatically display ads at the top or bottom of your view. It is designed to be used with either a UINavigationController or UITabBarController.

**1.** `#import "CJPAdController.h"` in your `AppDelegate.m`.

**2.** In `application didFinishLaunchingWithOptions`, configure CJPAdController to your liking using the sharedInstance:

```objective-c
    [CJPAdController sharedInstance].adNetworks = @[@(CJPAdNetworkiAd), @(CJPAdNetworkAdMob)];
    [CJPAdController sharedInstance].adPosition = CJPAdPositionBottom;
    [CJPAdController sharedInstance].initialDelay = 2.0;
    // AdMob specific
    [CJPAdController sharedInstance].adMobUnitID = @"ca-app-pub-1234567890987654/1234567890";
```

**3.** Set up your navigation/tabbar controller as usual, then tell CJPAdController to start serving ads in it.

```objective-c
    [[CJPAdController sharedInstance] startWithViewController:_yourNavController];
```

**4.** One more thing... you'll need to set the window's rootViewController to the sharedInstance of CJPAdController

```objective-c
    self.window.rootViewController = [CJPAdController sharedInstance];
```

## Configuration Options

### Choosing which ad networks are used, and which is preferred

CJPAdController assumes you will be using both iAd and AdMob as that is precisely what this class was written for. By default both will be used and iAd will be the preferred option. You can override this by passing the array in a different order (the first value in the array will be set as your preferred ads), you can even exclude one of the networks if you wish.

```objective-c
[CJPAdController sharedInstance].adNetworks = @[@(CJPAdNetworkAdMob), @(CJPAdNetworkiAd)];
```

### Choosing the position of the ads
By default, ads will slide up from the bottom of the view and be pinned there. Alternatively, you may wish to reverse this and have them slide down and stay at the top of your view.

```objective-c
[CJPAdController sharedInstance].adPosition = CJPAdPositionTop;
```

### Delay the appearance of ads after app has launched
By default, ads will be requested as soon as your app is launched. You can delay this by providing an NSTimeInterval, the following code would wait 2 seconds after your app has launched before requesting an ad:

```objective-c
[CJPAdController sharedInstance].initialDelay = 2.0;
```

### Use within custom view controllers
If you are trying to implement CJPAdController in a custom view controller that isn't a subclass of UINavigationController or UITabBarController, you may see issues causing ads to display incorrectly or not at all. In this case it is possible to override the `isNavController` property which some users have had success with.

```objective-c
[CJPAdController sharedInstance].overrideIsNavController = YES;
```

## More
There are a number of AdMob specific options that can also be configured, as well as a number of general methods for hiding, removing, restoring ads etc.
AdMob ads may also be targeted based on your users' age, gender and location. Please read the comments in the header file before using any of these.
You can see an example of these in the demo project, furthermore, the header file is well commented with information on what each method does and how you might want to use them both in testing or in production.


## Licence and Attribution
If you're feeling kind you can provide attribution and a link to [this GitHub project](https://github.com/chrisjp/CJPAdController).


### Licence
Copyright (c) 2011-2014 Chris Phillips

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.