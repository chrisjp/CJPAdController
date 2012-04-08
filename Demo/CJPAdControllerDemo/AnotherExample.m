//
//  AnotherExample.m
//  CJPAdControllerDemo
//
//  Created by Chris Phillips on 06/04/2012.
//  Copyright (c) 2012 ChrisJP. All rights reserved.
//

#import "AnotherExample.h"
#import "CJPAdController.h"

@interface AnotherExample ()

@end

@implementation AnotherExample

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

    self.title = @"Another Example";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 9;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];        
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Configure the cell...
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Just another example";
            break;
            
        case 1:
            cell.textLabel.text = @"with an ad presented";
            break;
        
        case 2:
            cell.textLabel.text = @"at the bottom";
            break;
        
        case 3:
            cell.textLabel.text = @"of the view.";
            break;
        case 4:
            cell.textLabel.text = @"The height gets set";
            break;
        case 5:
            cell.textLabel.text = @"so that no content is";
            break;
        case 6:
            cell.textLabel.text = @"hidden behind the ads.";
            break;
        case 7:
            cell.textLabel.text = @"Everything is still visible";
            break;
        case 8:
            cell.textLabel.text = @"Wonderful!";
            break;
            
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
