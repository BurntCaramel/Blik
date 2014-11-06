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


@interface GLAMainContentViewController ()

@end

@implementation GLAMainContentViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		[self setUpProjectManagerObserving];
	}
	return self;
}

- (void)dealloc
{
	[self stopProjectManagerObserving];
}

- (void)setUpProjectManagerObserving
{
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// All Projects
	[nc addObserver:self selector:@selector(projectManagerAllProjectsDidChangeNotification:) name:GLAProjectManagerAllProjectsDidChangeNotification object:projectManager];
	// Now Project
	[nc addObserver:self selector:@selector(projectManagerNowProjectDidChangeNotification:) name:GLAProjectManagerNowProjectDidChangeNotification object:projectManager];
	
}

- (void)stopProjectManagerObserving
{
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Stop observing any notifications on the project manager.
	[nc removeObserver:self name:nil object:projectManager];
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
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	GLAProjectsListViewController *controller = [[GLAProjectsListViewController alloc] initWithNibName:@"GLAProjectsListViewController" bundle:nil];
	(controller.view.identifier) = @"allProjects";
	
	[projectManager loadAllProjects];
	NSArray *allProjects = (projectManager.allProjectsSortedByDateCreatedNewestToOldest);
	if (allProjects) {
		(controller.projects) = allProjects;
	}
	
	(self.allProjectsViewController) = controller;
	
	// Add it to the content view
	//[self fillViewWithChildView:(controller.view)];
	[self addViewIfNeeded:(controller.view) layout:YES];
	
	[nc addObserver:self selector:@selector(projectsListViewControllerDidClickOnProjectNotification:) name:GLAProjectsListViewControllerDidChooseProjectNotification object:controller];
	[nc addObserver:self selector:@selector(projectsListViewControllerDidPerformWorkOnProjectNowNotification:) name:GLAProjectListsViewControllerDidPerformWorkOnProjectNowNotification object:controller];
}

#pragma mark Planned Projects

- (void)setUpPlannedProjectsViewControllerIfNeeded
{
	if (self.plannedProjectsViewController) {
		return;
	}
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	GLAProjectsListViewController *controller = [[GLAProjectsListViewController alloc] initWithNibName:@"GLAProjectsListViewController" bundle:nil];
	(controller.view.identifier) = @"plannedProjects";
	
	/*
	[projectManager usePlannedProjects:^(NSArray *plannedProjects) {
		(controller.projects) = plannedProjects;
	}];
	 */
	
	(self.plannedProjectsViewController) = controller;
	
	//[self fillViewWithChildView:(controller.view)];
	[self addViewIfNeeded:(controller.view) layout:YES];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(projectsListViewControllerDidClickOnProjectNotification:) name:GLAProjectsListViewControllerDidChooseProjectNotification object:controller];
	[nc addObserver:self selector:@selector(projectsListViewControllerDidPerformWorkOnProjectNowNotification:) name:GLAProjectListsViewControllerDidPerformWorkOnProjectNowNotification object:controller];
}

#pragma mark Now Project

- (void)setUpNowProjectViewControllerIfNeeded
{
	if (self.nowProjectViewController) {
		return;
	}
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	GLAProjectViewController *controller = [[GLAProjectViewController alloc] initWithNibName:@"GLAProjectViewController" bundle:nil];
	(controller.view.identifier) = @"nowProject";
	
	[projectManager loadNowProject];
	GLAProject *nowProject = (projectManager.nowProject);
	if (nowProject) {
		(controller.project) = nowProject;
	}
	
	(self.nowProjectViewController) = controller;
	
	// Add it to the content view
	//[self fillViewWithChildView:(controller.view)];
	[self addViewIfNeeded:(controller.view) layout:YES];
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
	
	//[self fillViewWithChildView:(controller.view)];
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

#pragma mark - Project Manager Notifications

- (void)projectManagerAllProjectsDidChangeNotification:(NSNotification *)note
{
	GLAProjectManager *projectManager = (note.object);
	GLAProjectsListViewController *allProjectsViewController = (self.allProjectsViewController);
	if (allProjectsViewController) {
		(allProjectsViewController.projects) = (projectManager.allProjectsSortedByDateCreatedNewestToOldest);
	}
	
#if 0
	// TEST
	[projectManager requestSaveAllProjects];
#endif
}

- (void)projectManagerNowProjectDidChangeNotification:(NSNotification *)note
{
	GLAProjectManager *projectManager = (note.object);
	GLAProjectViewController *nowProjectViewController = (self.nowProjectViewController);
	
	if (nowProjectViewController) {
		(nowProjectViewController.project) = (projectManager.nowProject);
	}
}

#pragma mark - Accessing View Controllers

- (void)setUpViewControllerForSection:(GLAMainContentSection *)section
{
	if (section.isAllProjects) {
		[self setUpAllProjectsViewControllerIfNeeded];
	}
	else if (section.isNow) {
		GLAMainContentEditProjectSection *nowProjectSection = (GLAMainContentEditProjectSection *)(section);
		
		GLAProject *nowProject = (nowProjectSection.project);
		if (nowProject) {
			[self setUpNowProjectViewControllerIfNeeded];
			(self.nowProjectViewController.project) = nowProject;
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
		
		GLAMainContentEditProjectSection *editProjectSection = (GLAMainContentEditProjectSection *)(section);
		(self.editedProjectViewController.project) = (editProjectSection.project);
	}
	else if (section.isEditCollection) {
		GLAMainContentEditCollectionSection *editCollectionSection = (GLAMainContentEditCollectionSection *)section;
		[self setUpEditedCollectionViewControllerForSection:editCollectionSection];
	}
	else if (section.isAddNewProject) {
		[self setUpAddedProjectViewControllerIfNeeded];
	}
	else if (section.isAddNewCollection) {
		[self setUpAddedCollectionViewControllerIfNeeded];
		
		GLAMainContentAddNewCollectionSection *addCollectionSection = (GLAMainContentAddNewCollectionSection *)(section);
		(self.addedCollectionViewController.project) = (addCollectionSection.project);
	}
}

- (GLAViewController *)viewControllerForSection:(GLAMainContentSection *)section
{
	if (section.isAllProjects) {
		return (self.allProjectsViewController);
	}
	else if (section.isNow) {
		GLAMainContentEditProjectSection *nowProjectSection = (GLAMainContentEditProjectSection *)(section);
		
		if (nowProjectSection.project) {
			return (self.nowProjectViewController);
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
	GLAMainContentSection *currentSection = (self.currentSection);
	
	if (currentSection.isNow) {
		GLAMainContentEditProjectSection *nowProjectSection = (GLAMainContentEditProjectSection *)(currentSection);
		
		if (nowProjectSection.project) {
			return (self.nowProjectViewController);
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

#pragma mark - Editing Projects

- (void)changeNowProject:(GLAProject *)project
{
	[self setUpNowProjectViewControllerIfNeeded];
	
	(self.nowProjectViewController.project) = project;
}

- (void)workOnProjectNow:(GLAProject *)project
{
	[self setUpNowProjectViewControllerIfNeeded];
	
	(self.nowProjectViewController.project) = project;
	
	[self goToSection:[GLAMainContentEditProjectSection nowProjectSectionWithProject:project]];
}

- (void)editProject:(GLAProject *)project;
{
	[self setUpEditedProjectViewControllerIfNeeded];
	(self.editedProjectViewController.project) = project;
	
	[self goToSection:[GLAMainContentEditProjectSection editProjectSectionWithProject:project previousSection:(self.currentSection)]];
}
/*
- (void)enterAddedProject:(GLAProject *)project
{
	[self setUpAddedProjectViewControllerIfNeeded];
	GLAAddNewProjectViewController *viewController = (self.addedProjectViewController);
	
	[self goToSection:[GLAMainContentSection addNewProjectSectionWithPreviousSection:(self.currentSection)]];
	
	[viewController resetAndFocus];
}
*/
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

- (void)setUpEditedCollectionViewControllerForSection:(GLAMainContentEditCollectionSection *)section
{
	// Remove old view
	GLAViewController *oldCollectionViewController = (self.activeCollectionViewController);
	[oldCollectionViewController viewWillDisappear];
	[(oldCollectionViewController.view) removeFromSuperview];
	[oldCollectionViewController viewDidDisappear];
	
	// Set up new view
	GLAViewController *collectionViewController = [self createViewControllerForCollection:(section.collection)];
	(collectionViewController.view.identifier) = @"activeCollection";
	
	[self fillViewWithChildView:(collectionViewController.view)];
	
	(self.activeCollectionViewController) = collectionViewController;
}

- (void)enterCollection:(GLACollection *)collection
{
	GLAMainContentEditCollectionSection *section = [GLAMainContentEditCollectionSection editCollectionSectionWithCollection:collection previousSection:(self.currentSection)];
	
	[self setUpEditedCollectionViewControllerForSection:section];
	
	[self goToSection:section];
}

- (IBAction)addNewFilesListCollection:(id)sender
{
	GLAProjectViewController *activeProjectViewController = (self.activeProjectViewController);
	if (activeProjectViewController) {
		[activeProjectViewController addNewFilesListCollection:sender];
	}
}

#pragma mark -

#pragma mark Active/Inactive Project View Controller

- (void)projectViewControllerDidBecomeActive:(GLAProjectViewController *)projectViewController
{
	id<GLAMainContentViewControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainContentViewController:self projectViewControllerDidBecomeActive:projectViewController];
	}
}

- (void)projectViewControllerDidBecomeInactive:(GLAProjectViewController *)projectViewController
{
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

- (void)addNewCollectionViewControllerDidConfirmCreatingNotification:(NSNotification *)note
{
	GLAAddNewCollectionViewController *addNewCollectionViewController = (note.object);
	GLACollection *collection = (note.userInfo)[@"collection"];
	
	id<GLAMainContentViewControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainContentViewController:self addNewCollectionViewController:addNewCollectionViewController didConfirmCreatingCollection:collection];
	}
}

#pragma mark - Transition

- (void)transitionToSection:(GLAMainContentSection *)newSection animate:(BOOL)animate
{
	GLAMainContentSection *outSection = (self.currentSection);
	if ([outSection isEqual:newSection]) {
		return;
	}
	
	GLAViewController *outViewController = [self viewControllerForSection:outSection];
	GLAViewController *inViewController = [self viewControllerForSection:newSection];
	
	NSAssert(outSection ? (outViewController != nil) : (outViewController == nil), @"There must be an appropriate view controller for an out section, or no view controller for no section");
	NSAssert(newSection ? (inViewController != nil) : (inViewController == nil), @"There must be an appropriate view controller for an in section, or no view controller for no section");
	
	if (outViewController == inViewController) {
		(self.currentSection) = newSection;
		return;
	}
	
	if (outViewController) {
		[self didBeginTransitioningOutViewController:outViewController];
	}
	else {
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
		//[self setUpNowProjectViewControllerIfNeeded];
		
		outLeading = 500.0;
		inLeading = -500.0;
		
		if (outSection) {
			if (outSection.isAllProjects) {
				outLeading = -500.0;
				inLeading = 500.0;
			}
			else if (outSection.isEditProject) {
				GLAProject *nowProject = (self.nowProjectViewController.project);
				GLAProject *editedProject = (self.editedProjectViewController.project);
				
				if (nowProject == editedProject) {
					[(self.nowProjectViewController) matchWithOtherProjectViewController:(self.editedProjectViewController)];
					//[(outViewController.view) removeFromSuperview];
					
					animate = NO;
				}
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
		if (outSection.isEditCollection) {
			outLeading = 500.0;
			inLeading = -500.0;
		}
	}
	
	// HIDE OUT
	if (outViewController && !isnan(outLeading)) {
		[self hideChildView:(outViewController.view) movingLeadingTo:outLeading animate:animate];
	}
	// SHOW IN
	if (!isnan(inLeading)) {
		[self showChildView:(inViewController.view) movingLeadingFrom:inLeading animate:animate];
	}
	
	
	(self.currentSection) = newSection;
	
	[self didBeginTransitioningInViewController:inViewController];
}

- (void)didBeginTransitioningInViewController:(GLAViewController *)viewController
{
	[viewController viewWillAppear];
	
	if (viewController == (self.nowProjectViewController) || viewController == (self.addedProjectViewController) || viewController == (self.editedProjectViewController)) {
		GLAProjectViewController *projectVC = (GLAProjectViewController *)viewController;
		[self projectViewControllerDidBecomeActive:projectVC];
	}
}

- (void)didBeginTransitioningOutViewController:(GLAViewController *)viewController
{
	if (viewController == (self.nowProjectViewController) || viewController == (self.addedProjectViewController) || viewController == (self.editedProjectViewController)) {
		GLAProjectViewController *projectVC = (GLAProjectViewController *)viewController;
		[self projectViewControllerDidBecomeInactive:projectVC];
	}
}

- (void)goToSection:(GLAMainContentSection *)newSection
{
	[self setUpViewControllerForSection:newSection];
	[self transitionToSection:newSection animate:YES];
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

- (void)hideChildView:(NSView *)view adjustingConstraint:(NSLayoutConstraint *)constraint toValue:(CGFloat)constraintValue animate:(BOOL)animate
{
	//[self addViewIfNeeded:view layout:YES];
	
	GLAMainContentSection *currentSection = (self.currentSection);
	GLAViewController *vc = [self viewControllerForSection:currentSection];
	
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
			if (![currentSection isEqual:(self.currentSection)]) {
				[vc viewWillDisappear];
				[view removeFromSuperview];
			}
		}
	}];
}

- (void)hideChildView:(NSView *)view movingLeadingTo:(CGFloat)offset animate:(BOOL)animate
{
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithIdentifier:@"leading" forChildView:view];
	[self hideChildView:view adjustingConstraint:leadingConstraint toValue:offset animate:animate];
}

- (void)hideChildView:(NSView *)view moveTopTo:(CGFloat)offset animate:(BOOL)animate
{
	NSLayoutConstraint *topConstraint = [self layoutConstraintWithIdentifier:@"top" forChildView:view];
	[self hideChildView:view adjustingConstraint:topConstraint toValue:offset animate:animate];
}

#pragma mark Showing Child Views

- (void)showChildView:(NSView *)view adjustingConstraint:(NSLayoutConstraint *)constraint toValue:(CGFloat)constraintValue animate:(BOOL)animate
{
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
		
		//(context.allowsImplicitAnimation) = YES;
		//[view layoutSubtreeIfNeeded];
	} completionHandler:^ {
		GLAViewController *vc = [self viewControllerForSection:(self.currentSection)];
		[vc viewDidAppear];
	}];
}

- (void)showChildView:(NSView *)view movingLeadingFrom:(CGFloat)leadingInitialValue animate:(BOOL)animate
{
	[self addViewIfNeeded:view layout:YES];
	
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithIdentifier:@"leading" forChildView:view];
	
	if (animate) {
		// Move view to initial position.
		[self hideChildView:view adjustingConstraint:leadingConstraint toValue:leadingInitialValue animate:NO];
	}
	
	[self showChildView:view adjustingConstraint:leadingConstraint toValue:0.0 animate:animate];
}

- (void)showChildViewMovingTop:(NSView *)view animate:(BOOL)animate
{
	[self addViewIfNeeded:view layout:YES];
	
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithIdentifier:@"top" forChildView:view];
	[self showChildView:view adjustingConstraint:leadingConstraint toValue:0.0 animate:animate];
}


@end
