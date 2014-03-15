# CJPAdController 1.5.2

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
CJPAdController fully supports iOS 6.x and 7.x. It is also compatible with iOS 5.x although it is no longer tested on any devices running it. Technically it is also possible to make the class work with iOS 4.3, but support for this version was officially dropped as of October 2013.

## Screenshots

[![CJPAdController screenshot](http://i.imgur.com/6PMvwBom.png)](http://i.imgur.com/6PMvwBo.png) [![CJPAdController screenshot](http://i.imgur.com/hLGgUkZm.png)](http://i.imgur.com/hLGgUkZ.png)

[![CJPAdController screenshot](http://i.imgur.com/c0mvCv2m.png)](http://i.imgur.com/c0mvCv2.png) [![CJPAdController screenshot](http://i.imgur.com/MFA5gqkm.png)](http://i.imgur.com/MFA5gqk.png) [![CJPAdController screenshot](http://i.imgur.com/MFXBdskm.png)](http://i.imgur.com/MFXBdsk.png)

## Adding to your project

### Method 1 - CocoaPods

[CocoaPods](http://cocoapods.org) is the simplest way to get started. Just add `pod 'CJPAdController'` to your podfile and run `pod install`.

### Method 2 - Old School

**1.** Drop the `CJPAdController` and `GoogleAdMobAdsSdk` folders into your project. NOTE: You may wish to check if there is a newer [**AdMob SDK**](https://developers.google.com/mobile-ads-sdk/download#downloadios) available. Also note that you do not need to include any of the "Add-ons" bundled with the SDK.

**2.** Add the following frameworks to your project:

For iAd:

  1. `iAd.framework`
  2. `AdSupport.framework` (Must be optionally linked if targeting iOS 5.x)

For AdMob:

  1. `AudioToolbox.framework`
  2. `AVFoundation.framework`
  3. `CoreGraphics.framework`
  4. `CoreTelephony.framework`
  5. `MessageUI.framework`
  6. `StoreKit.framework`
  7. `SystemConfiguration.framework`

**3.** For AdMob to work you'll need to add `-ObjC` to the **Other Linker Flags** in your project ([**read this guide**](https://developers.google.com/mobile-ads-sdk/docs/) if you don't know how to do this).

## Usage

CJPAdController will automatically display your ads at the top or bottom of your view. It is designed to be used with either a UINavigationController or UITabBarController. Note that when used with a UITabBarController and displaying ads at the bottom of the view, you have an extra configuration option to choose whether you want the ads to be appear above or below the tab bar (as seen in the screenshots above).

**1.** Modify the constants at the top of `CJPAdController.h` to suit your needs - you'll be able to set various options including your AdMob Publisher ID, position in view, seconds to wait before showing ads, and more. The options are fairly self-explanatory and are commented.

**2.** Add `#import "CJPAdController.h"` to your `AppDelegate.h` file, then add `CJPAdController *_adController;` in the @interface like so:

```objective-c
@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    CJPAdController *_adController;
}
```

**3.** In your `AppDelegate.m` file, alloc your `UINavigationController` as usual, then initialise the adController with your navController set as the root view. The rootViewController of the window should then be set as the adController. Your code should look similar to the following:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

    RootViewController *rootVC = [[RootViewController alloc] init];
    _navController = [[UINavigationController alloc] initWithRootViewController:rootVC];
    _adController = [[CJPAdController sharedManager] initWithContentViewController:_navController];

    self.window.rootViewController = _adController;
    [self.window makeKeyAndVisible];
    return YES;
}
```

Or if you're using Storyboards:

```objective-c
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"StoryboardName" bundle:nil];
    UINavigationController *navController = (UINavigationController*)[storyboard instantiateInitialViewController];

    // init CJPAdController with the nav controller
    _adController = [[CJPAdController sharedManager] initWithContentViewController:navController];

    // set the ad controller as the root view controller
    self.window.rootViewController = _adController;
```


### Programatically hiding, removing, and restoring ads
There are several ways you can programatically manipulate ads in your view in order to hide, remove, or restore them.

To temporarily hide an ad (temporarily moves it off-screen, will reappear when next request is fired, usually within 1-5 minutes):
```objective-c
[[CJPAdController sharedManager] removeBanner:@"iAd" permanently:NO];
```

To remove an ad from the view indefinitely:
```objective-c
[[CJPAdController sharedManager] removeBanner:@"iAd" permanently:YES];
```

To restore ads to the view after calling the above method (note that if restoreBanner is left empty here, your default ad type will be used):
```objective-c
[[CJPAdController sharedManager] restoreBanner:@"iAd"];
```

To permanently remove ads forever (for example if a user makes an in-app purchase to remove ads, a boolean can be set in `NSUserDefaults` so this user will never be shown ads again):
```objective-c
[[CJPAdController sharedManager] removeAllAdsForever];
```

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