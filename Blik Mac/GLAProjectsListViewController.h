//
//  GLAProjectsListViewController.h
//  Blik
//
//  Created by Patrick Smith on 11/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAProject.h"


@interface GLAProjectsListViewController : GLAViewController

@property(nonatomic) IBOutlet NSView *hasContentView;
@property(nonatomic) IBOutlet NSViewController *emptyContentViewController;

@property(nonatomic) IBOutlet NSTableView *tableView;

@property(nonatomic) IBOutlet NSSearchField *nameSearchField;

@property(nonatomic) IBOutlet NSMenu *contextualMenu;
@property(nonatomic) IBOutlet NSMenuItem *hideFromLauncherMenuItem;


- (IBAction)tableViewClicked:(id)sender;

- (IBAction)permanentlyDeleteClickedProject:(id)sender;
- (IBAction)hideClickedProjectFromLauncherMenu:(id)sender;

@end

extern NSString *GLAProjectsListViewControllerDidChooseProjectNotification;
extern NSString *GLAProjectListsViewControllerDidPerformWorkOnProjectNowNotification;