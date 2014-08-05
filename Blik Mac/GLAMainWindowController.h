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
#import "GLAMainContentViewController.h"
#import "GLAView.h"


typedef NS_ENUM(NSInteger, GLAMainWindowControllerSection) {
	GLAMainWindowControllerSectionUnknown,
	GLAMainWindowControllerSectionAll,
	GLAMainWindowControllerSectionToday,
	GLAMainWindowControllerSectionPlanned,
	GLAMainWindowControllerSectionAllEditProject,
	GLAMainWindowControllerSectionPlannedEditProject,
	GLAMainWindowControllerSectionAddNewProject
};


@interface GLAMainWindowController : NSWindowController <GLAMainNavigationBarControllerDelegate, GLAMainContentViewControllerDelegate>

@property (nonatomic) GLAMainNavigationBarController *mainNavigationBarController;
@property (nonatomic) GLAMainContentViewController *contentViewController;

@property (nonatomic) GLAProjectsListViewController *allProjectsViewController;
@property (nonatomic) GLAProjectsListViewController *plannedProjectsViewController;

@property (nonatomic) GLAProjectViewController *nowProjectViewController;
@property (nonatomic) GLAProjectViewController *editedProjectViewController;
@property (nonatomic) GLAProjectViewController *addedProjectViewController;

@property (nonatomic) GLAMainWindowControllerSection currentSection;
@property (readonly, nonatomic) GLAProjectViewController *activeProjectViewController;

@property (nonatomic) IBOutlet NSView *barHolderView;
@property (nonatomic) IBOutlet NSView *contentView;


//- (void)projectViewControllerDidBecomeActive:(GLAProjectViewController *)projectViewController;
//- (void)projectViewControllerDidBecomeInactive:(GLAProjectViewController *)projectViewController;


//- (void)transitionContentToSection:(GLAMainWindowControllerSection)newSection animate:(BOOL)animate;
//- (void)goToSection:(GLAMainWindowControllerSection)newSection animate:(BOOL)animate;
//- (void)didTransitionContentToViewController:(NSViewController *)viewController;

- (GLAMainContentSection)contentSectionForNavigationSection:(GLAMainNavigationSection)navigationSection;


- (void)projectListViewControllerDidClickOnProjectNotification:(NSNotification *)note;
- (void)projectListViewControllerDidPerformWorkOnProjectNowNotification:(NSNotification *)note;

@end
