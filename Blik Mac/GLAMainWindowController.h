//
//  GLAPrototypeBWindowController.h
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;
#import "GLAViewController.h"
#import "GLAMainSection.h"
#import "GLAMainSectionNavigator.h"
#import "GLAMainNavigationBarController.h"
#import "GLAProjectsListViewController.h"
#import "GLAProjectViewController.h"
#import "GLAMainNavigationBarController.h"
#import "GLAMainContentViewController.h"
#import "GLAView.h"


@interface GLAMainWindowController : NSWindowController <GLAMainNavigationBarControllerDelegate, GLAMainContentViewControllerDelegate, NSWindowDelegate, NSUserInterfaceValidations>

@property(readonly, nonatomic) GLAMainSectionNavigator *mainSectionNavigator;

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

@property(readonly, nonatomic) GLAMainSection *currentSection;

@property(nonatomic) NSTextView *fieldEditor;


//- (void)projectViewControllerDidBecomeActive:(GLAProjectViewController *)projectViewController;
//- (void)projectViewControllerDidBecomeInactive:(GLAProjectViewController *)projectViewController;


//- (void)transitionContentToSection:(GLAMainWindowControllerSection)newSection animate:(BOOL)animate;
//- (void)goToSection:(GLAMainWindowControllerSection)newSection animate:(BOOL)animate;
//- (void)didTransitionContentToViewController:(NSViewController *)viewController;

- (void)goToSection:(GLAMainSection *)newSection;
- (void)goToPreviousSection;

- (void)workOnProjectNow:(GLAProject *)project;

- (void)editProject:(GLAProject *)project;

#pragma mark Actions

- (IBAction)goToAll:(id)sender;
- (IBAction)goToNowProject:(id)sender;

- (BOOL)canWorkOnEditedProjectNow;
- (IBAction)workOnEditedProjectNow:(id)sender;

- (BOOL)canEditPrimaryFoldersOfViewedProject;
- (IBAction)editPrimaryFoldersOfViewedProject:(id)sender;

- (BOOL)canDeleteViewedProject;
- (IBAction)deleteViewedProject:(id)sender;

- (IBAction)addNewProject:(id)sender;

@property(nonatomic) BOOL hidesWhenInactive;
- (IBAction)toggleHideWhenInactive:(id)sender;

@end
