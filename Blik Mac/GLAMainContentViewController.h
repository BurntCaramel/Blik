//
//  GLAMainContentViewController.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAProjectsListViewController.h"
#import "GLAProjectViewController.h"
@class GLAProject;
@protocol GLAMainContentViewControllerDelegate;


typedef NS_ENUM(NSInteger, GLAMainContentSection) {
	GLAMainContentSectionUnknown,
	GLAMainContentSectionAll,
	GLAMainContentSectionToday,
	GLAMainContentSectionPlanned,
	GLAMainContentSectionAllEditProject,
	GLAMainContentSectionPlannedEditProject,
	GLAMainContentSectionAddNewProject
};


@interface GLAMainContentViewController : GLAViewController

@property(nonatomic) id<GLAMainContentViewControllerDelegate> delegate;

@property(nonatomic) GLAMainContentSection currentSection;
@property(readonly, nonatomic) GLAProjectViewController *activeProjectViewController;

@property(nonatomic) GLAProjectsListViewController *allProjectsViewController;
@property(nonatomic) GLAProjectsListViewController *plannedProjectsViewController;

@property(nonatomic) GLAProjectViewController *nowProjectViewController;
@property(nonatomic) GLAProjectViewController *editedProjectViewController;
@property(nonatomic) GLAProjectViewController *addedProjectViewController;

- (void)setUpAllProjectsViewControllerIfNeeded;
- (void)setUpPlannedProjectsViewControllerIfNeeded;
- (void)setUpNowProjectViewControllerIfNeeded;
- (void)setUpEditedProjectViewControllerIfNeeded;
- (void)setUpAddedProjectViewControllerIfNeeded;

- (GLAViewController *)viewControllerForSection:(GLAMainContentSection)section;

#pragma mark -

- (void)workOnProjectNow:(GLAProject *)project;

- (void)editProject:(GLAProject *)project;
- (void)enterAddedProject:(GLAProject *)project;
- (void)endEditingProject:(GLAProject *)project previousSection:(GLAMainContentSection)section;

- (void)transitionToSection:(GLAMainContentSection)newSection animate:(BOOL)animate;

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

@end
