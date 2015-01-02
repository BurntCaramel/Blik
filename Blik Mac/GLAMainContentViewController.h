//
//  GLAMainContentViewController.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAMainSection.h"
#import "GLAMainSectionNavigator.h"
#import "GLAProjectsListViewController.h"
#import "GLAProjectViewController.h"
#import "GLANoNowProjectViewController.h"
#import "GLAEmptyAllProjectsViewController.h"
#import "GLAAddNewProjectViewController.h"
#import "GLAAddNewCollectionViewController.h"
#import "GLAAddCollectedFilesChoiceActions.h"
@class GLAProject;
@protocol GLAMainContentViewControllerDelegate;

/*
typedef NS_ENUM(NSInteger, GLAMainContentSection) {
	GLAMainContentSectionUnknown,
	GLAMainContentSectionAll,
	GLAMainContentSectionToday,
	GLAMainContentSectionPlanned,
	GLAMainContentSectionAllEditProject,
	GLAMainContentSectionPlannedEditProject,
	GLAMainContentSectionAddNewProject,
	GLAMainContentSectionCollection
};
*/

@interface GLAMainContentViewController : GLAViewController

@property(nonatomic) id<GLAMainContentViewControllerDelegate> delegate;

@property(nonatomic) GLAMainSectionNavigator *sectionNavigator;
@property(readonly, nonatomic) GLAMainSection *currentSection;

// Project List

@property(nonatomic) GLAProjectsListViewController *allProjectsViewController;
@property(nonatomic) GLAProjectsListViewController *plannedProjectsViewController;

@property(nonatomic) GLAEmptyAllProjectsViewController *emptyAllProjectsViewController;

// Single Project

@property(readonly, nonatomic) GLAProjectViewController *activeProjectViewController;
@property(nonatomic) GLAProjectViewController *nowProjectViewController;
@property(nonatomic) GLAProjectViewController *editedProjectViewController;

@property(nonatomic) GLANoNowProjectViewController *blankNowProjectViewController;
@property(nonatomic) BOOL isShowingBlankNowProject;

// Collection

@property(nonatomic) GLAViewController *activeCollectionViewController;

// Adding Project or Collection

@property(nonatomic) GLAAddNewProjectViewController *addedProjectViewController;
@property(nonatomic) GLAAddNewCollectionViewController *addedCollectionViewController;

- (void)setUpAllProjectsViewControllerIfNeeded;
- (void)setUpPlannedProjectsViewControllerIfNeeded;
- (void)setUpNowProjectViewControllerIfNeeded;
- (void)setUpEditedProjectViewControllerIfNeeded;
- (void)setUpAddedProjectViewControllerIfNeeded;
- (void)setUpAddedCollectionViewControllerIfNeeded;

- (GLAViewController *)viewControllerForSection:(GLAMainSection *)section;

#pragma mark -

- (void)changeNowProject:(GLAProject *)project;

- (void)workOnProjectNow:(GLAProject *)project;

- (void)editProject:(GLAProject *)project;
//- (void)enterAddedProject:(GLAProject *)project;
//- (void)endEditingProject:(GLAProject *)project;

//- (void)enterAddedCollection:(GLAProject *)project;

- (void)transitionToSection:(GLAMainSection *)newSection fromSection:(GLAMainSection *)outSection animate:(BOOL)animate;

- (void)goToSection:(GLAMainSection *)newSection;

#pragma mark -

- (void)enterCollection:(GLACollection *)collection;

- (IBAction)addNewFilesListCollection:(id)sender;

#pragma mark -

- (void)projectViewControllerDidBecomeActive:(GLAProjectViewController *)projectViewController;
- (void)projectViewControllerDidBecomeInactive:(GLAProjectViewController *)projectViewController;

@end


@protocol GLAMainContentViewControllerDelegate <NSObject>

#pragma mark Project View Controller

- (void)mainContentViewController:(GLAMainContentViewController *)contentViewController projectViewControllerDidBecomeActive:(GLAProjectViewController *)projectViewController;

- (void)mainContentViewController:(GLAMainContentViewController *)contentViewController projectViewControllerDidBecomeInactive:(GLAProjectViewController *)projectViewController;

#pragma mark Projects List View Controller

- (void)mainContentViewController:(GLAMainContentViewController *)contentViewController projectsListViewController:(GLAProjectsListViewController *)projectsListViewController didClickOnProject:(GLAProject *)project;

- (void)mainContentViewController:(GLAMainContentViewController *)contentViewController projectsListViewController:(GLAProjectsListViewController *)projectsListViewController didPerformWorkOnProject:(GLAProject *)project;

#pragma mark Adding New Project

- (void)mainContentViewController:(GLAMainContentViewController *)contentViewController addNewProjectViewController:(GLAAddNewProjectViewController *)addNewProjectViewController didConfirmCreatingProject:(GLAProject *)project;

#pragma mark Adding New Collection

- (void)mainContentViewController:(GLAMainContentViewController *)contentViewController addNewCollectionViewControllerDidBecomeActive:(GLAAddNewCollectionViewController *)addNewCollectionViewController;

- (void)mainContentViewController:(GLAMainContentViewController *)contentViewController addNewCollectionViewController:(GLAAddNewCollectionViewController *)addNewCollectionViewController didConfirmCreatingCollection:(GLACollection *)collection inProject:(GLAProject *)project;

@end
