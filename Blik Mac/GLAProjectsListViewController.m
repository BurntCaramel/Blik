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


NSString *GLAProjectsListViewControllerDidClickOnProjectNotification = @"GLA.projectListViewController.didClickOnProject";
NSString *GLAProjectListsViewControllerDidPerformWorkOnProjectNowNotification = @"GLA.projectListViewController.didPerformWorkOnProjectNow";


@interface GLAProjectsListViewController ()

@property(nonatomic) NSArray *private_projects;

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
	
	NSScrollView *scrollView = [tableView enclosingScrollView];
	(scrollView.wantsLayer) = YES;
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

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	NSTableView *tableView = (self.tableView);
	NSScrollView *scrollView = [tableView enclosingScrollView];
	[scrollView flashScrollers];
}

#pragma mark Actions

- (NSArray *)projects
{
	return (self.private_projects);
}

- (void)setProjects:(NSArray *)projects
{
	(self.private_projects) = projects;
	[(self.tableView) reloadData];
}

- (IBAction)tableViewClicked:(id)sender
{
	NSInteger clickedRow = (self.tableView.clickedRow);
	if (clickedRow == -1) {
		return;
	}
	
	id project = (self.projects)[clickedRow];
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectsListViewControllerDidClickOnProjectNotification object:self userInfo:@{@"project": project}];
}

- (IBAction)workOnProjectNowClicked:(NSButton *)senderButton
{
	NSInteger projectIndex = (senderButton.tag);
	if (projectIndex == -1) {
		return;
	}
	
	id project = (self.projects)[projectIndex];
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectListsViewControllerDidPerformWorkOnProjectNowNotification object:self userInfo:@{@"project": project}];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.projects.count);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAProject *project = (self.projects)[row];
	return project;
}

#pragma mark Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAProjectOverviewTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	
	GLAUIStyle *activeStyle = [GLAUIStyle activeStyle];
	
	GLAProject *project = (self.projects)[row];
	NSString *displayName = (project.name);
	(cellView.objectValue) = displayName;
	(cellView.textField.stringValue) = displayName;
	
	NSTextField *plannedDateTextField = (cellView.plannedDateTextField);
	(plannedDateTextField.textColor) = (activeStyle.lightTextDisabledColor);
	//(plannedDateTextField.textColor) = (activeStyle.lightTextSecondaryColor);
	
	GLANavigationButton *workOnNowButton = (cellView.workOnNowButton);
	(workOnNowButton.alwaysHighlighted) = YES;
	(workOnNowButton.target) = self;
	(workOnNowButton.action) = @selector(workOnProjectNowClicked:);
	(workOnNowButton.tag) = row;
	//(workOnNowButton.textHighlightColor) = ([GLAUIStyle activeStyle].deleteProjectButtonColor);
	
	return cellView;
}

@end
