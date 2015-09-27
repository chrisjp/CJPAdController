//
//  AnotherViewController.m
//  CJPAdControllerDemo
//
//  Created by Chris Phillips on 06/02/2015.
//  Copyright (c) 2015 Midnight Labs. All rights reserved.
//

#import "AnotherViewController.h"

@interface AnotherViewController ()

@end

@implementation AnotherViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self.parentViewController.parentViewController isKindOfClass:[UITabBarController class]])
        self.title = @"Another Tab";
    else
        self.title = @"A UITableView";
    
    self.tableView.showsVerticalScrollIndicator = YES;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) return 110.0;
    return 44.0;
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
            cell.textLabel.text = @"Everything is still visible.";
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
