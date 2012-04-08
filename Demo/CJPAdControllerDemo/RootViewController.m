//
//  RootViewController.m
//  CJPAdControllerDemo
//
//  Created by Chris Phillips on 06/04/2012.
//  Copyright (c) 2012 ChrisJP. All rights reserved.
//

#import "RootViewController.h"
#import "CJPAdController.h"
#import "AnotherExample.h"

@interface RootViewController ()

@end

@implementation RootViewController

@synthesize scrollView = _scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    // Add ads to our view
    [[CJPAdController sharedManager] addBannerToViewController:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.title = @"CJPAdController Demo";
    
    // Let's put everything in a ScrollView
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:self.scrollView];
    
    // TextView describing basic functionality
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 320)];
    textView.text = @"After a couple of seconds you should see ads appear at the bottom of this view.\n\nYou can rotate your device any way you want; the ad will automatically resize and/or reposition itself.\n\nTap the button below to see it implemented in a UITableView. If you rotate while on the TableView and come back to this view, you'll notice the ad displayed here (if any) will have automatially been rotated to the correct orientation!";
    textView.autoresizingMask =  UIViewAutoresizingFlexibleWidth;
    textView.backgroundColor = [UIColor clearColor];
    textView.editable = NO;
    textView.scrollEnabled = NO;
    textView.font = [UIFont systemFontOfSize:16.0];
    textView.textColor = [UIColor darkTextColor];
    [self.scrollView addSubview:textView];
    CGRect textFrame = textView.frame;
    textFrame.size.height = textView.contentSize.height;
    textView.frame = textFrame;
    
    // Button to take us to an alternative example
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(0, textView.frame.size.height+10, 180, 40);
    button.center = CGPointMake(self.view.frame.size.width/2, button.center.y);
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [button setTitle:@"See Another Example" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(anotherExample) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:button];
    
    // Set scrollview content size
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, button.frame.size.height+button.frame.origin.y+10);
}

- (void)anotherExample
{
    AnotherExample *example = [[AnotherExample alloc] init];
    [self.navigationController pushViewController:example animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [[CJPAdController sharedManager] rotateAdToInterfaceOrientation:toInterfaceOrientation];
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [[CJPAdController sharedManager] fixAdViewAfterRotation];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

@end
