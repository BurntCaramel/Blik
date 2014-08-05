//
//  GLAMainContentViewController.m
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAMainContentViewController.h"
#import "GLAProject.h"
#import "GLATableRowView.h"
#import "GLAProjectManager.h"
@import QuartzCore;


@interface GLAMainContentViewController ()

@end

@implementation GLAMainContentViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		(self.currentSection) = GLAMainContentSectionUnknown;
	}
	return self;
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
	
	GLAProjectsListViewController *controller = [[GLAProjectsListViewController alloc] initWithNibName:@"GLAProjectsListViewController" bundle:nil];
	(controller.view.identifier) = @"allProjects";
	
	[projectManager useAllProjects:^(NSArray *allProjects) {
		(controller.projects) = allProjects;
	}];
	
	(self.allProjectsViewController) = controller;
	
	// Add it to the content view
	//[self fillViewWithChildView:(controller.view)];
	[self addViewIfNeeded:(controller.view) layout:YES];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(projectsListViewControllerDidClickOnProjectNotification:) name:GLAProjectsListViewControllerDidClickOnProjectNotification object:controller];
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
	
	[projectManager usePlannedProjects:^(NSArray *plannedProjects) {
		(controller.projects) = plannedProjects;
	}];
	
	(self.plannedProjectsViewController) = controller;
	
	//[self fillViewWithChildView:(controller.view)];
	[self addViewIfNeeded:(controller.view) layout:YES];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(projectsListViewControllerDidClickOnProjectNotification:) name:GLAProjectsListViewControllerDidClickOnProjectNotification object:controller];
	[nc addObserver:self selector:@selector(projectsListViewControllerDidPerformWorkOnProjectNowNotification:) name:GLAProjectListsViewControllerDidPerformWorkOnProjectNowNotification object:controller];
}

#pragma mark Now Project

- (void)setUpNowProjectViewControllerIfNeeded
{
	if (self.nowProjectViewController) {
		return;
	}
	
	GLAProjectViewController *controller = [[GLAProjectViewController alloc] initWithNibName:@"GLAProjectViewController" bundle:nil];
	(controller.view.identifier) = @"nowProject";
	
	(self.nowProjectViewController) = controller;
	
	// Add it to the content view
	//[self fillViewWithChildView:(controller.view)];
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
	
	GLAProjectViewController *controller = [[GLAProjectViewController alloc] initWithNibName:@"GLAProjectViewController" bundle:nil];
	(controller.view.identifier) = @"addedProject";
	
	(self.addedProjectViewController) = controller;
	
	//[self addViewIfNeeded:(controller.view) layout:YES];
	[self fillViewWithChildView:(controller.view)];
}

- (GLAViewController *)viewControllerForSection:(GLAMainContentSection)section
{
	switch (section) {
		case GLAMainContentSectionAll:
			return (self.allProjectsViewController);
			
		case GLAMainContentSectionToday:
			return (self.nowProjectViewController);
			
		case GLAMainContentSectionPlanned:
			return (self.plannedProjectsViewController);
			
		case GLAMainContentSectionAllEditProject:
		case GLAMainContentSectionPlannedEditProject:
			return (self.editedProjectViewController);
			
		case GLAMainContentSectionAddNewProject:
			return (self.addedProjectViewController);
			
		default:
			return nil;
	}
}

#pragma mark - Editing Projects

- (void)workOnProjectNow:(GLAProject *)project
{
	[self setUpNowProjectViewControllerIfNeeded];
	
	(self.nowProjectViewController.project) = project;
	
	//[(self.mainNavigationBarController) changeCurrentSectionTo:GLAMainNavigationSectionToday];
	[self transitionToSection:GLAMainContentSectionToday animate:YES];
}

- (void)editProject:(GLAProject *)project;
{
	[self setUpEditedProjectViewControllerIfNeeded];
	(self.editedProjectViewController.project) = project;
	
	GLAMainContentSection currentSection = (self.currentSection);
	if (currentSection == GLAMainContentSectionAll) {
		[self transitionToSection:GLAMainContentSectionAllEditProject animate:YES];
	}
	else if (currentSection == GLAMainContentSectionPlanned) {
		[self transitionToSection:GLAMainContentSectionPlannedEditProject animate:YES];
	}
}

- (void)endEditingProject:(GLAProject *)project previousSection:(GLAMainContentSection)previousSection
{
	GLAMainContentSection currentSection = (self.currentSection);
	if (currentSection == GLAMainContentSectionAddNewProject) {
		[self transitionToSection:previousSection animate:YES];
	}
	else {
		if (currentSection == GLAMainContentSectionAllEditProject) {
			[self transitionToSection:GLAMainContentSectionAll animate:YES];
		}
		else if (currentSection == GLAMainContentSectionPlannedEditProject) {
			[self transitionToSection:GLAMainContentSectionPlanned animate:YES];
		}
	}
}

- (void)enterAddedProject:(GLAProject *)project
{
	[self setUpAddedProjectViewControllerIfNeeded];
	GLAProjectViewController *viewController = (self.addedProjectViewController);
	
	(viewController.project) = project;
	[viewController clearName];
	
	[self transitionToSection:GLAMainContentSectionAddNewProject animate:YES];
	
	[viewController focusNameTextField];

}

#pragma mark Active Project View Controller

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

#pragma mark Transition

- (void)transitionToSection:(GLAMainContentSection)newSection animate:(BOOL)animate
{
	GLAMainContentSection previousSection = (self.currentSection);
	if (previousSection == newSection) {
		return;
	}
	
	[self didBeginTransitionAwayFromViewController:[self viewControllerForSection:previousSection]];
	
	if (newSection == GLAMainContentSectionAll) {
		[self setUpAllProjectsViewControllerIfNeeded];
		//[(self.allProjectsViewController.tableView) sizeLastColumnToFit];
		
		if (previousSection == GLAMainContentSectionAllEditProject) {
			[self hideChildView:(self.editedProjectViewController.view) moveLeadingTo:500.0 animate:YES];
		}
		else if (previousSection == GLAMainContentSectionAddNewProject) {
			[self hideChildView:(self.addedProjectViewController.view) moveLeadingTo:500.0 animate:YES];
		}
		else if (previousSection == GLAMainContentSectionToday) {
			[self hideChildView:(self.nowProjectViewController.view) moveLeadingTo:500.0 animate:YES];
		}
		else if (previousSection == GLAMainContentSectionPlanned) {
			[self hideChildView:(self.plannedProjectsViewController.view) moveLeadingTo:1000.0 animate:YES];
		}
		
		[self hideChildView:(self.allProjectsViewController.view) moveLeadingTo:-500.0 animate:NO];
		[self showChildViewMovingLeading:(self.allProjectsViewController.view) animate:YES];
	}
	else if (newSection == GLAMainContentSectionToday) {
		[self setUpNowProjectViewControllerIfNeeded];
		
		BOOL animateNowIn = YES;
		
		if (previousSection == GLAMainContentSectionAll) {
			[self hideChildView:(self.allProjectsViewController.view) moveLeadingTo:-500.0 animate:YES];
			[self hideChildView:(self.nowProjectViewController.view) moveLeadingTo:500.0 animate:NO];
		}
		else if (previousSection == GLAMainContentSectionPlanned) {
			[self hideChildView:(self.plannedProjectsViewController.view) moveLeadingTo:500.0 animate:YES];
			[self hideChildView:(self.nowProjectViewController.view) moveLeadingTo:-500.0 animate:NO];
		}
		else if (previousSection == GLAMainContentSectionAddNewProject) {
			[self hideChildView:(self.addedProjectViewController.view) moveLeadingTo:500.0 animate:YES];
			[self hideChildView:(self.nowProjectViewController.view) moveLeadingTo:-500.0 animate:NO];
		}
		else if (previousSection == GLAMainContentSectionAllEditProject || previousSection == GLAMainContentSectionPlannedEditProject) {
			[(self.nowProjectViewController) matchWithOtherProjectViewController:(self.editedProjectViewController)];
			
			[(self.editedProjectViewController.view) removeFromSuperview];
			
			animateNowIn = NO;
		}
		
		[self showChildViewMovingLeading:(self.nowProjectViewController.view) animate:animateNowIn];
	}
	else if (newSection == GLAMainContentSectionPlanned) {
		[self setUpPlannedProjectsViewControllerIfNeeded];
		//[(self.plannedProjectsViewController.tableView) sizeLastColumnToFit];
		
		if (previousSection == GLAMainContentSectionPlannedEditProject) {
			[self hideChildView:(self.editedProjectViewController.view) moveLeadingTo:500.0 animate:YES];
		}
		else if (previousSection == GLAMainContentSectionAddNewProject) {
			[self hideChildView:(self.addedProjectViewController.view) moveLeadingTo:500.0 animate:YES];
		}
		else if (previousSection == GLAMainContentSectionToday) {
			[self hideChildView:(self.nowProjectViewController.view) moveLeadingTo:-500.0 animate:YES];
		}
		else if (previousSection == GLAMainContentSectionAll) {
			[self hideChildView:(self.allProjectsViewController.view) moveLeadingTo:-1000.0 animate:YES];
		}
		
		if (previousSection == GLAMainContentSectionToday || previousSection == GLAMainContentSectionAll) {
			[self hideChildView:(self.plannedProjectsViewController.view) moveLeadingTo:500.0 animate:NO];
		}
		else {
			[self hideChildView:(self.plannedProjectsViewController.view) moveLeadingTo:-500.0 animate:NO];
		}
		[self showChildViewMovingLeading:(self.plannedProjectsViewController.view) animate:YES];
	}
	else if (newSection == GLAMainContentSectionAllEditProject) {
		[self setUpEditedProjectViewControllerIfNeeded];
		[self hideChildView:(self.editedProjectViewController.view) moveLeadingTo:500.0 animate:NO];
		
		[self hideChildView:(self.allProjectsViewController.view) moveLeadingTo:-500.0 animate:YES];
		[self showChildViewMovingLeading:(self.editedProjectViewController.view) animate:YES];
	}
	else if (newSection == GLAMainContentSectionPlannedEditProject) {
		[self setUpEditedProjectViewControllerIfNeeded];
		[self hideChildView:(self.editedProjectViewController.view) moveLeadingTo:500.0 animate:NO];
		
		[self hideChildView:(self.plannedProjectsViewController.view) moveLeadingTo:-500.0 animate:YES];
		[self showChildViewMovingLeading:(self.editedProjectViewController.view) animate:YES];
	}
	else if (newSection == GLAMainContentSectionAddNewProject) {
		[self setUpAddedProjectViewControllerIfNeeded];
		
		[self hideChildView:(self.addedProjectViewController.view) moveLeadingTo:500.0 animate:NO];
		//[self hideChildView:(self.addedProjectViewController.view) moveTopTo:-700.0 animate:NO];
		
		GLAViewController *previousViewController = [self viewControllerForSection:previousSection];
		[self hideChildView:(previousViewController.view) moveLeadingTo:-500.0 animate:YES];
		
		[self showChildViewMovingLeading:(self.addedProjectViewController.view) animate:YES];
		//[self showChildViewMovingTop:(self.addedProjectViewController.view) animate:YES];
	}
	
	(self.currentSection) = newSection;
	
	[self didBeginTransitionToViewController:[self viewControllerForSection:newSection]];
}

- (void)didBeginTransitionToViewController:(GLAViewController *)viewController
{
	[viewController viewWillAppear];
	
	if (viewController == (self.nowProjectViewController) || viewController == (self.addedProjectViewController) || viewController == (self.editedProjectViewController)) {
		GLAProjectViewController *projectVC = (GLAProjectViewController *)viewController;
		[self projectViewControllerDidBecomeActive:projectVC];
	}
}

- (void)didBeginTransitionAwayFromViewController:(GLAViewController *)viewController
{
	//TODO did appear??? or disappear
	//[viewController viewDidAppear];
	
	if (viewController == (self.nowProjectViewController) || viewController == (self.addedProjectViewController) || viewController == (self.editedProjectViewController)) {
		GLAProjectViewController *projectVC = (GLAProjectViewController *)viewController;
		[self projectViewControllerDidBecomeInactive:projectVC];
	}
}

#pragma mark Adjusting Individual Content Views

- (NSTimeInterval)transitionDurationGoingIn
{
	return 4.0 / 12.0;
}

- (NSTimeInterval)transitionDurationGoingOut
{
	return 4.0 / 12.0;
}

#pragma mark Hiding Child Views

- (void)hideChildView:(NSView *)view adjustingConstraint:(NSLayoutConstraint *)constraint toValue:(CGFloat)constraintValue animate:(BOOL)animate
{
	//[self addViewIfNeeded:view layout:YES];
	
	GLAMainContentSection currentSection = (self.currentSection);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		if (animate) {
			(context.duration) = [self transitionDurationGoingOut];
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
				GLATableRowView *rowView = (GLATableRowView *)rowViewSuperclassed;
				[rowView checkMouseLocationIsInside];
			}];
		}
		
		if (animate) {
			if (currentSection != (self.currentSection)) {
				[view removeFromSuperview];
			}
		}
	}];
}

- (void)hideChildView:(NSView *)view moveLeadingTo:(CGFloat)offset animate:(BOOL)animate
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
		
		//NSLog(@"Show running %@", (view.identifier));
		//NSLog(@"SHOW RUNNING %f %f %@", (leadingConstraint.constant), (leadingConstraint.animator.constant), (leadingConstraint.animations));
		CGFloat fractionFromDestination = (constraint.constant) / (constraint.animator.constant);
		//NSLog(@"%f", fractionFromDestination);
		
		if (animate) {
			(context.duration) = fractionFromDestination * [self transitionDurationGoingIn];
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

- (void)showChildViewMovingLeading:(NSView *)view animate:(BOOL)animate
{
	[self addViewIfNeeded:view layout:YES];
	
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithIdentifier:@"leading" forChildView:view];
	[self showChildView:view adjustingConstraint:leadingConstraint toValue:0.0 animate:animate];
}

- (void)showChildViewMovingTop:(NSView *)view animate:(BOOL)animate
{
	[self addViewIfNeeded:view layout:YES];
	
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithIdentifier:@"top" forChildView:view];
	[self showChildView:view adjustingConstraint:leadingConstraint toValue:0.0 animate:animate];
}


@end
