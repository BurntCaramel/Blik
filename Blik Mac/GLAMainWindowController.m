//
//  GLAPrototypeBWindowController.m
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAMainWindowController.h"
#import "GLAUIStyle.h"
#import "GLATableRowView.h"
@import QuartzCore;


@interface GLAMainWindowController ()

@end

@implementation GLAMainWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        (self.currentSection) = GLAMainWindowControllerSectionUnknown;
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	(self.window.movableByWindowBackground) = YES;
	
	[self setUpBaseUI];
	
	[self setUpContentViewController];
	[self setUpMainNavigationBarController];
	[self setUpNowProjectViewControllerIfNeeded];
	//[self projectViewControllerDidBecomeActive:(self.nowProjectViewController)];
	
	GLAProject *dummyProject = (self.allProjectsDummyContent)[0];
	[self workOnProjectNow:dummyProject];
}

#pragma mark Setting Up View Controllers

- (void)setUpBaseUI
{
	(self.barHolderView.translatesAutoresizingMaskIntoConstraints) = NO;
	(self.contentView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	NSView *contentView = (self.contentView);
	(contentView.wantsLayer) = YES;
	(contentView.layer.backgroundColor) = ([GLAUIStyle activeStyle].contentBackgroundColor.CGColor);
}

- (void)setUpContentViewController
{
	GLAViewController *controller = [[GLAViewController alloc] init];
	(controller.view) = (self.contentView);
	(controller.view.identifier) = @"contentView";
	
	(self.contentViewController) = controller;
}

- (NSString *)layoutConstraintIdentifierWithBase:(NSString *)baseIdentifier inView:(NSView *)view
{
	return [NSString stringWithFormat:@"%@--%@", (view.identifier), baseIdentifier];
}

- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)baseIdentifier view:(NSView *)view inHolderView:(NSView *)holderView
{
	NSString *constraintIdentifier = [self layoutConstraintIdentifierWithBase:baseIdentifier inView:view];
	NSArray *leadingConstraintInArray = [(holderView.constraints) filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", constraintIdentifier]];
	
	if (leadingConstraintInArray.count == 0) {
		return nil;
	}
	else {
		return leadingConstraintInArray[0];
	}
}

- (void)setUpViewController:(NSViewController *)viewController constrainedToFillView:(NSView *)holderView
{
	(viewController.nextResponder) = self;
	
	NSView *view = (viewController.view);
	
	[holderView addSubview:view];
	
	// Interface Builder's default is to have this on for new view controllers in 10.9 for some reason.
	// I have disabled it where I remember to in the xib file.
	(view.translatesAutoresizingMaskIntoConstraints) = NO;
	
	NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:holderView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
	NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:holderView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
	NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:holderView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];
	NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:holderView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
	
	(leadingConstraint.identifier) = [self layoutConstraintIdentifierWithBase:@"leading" inView:view];
	(topConstraint.identifier) = [self layoutConstraintIdentifierWithBase:@"top" inView:view];
	
	[holderView addConstraints:@[widthConstraint, heightConstraint, leadingConstraint, topConstraint]];
}

- (void)addViewToContentViewIfNeeded:(NSView *)view layout:(BOOL)layout
{
	if (!(view.superview)) {
		[(self.contentViewController) fillViewWithChildView:view];
		
		if (layout) {
			[(self.contentViewController.view) layoutSubtreeIfNeeded];
		}
	}
}

- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)baseIdentifier inContentInnerView:(NSView *)view
{
	[self addViewToContentViewIfNeeded:view layout:YES];
	return [self layoutConstraintWithIdentifier:baseIdentifier view:view inHolderView:(self.contentView)];
}

- (void)setUpMainNavigationBarController
{
	if (self.mainNavigationBarController) {
		return;
	}
	
	GLAMainNavigationBarController *controller = [[GLAMainNavigationBarController alloc] initWithNibName:@"GLAMainNavigationBarController" bundle:nil];
	(controller.delegate) = self;
	(controller.view.identifier) = @"mainNavigationBar";
	
	(self.mainNavigationBarController) = controller;
	
	//[(self.mainNavigationBarController) fillViewWithInnerView:(controller.view)];
	[self setUpViewController:controller constrainedToFillView:(self.barHolderView)];
	
	GLAView *navigationBarView = (controller.view);
	(navigationBarView.wantsLayer) = YES;
	(navigationBarView.layer.backgroundColor) = ([GLAUIStyle activeStyle].barBackgroundColor.CGColor);
}

#pragma mark Setting Up Content View Controllers

- (GLAProject *)dummyProjectWithName:(NSString *)name
{
	GLAProject *project = [GLAProject new];
	
	(project.name) = name;
	
	return project;
}

- (NSArray *)allProjectsDummyContent
{
	return @[
	  [self dummyProjectWithName:@"Project With Big Long Name That Goes On"],
	  [self dummyProjectWithName:@"Eat a thousand muffins in one day"],
	  [self dummyProjectWithName:@"Another, yet another project"],
	  [self dummyProjectWithName:@"The one that just won’t die"],
	  [self dummyProjectWithName:@"Could this be my favourite project ever?"],
	  [self dummyProjectWithName:@"Freelance project #82"]
	  ];
}

- (void)setUpAllProjectsViewControllerIfNeeded
{
	if (self.allProjectsViewController) {
		return;
	}
	
	GLAProjectsListViewController *controller = [[GLAProjectsListViewController alloc] initWithNibName:@"GLAProjectsListViewController" bundle:nil];
	(controller.view.identifier) = @"allProjects";
	(controller.projects) = (self.allProjectsDummyContent);
	
	(self.allProjectsViewController) = controller;
	
	// Add it to the content view
	
	[self addViewToContentViewIfNeeded:(controller.view) layout:YES];
	//[(self.contentViewController) fillViewWithInnerView:(controller.view)];
	// Put it into position
	//[self hideChildContentView:(controller.view) offsetBy:-500.0 animate:NO];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(projectListViewControllerDidClickOnProjectNotification:) name:GLAProjectListViewControllerDidClickOnProjectNotification object:controller];
	[nc addObserver:self selector:@selector(projectListViewControllerDidPerformWorkOnProjectNowNotification:) name:GLAProjectListViewControllerDidPerformWorkOnProjectNowNotification object:controller];
}

- (void)setUpNowProjectViewControllerIfNeeded
{
	if (self.nowProjectViewController) {
		return;
	}
	
	GLAProjectViewController *controller = [[GLAProjectViewController alloc] initWithNibName:@"GLAProjectViewController" bundle:nil];
	(controller.view.identifier) = @"nowProject";
	
	(self.nowProjectViewController) = controller;
	
	// Add it to the content view
	[(self.contentViewController) fillViewWithChildView:(controller.view)];
}

- (NSArray *)plannedProjectsDummyContent
{
	return @[
			 [self dummyProjectWithName:@"Eat a thousand muffins in one day"],
			 [self dummyProjectWithName:@"Another, yet another project"],
			 [self dummyProjectWithName:@"The one that just won’t die"],
			 [self dummyProjectWithName:@"Could this be my favourite project ever?"],
			 [self dummyProjectWithName:@"Freelance project #82"]
			 ];
}

- (void)setUpPlannedProjectsViewControllerIfNeeded
{
	if (self.plannedProjectsViewController) {
		return;
	}
	
	GLAProjectsListViewController *controller = [[GLAProjectsListViewController alloc] initWithNibName:@"GLAProjectsListViewController" bundle:nil];
	(controller.view.identifier) = @"plannedProjects";
	(controller.projects) = (self.plannedProjectsDummyContent);
	
	(self.plannedProjectsViewController) = controller;
	
	[self addViewToContentViewIfNeeded:(controller.view) layout:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectListViewControllerDidClickOnProjectNotification:) name:GLAProjectListViewControllerDidClickOnProjectNotification object:controller];
}

- (void)setUpEditedProjectViewControllerIfNeeded
{
	if (self.editedProjectViewController) {
		return;
	}
	
	GLAProjectViewController *controller = [[GLAProjectViewController alloc] initWithNibName:@"GLAProjectViewController" bundle:nil];
	(controller.view.identifier) = @"editedProject";
	
	(self.editedProjectViewController) = controller;
	
	[self addViewToContentViewIfNeeded:(controller.view) layout:YES];
}

- (void)setUpAddedProjectViewControllerIfNeeded
{
	if (self.addedProjectViewController) {
		return;
	}
	
	GLAProjectViewController *controller = [[GLAProjectViewController alloc] initWithNibName:@"GLAProjectViewController" bundle:nil];
	(controller.view.identifier) = @"addedProject";
	
	(self.addedProjectViewController) = controller;
	
	[self addViewToContentViewIfNeeded:(controller.view) layout:YES];
}

#pragma mark Editing Projects

- (void)workOnProjectNow:(GLAProject *)project
{
	(self.nowProjectViewController.project) = project;
	
	[(self.mainNavigationBarController) changeCurrentSectionTo:GLAMainNavigationSectionToday];
	[self transitionContentToSection:GLAMainWindowControllerSectionToday animate:YES];
}

- (void)editProject:(id)project
{
	[self setUpEditedProjectViewControllerIfNeeded];
	(self.editedProjectViewController.project) = project;
	
	GLAMainWindowControllerSection currentSection = (self.currentSection);
	if (currentSection == GLAMainWindowControllerSectionAll) {
		[self transitionContentToSection:GLAMainWindowControllerSectionAllEditProject animate:YES];
	}
	else if (currentSection == GLAMainWindowControllerSectionPlanned) {
		[self transitionContentToSection:GLAMainWindowControllerSectionPlannedEditProject animate:YES];
	}
	
	[(self.mainNavigationBarController) enterProject:project];
}

- (void)endEditingProject:(id)project
{
	GLAMainWindowControllerSection currentSection = (self.currentSection);
	if (currentSection == GLAMainWindowControllerSectionAddNewProject) {
		GLAMainWindowControllerSection navSection = [self sectionForNavigationSection:(self.mainNavigationBarController.currentSection)];
		[self transitionContentToSection:navSection animate:YES];
	}
	else {
		if (currentSection == GLAMainWindowControllerSectionAllEditProject) {
			[self transitionContentToSection:GLAMainWindowControllerSectionAll animate:YES];
		}
		else if (currentSection == GLAMainWindowControllerSectionPlannedEditProject) {
			[self transitionContentToSection:GLAMainWindowControllerSectionPlanned animate:YES];
		}
	}
}

#pragma mark New Project

- (IBAction)addNewProject:(id)sender
{
	[self setUpAddedProjectViewControllerIfNeeded];
	
	GLAProjectViewController *viewController = (self.addedProjectViewController);
	
	id project = nil;
	(viewController.project) = project;
	[viewController clearName];
	
	[self transitionContentToSection:GLAMainWindowControllerSectionAddNewProject animate:YES];
	
	[(self.mainNavigationBarController) enterAddedProject:project];
	[viewController focusNameTextField];
}

#pragma mark Working with Project List View Controllers

- (void)projectListViewControllerDidClickOnProjectNotification:(NSNotification *)note
{
	GLAProject *project = (note.userInfo)[@"project"];
	[self editProject:project];
}

- (void)projectListViewControllerDidPerformWorkOnProjectNowNotification:(NSNotification *)note
{
	GLAProject *project = (note.userInfo)[@"project"];
	[self workOnProjectNow:project];
}

#pragma mark Working with Project View Controllers

- (GLAProjectViewController *)activeProjectViewController
{
	switch (self.currentSection) {
		case GLAMainWindowControllerSectionToday:
			return (self.nowProjectViewController);
			
		case GLAMainWindowControllerSectionAllEditProject:
		case GLAMainWindowControllerSectionPlannedEditProject:
			return (self.editedProjectViewController);
			
		case GLAMainWindowControllerSectionAddNewProject:
			return (self.addedProjectViewController);
			
		default:
			return nil;
	}
}

- (IBAction)workOnEditedProjectNow:(id)sender
{
	GLAProjectViewController *projectViewController = (self.editedProjectViewController);
	if ((projectViewController) && (projectViewController.project)) {
		[self workOnProjectNow:(projectViewController.project)];
	}
}

- (BOOL)canWorkOnEditedProjectNow
{
	GLAProjectViewController *projectViewController = (self.editedProjectViewController);
	if ((projectViewController) && (projectViewController.project)) {
		return YES;
	}
	else {
		return NO;
	}
}

- (void)projectViewControllerDidBecomeActive:(GLAProjectViewController *)projectViewController
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	// Begin editing items
	[nc addObserver:self selector:@selector(activeProjectViewControllerDidBeginEditing:) name:GLAProjectViewControllerDidBeginEditingItemsNotification object:projectViewController];
	// Begin editing plan
	[nc addObserver:self selector:@selector(activeProjectViewControllerDidBeginEditing:) name:GLAProjectViewControllerDidBeginEditingPlanNotification object:projectViewController];
	// End editing items
	[nc addObserver:self selector:@selector(activeProjectViewControllerDidEndEditing:) name:GLAProjectViewControllerDidEndEditingItemsNotification object:projectViewController];
	// End editing plan
	[nc addObserver:self selector:@selector(activeProjectViewControllerDidEndEditing:) name:GLAProjectViewControllerDidEndEditingPlanNotification object:projectViewController];
	
	// Enter collection
	[nc addObserver:self selector:@selector(activeProjectViewControllerDidEnterCollection:) name:GLAProjectViewControllerDidEnterCollectionNotification object:projectViewController];
}

- (void)projectViewControllerDidBecomeInactive:(GLAProjectViewController *)projectViewController
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	// Remove all that were added in -projectViewControllerDidBecomeActive:
	[nc removeObserver:self name:nil object:projectViewController];
}

- (void)activeProjectViewControllerDidBeginEditing:(NSNotification *)note
{
	(self.mainNavigationBarController.enabled) = NO;
}

- (void)activeProjectViewControllerDidEndEditing:(NSNotification *)note
{
	GLAProjectViewController *controller = (note.object);
	if (controller != (self.addedProjectViewController)) {
		(self.mainNavigationBarController.enabled) = YES;
	}
}

- (void)activeProjectViewControllerDidEnterCollection:(NSNotification *)note
{
	GLACollection *collection = (note.userInfo)[@"collection"];
	[(self.mainNavigationBarController) enterProjectCollection:collection];
}

- (GLAMainWindowControllerSection)sectionForNavigationSection:(GLAMainNavigationSection)navigationSection
{
	switch (navigationSection) {
		case GLAMainNavigationSectionAll:
			return GLAMainWindowControllerSectionAll;
			
		case GLAMainNavigationSectionPlanned:
			return GLAMainWindowControllerSectionPlanned;
			
		case GLAMainNavigationSectionToday:
			return GLAMainWindowControllerSectionToday;
			
		default:
			return GLAMainWindowControllerSectionUnknown;
	}
}

#pragma mark Main Navigation

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller didChangeCurrentSection:(GLAMainNavigationSection)newNavigationSection
{
	GLAMainWindowControllerSection newSection = [self sectionForNavigationSection:newNavigationSection];
	[self transitionContentToSection:newSection animate:YES];
}

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller performAddNewProject:(id)sender
{
	[self addNewProject:sender];
}

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller didExitProject:(GLAProject *)project
{
	[self endEditingProject:project];
}

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller performWorkOnProjectNow:(GLAProject *)project
{
	[self workOnProjectNow:project];
}

#pragma mark Content Transitioning

- (GLAViewController *)viewControllerForSection:(GLAMainWindowControllerSection)section
{
	switch (section) {
		case GLAMainWindowControllerSectionAll:
			return (self.allProjectsViewController);
			
		case GLAMainWindowControllerSectionToday:
			return (self.nowProjectViewController);
		
		case GLAMainWindowControllerSectionPlanned:
			return (self.plannedProjectsViewController);
		
		case GLAMainWindowControllerSectionAllEditProject:
		case GLAMainWindowControllerSectionPlannedEditProject:
			return (self.editedProjectViewController);
		
		case GLAMainWindowControllerSectionAddNewProject:
			return (self.addedProjectViewController);
			
		default:
			return nil;
	}
}

- (void)transitionContentToSection:(GLAMainWindowControllerSection)newSection animate:(BOOL)animate
{
	GLAMainWindowControllerSection previousSection = (self.currentSection);
	if (previousSection == newSection) {
		return;
	}
	
	[self didBeginTransitionAwayFromViewController:[self viewControllerForSection:previousSection]];
	
	if (newSection == GLAMainWindowControllerSectionAll) {
		[self setUpAllProjectsViewControllerIfNeeded];
		//[(self.allProjectsViewController.tableView) sizeLastColumnToFit];
		
		if (previousSection == GLAMainWindowControllerSectionAllEditProject) {
			[self hideChildContentView:(self.editedProjectViewController.view) moveLeadingTo:500.0 animate:YES];
		}
		else if (previousSection == GLAMainWindowControllerSectionAddNewProject) {
			[self hideChildContentView:(self.addedProjectViewController.view) moveLeadingTo:500.0 animate:YES];
		}
		else if (previousSection == GLAMainWindowControllerSectionToday) {
			[self hideChildContentView:(self.nowProjectViewController.view) moveLeadingTo:500.0 animate:YES];
		}
		else if (previousSection == GLAMainWindowControllerSectionPlanned) {
			[self hideChildContentView:(self.plannedProjectsViewController.view) moveLeadingTo:1000.0 animate:YES];
		}
		
		[self hideChildContentView:(self.allProjectsViewController.view) moveLeadingTo:-500.0 animate:NO];
		[self showChildContentViewMovingLeading:(self.allProjectsViewController.view) animate:YES];
	}
	else if (newSection == GLAMainWindowControllerSectionToday) {
		[self setUpNowProjectViewControllerIfNeeded];
		
		BOOL animateNowIn = YES;
		
		if (previousSection == GLAMainWindowControllerSectionAll) {
			[self hideChildContentView:(self.allProjectsViewController.view) moveLeadingTo:-500.0 animate:YES];
			[self hideChildContentView:(self.nowProjectViewController.view) moveLeadingTo:500.0 animate:NO];
		}
		else if (previousSection == GLAMainWindowControllerSectionPlanned) {
			[self hideChildContentView:(self.plannedProjectsViewController.view) moveLeadingTo:500.0 animate:YES];
			[self hideChildContentView:(self.nowProjectViewController.view) moveLeadingTo:-500.0 animate:NO];
		}
		else if (previousSection == GLAMainWindowControllerSectionAddNewProject) {
			[self hideChildContentView:(self.addedProjectViewController.view) moveLeadingTo:500.0 animate:YES];
			[self hideChildContentView:(self.nowProjectViewController.view) moveLeadingTo:-500.0 animate:NO];
		}
		else if (previousSection == GLAMainWindowControllerSectionAllEditProject || previousSection == GLAMainWindowControllerSectionPlannedEditProject) {
			NSViewController *vc = [self viewControllerForSection:previousSection];
			[(vc.view) removeFromSuperview];
			
			animateNowIn = NO;
		}
		
		[self showChildContentViewMovingLeading:(self.nowProjectViewController.view) animate:animateNowIn];
	}
	else if (newSection == GLAMainWindowControllerSectionPlanned) {
		[self setUpPlannedProjectsViewControllerIfNeeded];
		//[(self.plannedProjectsViewController.tableView) sizeLastColumnToFit];
		
		if (previousSection == GLAMainWindowControllerSectionPlannedEditProject) {
			[self hideChildContentView:(self.editedProjectViewController.view) moveLeadingTo:500.0 animate:YES];
		}
		else if (previousSection == GLAMainWindowControllerSectionAddNewProject) {
			[self hideChildContentView:(self.addedProjectViewController.view) moveLeadingTo:500.0 animate:YES];
		}
		else if (previousSection == GLAMainWindowControllerSectionToday) {
			[self hideChildContentView:(self.nowProjectViewController.view) moveLeadingTo:-500.0 animate:YES];
		}
		else if (previousSection == GLAMainWindowControllerSectionAll) {
			[self hideChildContentView:(self.allProjectsViewController.view) moveLeadingTo:-1000.0 animate:YES];
		}
		
		if (previousSection == GLAMainWindowControllerSectionToday || previousSection == GLAMainWindowControllerSectionAll) {
			[self hideChildContentView:(self.plannedProjectsViewController.view) moveLeadingTo:500.0 animate:NO];
		}
		else {
			[self hideChildContentView:(self.plannedProjectsViewController.view) moveLeadingTo:-500.0 animate:NO];
		}
		[self showChildContentViewMovingLeading:(self.plannedProjectsViewController.view) animate:YES];
	}
	else if (newSection == GLAMainWindowControllerSectionAllEditProject) {
		[self setUpEditedProjectViewControllerIfNeeded];
		[self hideChildContentView:(self.editedProjectViewController.view) moveLeadingTo:500.0 animate:NO];
		
		[self hideChildContentView:(self.allProjectsViewController.view) moveLeadingTo:-500.0 animate:YES];
		[self showChildContentViewMovingLeading:(self.editedProjectViewController.view) animate:YES];
	}
	else if (newSection == GLAMainWindowControllerSectionPlannedEditProject) {
		[self setUpEditedProjectViewControllerIfNeeded];
		[self hideChildContentView:(self.editedProjectViewController.view) moveLeadingTo:500.0 animate:NO];
		
		[self hideChildContentView:(self.plannedProjectsViewController.view) moveLeadingTo:-500.0 animate:YES];
		[self showChildContentViewMovingLeading:(self.editedProjectViewController.view) animate:YES];
	}
	else if (newSection == GLAMainWindowControllerSectionAddNewProject) {
		[self setUpAddedProjectViewControllerIfNeeded];
		
		[self hideChildContentView:(self.addedProjectViewController.view) moveLeadingTo:500.0 animate:NO];
		//[self hideChildContentView:(self.addedProjectViewController.view) moveTopTo:-700.0 animate:NO];
		
		GLAViewController *previousViewController = [self viewControllerForSection:previousSection];
		[self hideChildContentView:(previousViewController.view) moveLeadingTo:-500.0 animate:YES];
		
		[self showChildContentViewMovingLeading:(self.addedProjectViewController.view) animate:YES];
		//[self showChildContentViewMovingTop:(self.addedProjectViewController.view) animate:YES];
	}
	
	(self.currentSection) = newSection;
	
	[self didBeginTransitionToViewController:[self viewControllerForSection:newSection]];
}

- (void)didBeginTransitionToViewController:(NSViewController *)viewController
{
	if (viewController == (self.nowProjectViewController) || viewController == (self.addedProjectViewController) || viewController == (self.editedProjectViewController)) {
		GLAProjectViewController *projectVC = (GLAProjectViewController *)viewController;
		
		[self projectViewControllerDidBecomeActive:projectVC];
	}
	else if (viewController == (self.allProjectsViewController) || viewController == (self.plannedProjectsViewController)) {
		GLAProjectsListViewController *projectListVC = (GLAProjectsListViewController *)viewController;
		
		[projectListVC viewDidAppear];
	}
}

- (void)didBeginTransitionAwayFromViewController:(NSViewController *)viewController
{
	if (viewController == (self.nowProjectViewController) || viewController == (self.addedProjectViewController) || viewController == (self.editedProjectViewController)) {
		GLAProjectViewController *projectVC = (GLAProjectViewController *)viewController;
		[self projectViewControllerDidBecomeInactive:projectVC];
	}
}

- (NSTimeInterval)contentViewTransitionDurationGoingInNotOut:(BOOL)inNotOut
{
	// IN
	if (inNotOut) {
		return 4.0 / 12.0;
	}
	// OUT
	else {
		return 4.0 / 12.0;
	}
}

#pragma mark Adjusting Individual Content Views

- (void)hideChildContentView:(NSView *)view adjustingConstraint:(NSLayoutConstraint *)constraint toValue:(CGFloat)constraintValue animate:(BOOL)animate
{
	//[self addViewToContentViewIfNeeded:view layout:YES];
	
	GLAMainWindowControllerSection currentSection = (self.currentSection);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		if (animate) {
			(context.duration) = [self contentViewTransitionDurationGoingInNotOut:NO];
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

- (void)hideChildContentView:(NSView *)view moveLeadingTo:(CGFloat)offset animate:(BOOL)animate
{
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithIdentifier:@"leading" inContentInnerView:view];
	[self hideChildContentView:view adjustingConstraint:leadingConstraint toValue:offset animate:animate];
}

- (void)hideChildContentView:(NSView *)view moveTopTo:(CGFloat)offset animate:(BOOL)animate
{
	NSLayoutConstraint *topConstraint = [self layoutConstraintWithIdentifier:@"top" inContentInnerView:view];
	[self hideChildContentView:view adjustingConstraint:topConstraint toValue:offset animate:animate];
}

- (void)showChildContentView:(NSView *)view adjustingConstraint:(NSLayoutConstraint *)constraint toValue:(CGFloat)constraintValue animate:(BOOL)animate
{
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(view.hidden) = NO;
		
		//NSLog(@"Show running %@", (view.identifier));
		//NSLog(@"SHOW RUNNING %f %f %@", (leadingConstraint.constant), (leadingConstraint.animator.constant), (leadingConstraint.animations));
		CGFloat fractionFromDestination = ((constraint.constant) / (constraint.animator.constant));
		//NSLog(@"%f", fractionFromDestination);
		
		if (animate) {
			(context.duration) = fractionFromDestination * [self contentViewTransitionDurationGoingInNotOut:YES];
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
		//NSLog(@"SHOW COMPLETED %@", (view.identifier));
	}];
}

- (void)showChildContentViewMovingLeading:(NSView *)view animate:(BOOL)animate
{
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithIdentifier:@"leading" inContentInnerView:view];
	[self showChildContentView:view adjustingConstraint:leadingConstraint toValue:0.0 animate:animate];
}

- (void)showChildContentViewMovingTop:(NSView *)view animate:(BOOL)animate
{
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithIdentifier:@"top" inContentInnerView:view];
	[self showChildContentView:view adjustingConstraint:leadingConstraint toValue:0.0 animate:animate];
}

@end
