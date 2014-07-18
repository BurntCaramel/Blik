//
//  GLAPrototypeBWindowController.h
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAViewController.h"
#import "GLAMainNavigationBarController.h"
#import "GLAProjectsListViewController.h"
#import "GLAProjectViewController.h"
#import "GLAMainNavigationBarController.h"
#import "GLAView.h"


typedef NS_ENUM(NSInteger, GLAMainWindowControllerSection) {
	GLAMainWindowControllerSectionAll,
	GLAMainWindowControllerSectionToday,
	GLAMainWindowControllerSectionPlanned,
	GLAMainWindowControllerSectionAllEditProject,
	GLAMainWindowControllerSectionPlannedEditProject
};


@interface GLAMainWindowController : NSWindowController <GLAMainNavigationBarControllerDelegate>

@property (nonatomic) GLAMainNavigationBarController *mainNavigationBarController;

@property (nonatomic) GLAViewController *contentViewController;

@property (nonatomic) GLAProjectsListViewController *allProjectsViewController;
@property (nonatomic) GLAProjectsListViewController *plannedProjectsViewController;

@property (nonatomic) GLAProjectViewController *nowProjectViewController;
@property (nonatomic) GLAProjectViewController *editedProjectViewController;

@property (nonatomic) GLAMainWindowControllerSection currentSection;

@property (nonatomic) IBOutlet NSView *barHolderView;
@property (nonatomic) IBOutlet NSView *contentView;


- (void)projectViewControllerDidBecomeActive:(GLAProjectViewController *)projectViewController;
- (void)projectViewControllerDidBecomeInactive:(GLAProjectViewController *)projectViewController;

@end
