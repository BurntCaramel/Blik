//
//  GLAProjectsListViewController.m
//  Blik
//
//  Created by Patrick Smith on 11/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAProjectsListViewController.h"
#import "GLAUIStyle.h"
#import "GLAProjectOverviewTableCellView.h"


NSString *GLAProjectListViewControllerDidClickOnProjectNotification = @"GLA.projectListViewController.didClickOnProject";


@interface GLAProjectsListViewController ()

@end

@implementation GLAProjectsListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)prepareViews
{
	NSTableView *tableView = (self.tableView);
	(tableView.backgroundColor) = ([GLAUIStyle activeStyle].contentBackgroundColor);
	(tableView.enclosingScrollView.backgroundColor) = ([GLAUIStyle activeStyle].contentBackgroundColor);
}

- (void)loadView
{
	[super loadView];
	
	[self prepareViews];
}

- (void)awakeFromNib
{
	//[self prepareViews];
}

#pragma mark Actions

- (IBAction)tableViewClicked:(id)sender
{
	NSInteger clickedRow = (self.tableView.clickedRow);
	if (clickedRow == -1) {
		return;
	}
	
	id project = (self.projects)[clickedRow];
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectListViewControllerDidClickOnProjectNotification object:self userInfo:@{@"project": project}];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.projects.count);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return (self.projects)[row];
}

#pragma mark Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAProjectOverviewTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	
	NSString *displayName = (self.projects)[row];
	(cellView.objectValue) = displayName;
	(cellView.textField.stringValue) = displayName;
	
	GLANavigationButton *workOnNowButton = (cellView.workOnNowButton);
	(workOnNowButton.alwaysHighlighted) = YES;
	//(workOnNowButton.textHighlightColor) = ([GLAUIStyle activeStyle].deleteProjectButtonColor);
	
	return cellView;
}


@end
