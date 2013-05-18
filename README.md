# CJPAdController 1.4.3

CJPAdController is a singleton class allowing easy implementation of iAds and Google AdMob ads in your iOS app. It supports all devices and orientations, and works on iOS 4.3+

## Features
* Supports iPhone, iPod touch and iPad, in any orientation
* Choose whether to show both iAd and AdMob, or just one of them
* Choose whether iAd or AdMob is your default ads, falling back to the other if your default is unable to load an ad
* Ability to choose where ads are displayed within a view (top or bottom)
* Specify a time delay for when to start showing ads in a view
* Automatically hides from view if there are no ads to display
* Support for hiding ads from users who have purchased a "Remove Ads" In-App Purchase (assumes you store a boolean value for this in `NSUserDefaults`)

## Screenshots

[![CJPAdController screenshot](http://i.imgur.com/6PMvwBom.png)](http://i.imgur.com/6PMvwBo.png) [![CJPAdController screenshot](http://i.imgur.com/hLGgUkZm.png)](http://i.imgur.com/hLGgUkZ.png)

[![CJPAdController screenshot](http://i.imgur.com/c0mvCv2m.png)](http://i.imgur.com/c0mvCv2.png) [![CJPAdController screenshot](http://i.imgur.com/MFA5gqkm.png)](http://i.imgur.com/MFA5gqk.png) [![CJPAdController screenshot](http://i.imgur.com/MFXBdskm.png)](http://i.imgur.com/MFXBdsk.png)

## Usage

CJPAdController will automatically display your ads at the top or bottom of your view. It is designed to be used with either a UINavigationController or UITabBarController. Note that when used with a UITabBarController and display ads at the bottom of the view, you have an extra configuration option to choose whether you want the ads to be appear above or below the tab bar (as seen in the screenshots above).

### Adding to your project

**1.** Add both `CJPAdController.h` and `CJPAdController.m` to your project. 

**2.** Modify the constants at the top of `CJPAdController.h` to suit your needs - here you'll be able to set various options, including your AdMob Publisher ID, position in view, seconds to wait before showing ads, and more. The options are fairly self-explanatory and the code is commented.

**3.** Add `#import "CJPAdController.h"` to your app delegate header file, then add `CJPAdController *_adController;` in the @interface like so:

```objective-c
@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    CJPAdController *_adController;
}
```

**4.** And in your app delegate method file, alloc your `UINavigationController` as usual, then init the adController with your navController set as the root view. The rootViewController of the window should then be set as the adController. Your code should look similar to the following:

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

**5.** You're almost done! Just check the other requirements below to make sure you've got all the right frameworks included in your project.
  
### Other Requirements
In order to compile, you'll need to have these frameworks included in your project:

For iAd:

  1. `iAd.framework`
  2. `AdSupport.framework` (Optional)
  
For AdMob:

  1. `AudioToolbox.framework`
  2. `MessageUI.framework`
  3. `SystemConfiguration.framework`
  4. `CoreGraphics.framework`
  5. `StoreKit.framework`
  6. `AdSupport.framework` (Optional)

  
**NOTE:** For AdMob to work ensure you also include the [**AdMob SDK**](https://developers.google.com/mobile-ads-sdk/download#downloadios) files, and please also read the note on setting [**Other Linker Flags**](https://developers.google.com/mobile-ads-sdk/docs/) in your project. You should use the latest SDK in your project (at least 6.2.0 or greater). Version 6.3.0 is included in the demo app in this project.


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

## To-Do
Possible features to be added include:

* Add support for additional ad networks


## Licence and Attribution
If you're feeling kind you can provide attribution and a link to [this GitHub project](https://github.com/chrisjp/CJPAdController), but you don't have to.

### Licence
Copyright (c) 2011-2013 Chris Phillips

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