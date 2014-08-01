//
//  GLAProjectsListViewController.h
//  Blik
//
//  Created by Patrick Smith on 11/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAProject.h"


@interface GLAProjectsListViewController : GLAViewController

@property (nonatomic) IBOutlet NSTableView *tableView;

//@property (copy, nonatomic) NSMutableArray *mutableProjects;
@property (copy, nonatomic) NSArray *projects;


- (void)viewDidAppear;

- (IBAction)tableViewClicked:(id)sender;

@end

extern NSString *GLAProjectListViewControllerDidClickOnProjectNotification;
extern NSString *GLAProjectListViewControllerDidPerformWorkOnProjectNowNotification;