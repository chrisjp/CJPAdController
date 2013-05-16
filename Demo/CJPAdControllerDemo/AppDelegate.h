//
//  AppDelegate.h
//  CJPAdControllerDemo
//
//  Created by Chris Phillips on 19/11/2011.
//  Copyright (c) 2011 ChrisJP. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CJPAdController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    CJPAdController *_adController;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navController;
@property (strong, nonatomic) UITabBarController *tabController;

@end
