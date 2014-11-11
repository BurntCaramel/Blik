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

@property(nonatomic) IBOutlet NSTableView *tableView;

@property(nonatomic) IBOutlet NSMenu *contextualMenu;

// You set the projects.
@property(copy, nonatomic) NSArray *projects;


- (IBAction)tableViewClicked:(id)sender;

- (IBAction)permanentlyDeleteClickedProject:(id)sender;

@end

extern NSString *GLAProjectsListViewControllerDidChooseProjectNotification;
extern NSString *GLAProjectListsViewControllerDidPerformWorkOnProjectNowNotification;