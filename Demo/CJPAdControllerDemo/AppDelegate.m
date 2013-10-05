//
//  AppDelegate.m
//  CJPAdControllerDemo
//
//  Created by Chris Phillips on 19/11/2011.
//  Copyright (c) 2011 ChrisJP. All rights reserved.
//

#import "AppDelegate.h"
#import "RootViewController.h"
#import "AnotherExample.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize navController = _navController;
@synthesize tabController = _tabController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    //[[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    /*
          
     By default this demo app is set up to use a UINavigationController.
     Change the boolean below to YES if you wish to see it using a UITabBarController instead.
     
    */
    BOOL useTabBar = NO;
    
    if (!useTabBar) {
        // 1. UINavigationController Example
        
        // init the nav controller and the root view controller
        RootViewController *rootVC = [[RootViewController alloc] init];
        _navController = [[UINavigationController alloc] initWithRootViewController:rootVC];
        
        // init CJPAdController with the nav controller
        _adController = [[CJPAdController sharedManager] initWithContentViewController:_navController];
        
        // set the ad controller as the root view controller
        self.window.rootViewController = _adController;
    }
    else {
        // 2. UITabBarController Example
        
        // init the view controllers
        UIViewController *viewController1 = [[RootViewController alloc] init];
        UIViewController *viewController2 = [[AnotherExample alloc] init];
        
        // init the navigation
        UINavigationController *navController1 = [[UINavigationController alloc] initWithRootViewController:viewController1];
        navController1.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"CJPAdController Demo" image:nil tag:666];
        UINavigationController *navController2 = [[UINavigationController alloc] initWithRootViewController:viewController2];
        navController2.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Another Tab" image:nil tag:667];
        
        // init the tab bar controller
        _tabController = [[UITabBarController alloc] init];
        _tabController.viewControllers = @[navController1, navController2];
        
        // init CJPAdController with the tab bar controller
        _adController = [[CJPAdController sharedManager] initWithContentViewController:_tabController];
        
        // set the ad controller as the root view controller
        self.window.rootViewController = _adController;
    }
    
    
    // IF YOU ARE USING STORYBOARDS, YOUR CODE SHOULD LOOK SIMILAR TO THE FOLLOWING:
    /*
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"StoryboardName" bundle:nil];
    UINavigationController *navController = (UINavigationController*)[storyboard instantiateInitialViewController];
    
    // init CJPAdController with the nav controller
    _adController = [[CJPAdController sharedManager] initWithContentViewController:navController];
    
    // set the ad controller as the root view controller
    self.window.rootViewController = _adController;
    */
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
