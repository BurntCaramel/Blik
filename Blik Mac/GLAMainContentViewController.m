//
//  GLAMainContentViewController.m
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAMainContentViewController.h"
#import "GLAProject.h"
#import "GLATableProjectRowView.h"
#import "GLAProjectManager.h"
@import QuartzCore;

#import "GLAFileCollectionViewController.h"
#import "GLAAddCollectedFilesChoiceActions.h"
#import "GLAPendingAddedCollectedFilesInfo.h"


@interface GLAMainContentViewController ()

@end

@interface GLAMainContentViewController (GLAProjectViewControllerDelegate) <GLAProjectViewControllerDelegate>

@end

@implementation GLAMainContentViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
	}
	return self;
}

- (void)dealloc
{
	[self stopSectionNavigatorObserving];
}

- (void)setUpSectionNavigatorObserving
{
	GLAMainSectionNavigator *sectionNavigator = (self.sectionNavigator);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Now Project
	[nc addObserver:self selector:@selector(sectionNavigatorDidChangeCurrentSection:) name:GLAMainSectionNavigatorDidChangeCurrentSectionNotification object:sectionNavigator];
}

- (void)stopSectionNavigatorObserving
{
	GLAMainSectionNavigator *sectionNavigator = (self.sectionNavigator);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Stop observing any notifications on the project manager.
	[nc removeObserver:self name:nil object:sectionNavigator];
}

#pragma mark - Setting Up View Controllers -

- (void)addViewIfNeeded:(NSView *)view layout:(BOOL)layout
{
	if (!(view.superview)) {
		[self fillViewWithChildView:view];
		
		if (layout) {
			[(self.view) layoutSubtreeIfNeeded];
		}
	}
}

- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView
{
	[self addViewIfNeeded:innerView layout:YES];
	return [super layoutConstraintWithIdentifier:baseIdentifier forChildView:innerView];
}

#pragma mark All Projects

- (void)setUpAllProjectsViewControllerIfNeeded
{
	if (self.allProjectsViewController) {
		return;
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	GLAProjectsListViewController *controller = [[GLAProjectsListViewController alloc] initWithNibName:@"GLAProjectsListViewController" bundle:nil];
	(controller.view.identifier) = @"allProjects";
	
	[self setUpEmptyAllProjectsViewControllerIfNeeded];
	(controller.emptyContentViewController) = (self.emptyAllProjectsViewController);
	
	(self.allProjectsViewController) = controller;
	
	// Add it to the content view
	//[self fillViewWithChildView:(controller.view)];
	[self addViewIfNeeded:(controller.view) layout:YES];
	
	[nc addObserver:self selector:@selector(projectsListViewControllerDidClickOnProjectNotification:) name:GLAProjectsListViewControllerDidChooseProjectNotification object:controller];
	[nc addObserver:self selector:@selector(projectsListViewControllerDidPerformWorkOnProjectNowNotification:) name:GLAProjectListsViewControllerDidPerformWorkOnProjectNowNotification object:controller];
}

- (void)setUpEmptyAllProjectsViewControllerIfNeeded
{
	if (self.emptyAllProjectsViewController) {
		return;
	}
	
	GLAEmptyAllProjectsViewController *controller = [[GLAEmptyAllProjectsViewController alloc] initWithNibName:NSStringFromClass([GLAEmptyAllProjectsViewController class]) bundle:nil];
	(controller.view.identifier) = @"emptyAllProjects";
	
	(self.emptyAllProjectsViewController) = controller;
}

#pragma mark Planned Projects

- (void)setUpPlannedProjectsViewControllerIfNeeded
{
	if (self.plannedProjectsViewController) {
		return;
	}
	
	GLAProjectsListViewController *controller = [[GLAProjectsListViewController alloc] initWithNibName:@"GLAProjectsListViewController" bundle:nil];
	(controller.view.identifier) = @"plannedProjects";
	
	(self.plannedProjectsViewController) = controller;
	
	//[self fillViewWithChildView:(controller.view)];
	[self addViewIfNeeded:(controller.view) layout:YES];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(projectsListViewControllerDidClickOnProjectNotification:) name:GLAProjectsListViewControllerDidChooseProjectNotification object:controller];
	[nc addObserver:self selector:@selector(projectsListViewControllerDidPerformWorkOnProjectNowNotification:) name:GLAProjectListsViewControllerDidPerformWorkOnProjectNowNotification object:controller];
}

#pragma mark No Now Project

- (void)setUpNoNowProjectViewControllerIfNeeded
{
	if (self.blankNowProjectViewController) {
		return;
	}
	
	GLANoNowProjectViewController *controller = [[GLANoNowProjectViewController alloc] initWithNibName:NSStringFromClass([GLANoNowProjectViewController class]) bundle:nil];
	(controller.view.identifier) = @"noNowProject";
	
	(self.blankNowProjectViewController) = controller;
	
	[self addViewIfNeeded:(controller.view) layout:YES];
}

#pragma mark Edited Project

- (void)setUpEditedProjectViewControllerIfNeeded
{
	if (self.editedProjectViewController) {
		return;
	}
	
	GLAProjectViewController *controller = [[GLAProjectViewController alloc] initWithNibName:@"GLAProjectViewController" bundle:nil];
	(controller.view.identifier) = @"editedProject";
	
	(self.editedProjectViewController) = controller;
	
	[self addViewIfNeeded:(controller.view) layout:YES];
}

- (void)setUpEditProjectPrimaryFoldersViewControllerIfNeeded
{
	if (self.editProjectPrimaryFoldersViewController) {
		return;
	}
	
	GLAProjectEditPrimaryFoldersViewController *controller = [[GLAProjectEditPrimaryFoldersViewController alloc] initWithNibName:@"GLAProjectEditPrimaryFoldersViewController" bundle:nil];
	(controller.view.identifier) = @"projectEditPrimaryFolders";
	
	(self.editProjectPrimaryFoldersViewController) = controller;
	
	[self addViewIfNeeded:(controller.view) layout:YES];
}

#pragma mark Added Project

- (void)setUpAddedProjectViewControllerIfNeeded
{
	if (self.addedProjectViewController) {
		return;
	}
	
	GLAAddNewProjectViewController *controller = [[GLAAddNewProjectViewController alloc] initWithNibName:@"GLAAddNewProjectViewController" bundle:nil];
	(controller.view.identifier) = @"addNewProject";
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(addNewProjectViewControllerDidConfirmCreatingNotification:) name:GLAAddNewProjectViewControllerDidConfirmCreatingNotification object:controller];
	
	(self.addedProjectViewController) = controller;
	
	[self fillViewWithChildView:(controller.view)];

}

#pragma mark Added Collection

- (void)setUpAddedCollectionViewControllerIfNeeded
{
	if (self.addedCollectionViewController) {
		return;
	}
	
	GLAAddNewCollectionViewController *controller = [[GLAAddNewCollectionViewController alloc] initWithNibName:@"GLAAddNewCollectionViewController" bundle:nil];
	(controller.view.identifier) = @"addNewCollection";
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(addNewCollectionViewControllerDidConfirmCreatingNotification:) name:GLAAddNewCollectionViewControllerDidConfirmCreatingNotification object:controller];
	
	(self.addedCollectionViewController) = controller;
	
	[self fillViewWithChildView:(controller.view)];
}

#pragma mark - Section Navigator

@synthesize sectionNavigator = _sectionNavigator;

- (void)setSectionNavigator:(GLAMainSectionNavigator *)sectionNavigator
{
	_sectionNavigator = sectionNavigator;
	
	[self setUpSectionNavigatorObserving];
}

- (GLAMainSection *)currentSection
{
	return (self.sectionNavigator.currentSection);
}

#pragma mark Section Navigator Notifications

- (void)sectionNavigatorDidChangeCurrentSection:(NSNotification *)note
{
	GLAMainSectionNavigator *sectionNavigator = (self.sectionNavigator);
	GLAMainSection *newSection = (sectionNavigator.currentSection);
	GLAMainSection *previousSection = nil;
	
	NSDictionary *userInfo = (note.userInfo);
	if (userInfo) {
		previousSection = userInfo[GLAMainSectionNavigatorNotificationUserInfoPreviousSection];
	}
	
	[self setUpViewControllerForSection:newSection];
	[self transitionToSection:newSection fromSection:previousSection animate:YES];
}

#pragma mark - Accessing View Controllers

- (void)setUpViewControllerForSection:(GLAMainSection *)section
{
	if (section.isAllProjects) {
		[self setUpAllProjectsViewControllerIfNeeded];
	}
	else if (section.isNow) {
		GLAEditProjectSection *nowProjectSection = (GLAEditProjectSection *)(section);
		
		GLAProject *nowProject = (nowProjectSection.project);
		if (nowProject) {
			[self setUpEditedProjectViewControllerIfNeeded];
			
			GLAProjectViewController *editedProjectViewController = (self.editedProjectViewController);
			(editedProjectViewController.project) = (nowProjectSection.project);
			[self setUpProjectViewController:editedProjectViewController];
			
			(self.isShowingBlankNowProject) = NO;
		}
		else {
			[self setUpNoNowProjectViewControllerIfNeeded];
			(self.isShowingBlankNowProject) = YES;
		}
	}
	else if (section.isPlannedProjects) {
		[self setUpPlannedProjectsViewControllerIfNeeded];
	}
	else if (section.isEditProject) {
		[self setUpEditedProjectViewControllerIfNeeded];
		
		GLAEditProjectSection *editProjectSection = (GLAEditProjectSection *)(section);
		
		GLAProjectViewController *editedProjectViewController = (self.editedProjectViewController);
		(editedProjectViewController.project) = (editProjectSection.project);
		[self setUpProjectViewController:editedProjectViewController];
	}
	else if (section.isEditProjectPrimaryFolders) {
		[self setUpEditProjectPrimaryFoldersViewControllerIfNeeded];
		
		GLAEditProjectPrimaryFoldersSection *editProjectPrimaryFoldersSection = (GLAEditProjectPrimaryFoldersSection *)(section);
		
		GLAProjectEditPrimaryFoldersViewController *editProjectPrimaryFoldersViewController = (self.editProjectPrimaryFoldersViewController);
		(editProjectPrimaryFoldersViewController.project) = (editProjectPrimaryFoldersSection.project);
	}
	else if (section.isEditCollection) {
		GLAEditCollectionSection *editCollectionSection = (GLAEditCollectionSection *)section;
		[self setUpEditedCollectionViewControllerForSection:editCollectionSection];
	}
	else if (section.isAddNewProject) {
		[self setUpAddedProjectViewControllerIfNeeded];
	}
	else if (section.isAddNewCollection) {
		[self setUpAddedCollectionViewControllerIfNeeded];
		
		GLAAddNewCollectionSection *addCollectionSection = (GLAAddNewCollectionSection *)(section);
		GLAAddNewCollectionViewController *addNewCollectionViewController = (self.addedCollectionViewController);
		(addNewCollectionViewController.project) = (addCollectionSection.project);
		(addNewCollectionViewController.pendingAddedCollectedFilesInfo) = (addCollectionSection.pendingAddedCollectedFilesInfo);
	}
}

- (void)setUpProjectViewController:(GLAProjectViewController *)projectViewController
{
	
}

- (GLAViewController *)viewControllerForSection:(GLAMainSection *)section
{
	if (section.isAllProjects) {
		return (self.allProjectsViewController);
	}
	else if (section.isNow) {
		GLAEditProjectSection *nowProjectSection = (GLAEditProjectSection *)(section);
		
		if (nowProjectSection.project) {
			return (self.editedProjectViewController);
		}
		else {
			return (self.blankNowProjectViewController);
		}
	}
	else if (section.isPlannedProjects) {
		return (self.plannedProjectsViewController);
	}
	else if (section.isEditProject) {
		return (self.editedProjectViewController);
	}
	else if (section.isEditProjectPrimaryFolders) {
		return (self.editProjectPrimaryFoldersViewController);
	}
	else if (section.isEditCollection) {
		return (self.activeCollectionViewController);
	}
	else if (section.isAddNewProject) {
		return (self.addedProjectViewController);
	}
	else if (section.isAddNewCollection) {
		return (self.addedCollectionViewController);
	}
	else {
		return nil;
	}
}

- (GLAProjectViewController *)activeProjectViewController
{
	GLAMainSection *currentSection = (self.currentSection);
	
	if (currentSection.isNow) {
		GLAEditProjectSection *nowProjectSection = (GLAEditProjectSection *)(currentSection);
		
		if (nowProjectSection.project) {
			return (self.editedProjectViewController);
		}
		else {
			return nil;
		}
	}
	else if (currentSection.isEditProject) {
		return (self.editedProjectViewController);
	}
	/*
	else if (currentSection.isAddNewProject) {
		return (self.addedProjectViewController);
	}
	 */
	else {
		return nil;
	}
}

#pragma mark Collections

- (GLAViewController *)createViewControllerForCollection:(GLACollection *)collection
{
	GLAViewController *controller = nil;
	
	if ([(collection.type) isEqualToString:GLACollectionTypeFilesList]) {
		GLAFileCollectionViewController *fileCollectionViewController = [[GLAFileCollectionViewController alloc] initWithNibName:@"GLAFileCollectionViewController" bundle:nil];
		(fileCollectionViewController.filesListCollection) = collection;
		
		controller = fileCollectionViewController;
	}
	
	return controller;
}

- (void)setUpEditedCollectionViewControllerForSection:(GLAEditCollectionSection *)section
{
	// Remove old view
	GLAViewController *oldCollectionViewController = (self.activeCollectionViewController);
	[oldCollectionViewController viewWillTransitionOut];
	[(oldCollectionViewController.view) removeFromSuperview];
	[oldCollectionViewController viewDidTransitionOut];
	
	// Set up new view
	GLAViewController *collectionViewController = [self createViewControllerForCollection:(section.collection)];
	(collectionViewController.view.identifier) = @"activeCollection";
	
	[self fillViewWithChildView:(collectionViewController.view)];
	
	(self.activeCollectionViewController) = collectionViewController;
}

- (void)enterCollection:(GLACollection *)collection
{
	[(self.sectionNavigator) goToCollection:collection];
}

#pragma mark -

#pragma mark Active/Inactive Project View Controller

- (void)projectViewControllerDidBecomeActive:(GLAProjectViewController *)projectViewController
{
	(projectViewController.delegate) = self;
	
	id<GLAMainContentViewControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainContentViewController:self projectViewControllerDidBecomeActive:projectViewController];
	}
}

- (void)projectViewControllerDidBecomeInactive:(GLAProjectViewController *)projectViewController
{
	(projectViewController.delegate) = nil;
	
	id<GLAMainContentViewControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainContentViewController:self projectViewControllerDidBecomeInactive:projectViewController];
	}
}

#pragma mark Working with Project List View Controllers

- (void)projectsListViewControllerDidClickOnProjectNotification:(NSNotification *)note
{
	GLAProjectsListViewController *projectsListViewController = (note.object);
	GLAProject *project = (note.userInfo)[@"project"];
	
	id<GLAMainContentViewControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainContentViewController:self projectsListViewController:projectsListViewController didClickOnProject:project];
	}
}

- (void)projectsListViewControllerDidPerformWorkOnProjectNowNotification:(NSNotification *)note
{
	GLAProjectsListViewController *projectsListViewController = (note.object);
	GLAProject *project = (note.userInfo)[@"project"];
	
	id<GLAMainContentViewControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainContentViewController:self projectsListViewController:projectsListViewController didPerformWorkOnProject:project];
	}
}

#pragma mark Add New Project View Controller

- (void)addNewProjectViewControllerDidConfirmCreatingNotification:(NSNotification *)note
{
	GLAAddNewProjectViewController *addNewProjectViewController = (note.object);
	GLAProject *project = (note.userInfo)[@"project"];
	
	id<GLAMainContentViewControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainContentViewController:self addNewProjectViewController:addNewProjectViewController didConfirmCreatingProject:project];
	}
}

#pragma mark Add New Collection View Controller

- (void)addNewCollectionViewControllerDidBecomeActive:(GLAAddNewCollectionViewController *)addNewCollectionViewController
{
	id<GLAMainContentViewControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainContentViewController:self addNewCollectionViewControllerDidBecomeActive:addNewCollectionViewController];
	}
}

- (void)addNewCollectionViewControllerDidConfirmCreatingNotification:(NSNotification *)note
{
	GLAAddNewCollectionViewController *addNewCollectionViewController = (note.object);
	NSDictionary *userInfo = (note.userInfo);
	GLACollection *collection = userInfo[@"collection"];
	GLAProject *project = userInfo[@"project"];
	
	id<GLAMainContentViewControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainContentViewController:self addNewCollectionViewController:addNewCollectionViewController didConfirmCreatingCollection:collection inProject:project];
	}
}

#pragma mark - Transition

- (void)transitionToSection:(GLAMainSection *)newSection fromSection:(GLAMainSection *)outSection animate:(BOOL)animate
{
	if ([outSection isEqual:newSection]) {
		return;
	}
	
	GLAViewController *outViewController = [self viewControllerForSection:outSection];
	GLAViewController *inViewController = [self viewControllerForSection:newSection];
	
	NSAssert((outSection) ? (outViewController != nil) : (outViewController == nil), @"There must be an appropriate view controller for an out section, or no view controller for no section");
	NSAssert((newSection) ? (inViewController != nil) : (inViewController == nil), @"There must be an appropriate view controller for an in section, or no view controller for no section");
	
	if (outViewController == inViewController) {
		return;
	}
	
	if (!outViewController) {
		// If this is the first view in, just make it appear instantly.
		animate = NO;
	}
	
	CGFloat outLeading = -500.0, inLeading = 500.0;
	
	if (newSection.isAllProjects) {
		//[self setUpAllProjectsViewControllerIfNeeded];
		//[(self.allProjectsViewController.tableView) sizeLastColumnToFit];
		
		outLeading = 500.0;
		inLeading = -500.0;
		
		if (outSection) {
			if (outSection.isPlannedProjects) {
				outLeading = 1000.0;
				//inLeading = -1000.0;
			}
		}
	}
	else if (newSection.isNow) {
		outLeading = 500.0;
		inLeading = -500.0;
		
		if (outSection) {
			if (outSection.isAllProjects) {
				outLeading = -500.0;
				inLeading = 500.0;
			}
			else if (outSection.isEditProject) {
				// No transition needed.
				return;
			}
			else if (outSection.isNow) {
				outLeading = 0.0;
				inLeading = 0.0;
			}
		}
	}
	else if (newSection.isPlannedProjects) {
		outLeading = 500.0;
		inLeading = -500.0;
		
		if (outSection) {
			if (outSection.isNow) {
				outLeading = -500.0;
				inLeading = 500.0;
			}
			else if (outSection.isAllProjects) {
				outLeading = -1000.0;
				inLeading = 500.0;
			}
		}
	}
	else if (newSection.isEditProject) {
		if ((outSection.isEditCollection) || (outSection.isAddNewCollection) || (outSection.isEditProjectPrimaryFolders)) {
			outLeading = 500.0;
			inLeading = -500.0;
		}
	}
	
	// HIDE OUT
	if (outViewController && !isnan(outLeading)) {
		[self didBeginTransitioningOutViewController:outViewController];
		[self hideChildViewController:outViewController movingLeadingTo:outLeading animate:animate associatedSection:outSection];
	}
	// SHOW IN
	if (!isnan(inLeading)) {
		[self showChildViewController:inViewController movingLeadingFrom:inLeading animate:animate associatedSection:newSection];
		[self didBeginTransitioningInViewController:inViewController];
	}
}

- (void)didBeginTransitioningInViewController:(GLAViewController *)viewController
{
	[viewController viewWillTransitionIn];
	
	if (viewController == (self.editedProjectViewController)) {
		GLAProjectViewController *projectVC = (GLAProjectViewController *)viewController;
		[self projectViewControllerDidBecomeActive:projectVC];
	}
	else if (viewController == (self.addedCollectionViewController)) {
		GLAAddNewCollectionViewController *addNewCollectionViewController = (GLAAddNewCollectionViewController *)viewController;
		[self addNewCollectionViewControllerDidBecomeActive:addNewCollectionViewController];
	}
}

- (void)didBeginTransitioningOutViewController:(GLAViewController *)viewController
{
	if (viewController == (self.editedProjectViewController)) {
		GLAProjectViewController *projectVC = (GLAProjectViewController *)viewController;
		[self projectViewControllerDidBecomeInactive:projectVC];
	}
}

#pragma mark Adjusting Individual Content Views

- (NSTimeInterval)transitionDurationGoingInForChildView:(NSView *)view
{
	if (view == (self.activeCollectionViewController.view)) {
		return 2.5 / 12.0;
	}
	else {
		return 4.0 / 12.0;
	}
}

- (NSTimeInterval)transitionDurationGoingOutForChildView:(NSView *)view
{
	return 4.0 / 12.0;
}

#pragma mark Hiding Child Views

- (void)hideChildViewController:(GLAViewController *)vc adjustingConstraint:(NSLayoutConstraint *)constraint toValue:(CGFloat)constraintValue animate:(BOOL)animate associatedSection:(GLAMainSection *)associatedSection
{
	NSView *view = (vc.view);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		if (animate) {
			(context.duration) = [self transitionDurationGoingOutForChildView:view];
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(view.animator.alphaValue) = 0.0;
			(constraint.animator.constant) = constraintValue;
		}
		else {
			(context.duration) = 0;
			(view.alphaValue) = 0.0;
			(constraint.constant) = constraintValue;
		}
	} completionHandler:^ {
		NSTableView *tableView = nil;
		if (view == (self.allProjectsViewController.view)) {
			tableView = (self.allProjectsViewController.tableView);
		}
		else if (view == (self.plannedProjectsViewController.view)) {
			tableView = (self.plannedProjectsViewController.tableView);
		}
		
		if (tableView) {
			[tableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowViewSuperclassed, NSInteger row) {
				GLATableProjectRowView *rowView = (GLATableProjectRowView *)rowViewSuperclassed;
				[rowView checkMouseLocationIsInside];
			}];
		}
		
		if (animate) {
			if (![associatedSection isEqual:(self.currentSection)]) {
				[vc viewWillTransitionOut];
				[view removeFromSuperview];
			}
		}
	}];
}

- (void)hideChildViewController:(GLAViewController *)vc movingLeadingTo:(CGFloat)offset animate:(BOOL)animate associatedSection:(GLAMainSection *)associatedSection
{
	NSView *view = (vc.view);
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithIdentifier:@"leading" forChildView:view];
	[self hideChildViewController:vc adjustingConstraint:leadingConstraint toValue:offset animate:animate associatedSection:associatedSection];
}

- (void)hideChildViewController:(GLAViewController *)vc moveTopTo:(CGFloat)offset animate:(BOOL)animate associatedSection:(GLAMainSection *)associatedSection
{
	NSView *view = (vc.view);
	NSLayoutConstraint *topConstraint = [self layoutConstraintWithIdentifier:@"top" forChildView:view];
	[self hideChildViewController:vc adjustingConstraint:topConstraint toValue:offset animate:animate associatedSection:associatedSection];
}

#pragma mark Showing Child Views

- (void)showChildViewController:(GLAViewController *)vc adjustingConstraint:(NSLayoutConstraint *)constraint toValue:(CGFloat)constraintValue animate:(BOOL)animate associatedSection:(GLAMainSection *)associatedSection
{
	NSParameterAssert(vc != nil);
	
	NSView *view = (vc.view);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(view.hidden) = NO;
		
		CGFloat fractionFromDestination = (constraint.constant) / (constraint.animator.constant);
		
		if (animate) {
			(context.duration) = fractionFromDestination * [self transitionDurationGoingInForChildView:view];
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(view.animator.alphaValue) = 1.0;
			(constraint.animator.constant) = constraintValue;
		}
		else {
			(context.duration) = 0;
			(view.alphaValue) = 1.0;
			(constraint.constant) = constraintValue;
		}
	} completionHandler:^ {
		if ([associatedSection isEqual:(self.currentSection)]) {
			GLAViewController *vc = [self viewControllerForSection:(self.currentSection)];
			[vc viewDidTransitionIn];
		}
	}];
}

- (void)showChildViewController:(GLAViewController *)vc movingLeadingFrom:(CGFloat)leadingInitialValue animate:(BOOL)animate associatedSection:(GLAMainSection *)associatedSection
{
	NSParameterAssert(vc != nil);
	
	NSView *view = (vc.view);
	[self addViewIfNeeded:view layout:YES];
	
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithIdentifier:@"leading" forChildView:view];
	NSAssert(leadingConstraint != nil, @"View must have a 'leading' constraint.");
	
	if (animate) {
		// Move view to initial position.
		[self hideChildViewController:vc adjustingConstraint:leadingConstraint toValue:leadingInitialValue animate:NO associatedSection:associatedSection];
	}
	
	[self showChildViewController:vc adjustingConstraint:leadingConstraint toValue:0.0 animate:animate associatedSection:associatedSection];
}

- (void)showChildViewControllerMovingTop:(GLAViewController *)vc animate:(BOOL)animate associatedSection:(GLAMainSection *)associatedSection
{
	NSView *view = (vc.view);
	[self addViewIfNeeded:view layout:YES];
	
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithIdentifier:@"top" forChildView:view];
	[self showChildViewController:vc adjustingConstraint:leadingConstraint toValue:0.0 animate:animate associatedSection:associatedSection];
}

@end


@implementation GLAMainContentViewController (GLAProjectViewControllerDelegate)

- (void)projectViewController:(GLAProjectViewController *)projectViewController performAddCollectedFilesToNewCollection:(GLAPendingAddedCollectedFilesInfo *)info
{
	GLAProject *project = (projectViewController.project);
	[(self.sectionNavigator) addNewCollectionToProject:project pendingCollectedFilesInfo:info];
}

@end
