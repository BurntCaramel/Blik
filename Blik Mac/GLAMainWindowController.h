//
//  GLAPrototypeBWindowController.h
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAViewController.h"
#import "GLAMainContentSection.h"
#import "GLAMainNavigationBarController.h"
#import "GLAProjectsListViewController.h"
#import "GLAProjectViewController.h"
#import "GLAMainNavigationBarController.h"
#import "GLAMainContentViewController.h"
#import "GLAView.h"


@interface GLAMainWindowController : NSWindowController <GLAMainNavigationBarControllerDelegate, GLAMainContentViewControllerDelegate, NSWindowDelegate, NSUserInterfaceValidations>

@property(nonatomic) IBOutlet NSView *barHolderView;
@property(nonatomic) GLAViewController *mainNavigationHolderViewController;
@property(nonatomic) GLAMainNavigationBarController *mainNavigationBarController;

@property(nonatomic) IBOutlet NSView *contentView;
@property(nonatomic) GLAMainContentViewController *mainContentViewController;

@property(nonatomic) GLAProjectsListViewController *allProjectsViewController;
@property(nonatomic) GLAProjectsListViewController *plannedProjectsViewController;

@property(nonatomic) GLAProjectViewController *nowProjectViewController;
@property(nonatomic) GLAProjectViewController *editedProjectViewController;
@property(nonatomic) GLAProjectViewController *addedProjectViewController;
@property(readonly, nonatomic) GLAProjectViewController *activeProjectViewController;

@property(nonatomic) GLAMainContentSection *currentSection;

@property(nonatomic) NSTextView *fieldEditor;


//- (void)projectViewControllerDidBecomeActive:(GLAProjectViewController *)projectViewController;
//- (void)projectViewControllerDidBecomeInactive:(GLAProjectViewController *)projectViewController;


//- (void)transitionContentToSection:(GLAMainWindowControllerSection)newSection animate:(BOOL)animate;
//- (void)goToSection:(GLAMainWindowControllerSection)newSection animate:(BOOL)animate;
//- (void)didTransitionContentToViewController:(NSViewController *)viewController;

- (void)goToSection:(GLAMainContentSection *)newSection;
- (void)goToPreviousSection;

- (void)workOnProjectNow:(GLAProject *)project;

- (void)editProject:(GLAProject *)project;

- (void)showAddNewProject;
- (void)showAddNewCollectionToProject:(GLAProject *)project;

#pragma mark Actions

- (IBAction)goToAll:(id)sender;
- (IBAction)goToToday:(id)sender;
- (IBAction)goToPlanned:(id)sender;
- (IBAction)workOnEditedProjectNow:(id)sender;

- (IBAction)addNewProject:(id)sender;

- (void)projectListViewControllerDidClickOnProjectNotification:(NSNotification *)note;
- (void)projectListViewControllerDidPerformWorkOnProjectNowNotification:(NSNotification *)note;

@end
