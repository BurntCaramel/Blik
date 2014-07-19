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
        (self.currentSection) = GLAMainWindowControllerSectionToday;
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
	[self setUpNowProjectViewController];
	[self projectViewControllerDidBecomeActive:(self.nowProjectViewController)];
}

#pragma mark Setting Up View Controllers

- (void)setUpBaseUI
{
	(self.barHolderView.translatesAutoresizingMaskIntoConstraints) = NO;
	(self.contentView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	NSView *contentView = (self.contentView);
	(contentView.wantsLayer) = YES;
	(contentView.layer.backgroundColor) = ([GLAUIStyle styleA].contentBackgroundColor.CGColor);
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

- (NSLayoutConstraint *)layoutConstraintWithBaseIdentifier:(NSString *)baseIdentifier view:(NSView *)view inHolderView:(NSView *)holderView
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
	
	if (holderView) {
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
	
	[self setUpViewController:controller constrainedToFillView:(self.barHolderView)];
}

#pragma mark Setting Up Content View Controllers

- (NSArray *)allProjectsDummyContent
{
	return @[
	  @"Project With Big Long Name That Goes On",
	  @"Eat a thousand muffins in one day",
	  @"Another, yet another project",
	  @"The one that just won’t die",
	  @"Could this be my favourite project ever?",
	  @"Freelance project #82"
	  ];
}

- (BOOL)setUpAllProjectsViewController
{
	if (self.allProjectsViewController) {
		return NO;
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectListViewControllerDidClickOnProjectNotification:) name:GLAProjectListViewControllerDidClickOnProjectNotification object:controller];
	
	return YES;
}

- (BOOL)setUpNowProjectViewController
{
	if (self.nowProjectViewController) {
		return NO;
	}
	
	GLAProjectViewController *controller = [[GLAProjectViewController alloc] initWithNibName:@"GLAProjectViewController" bundle:nil];
	(controller.view.identifier) = @"nowProject";
	
	(self.nowProjectViewController) = controller;
	
	// Add it to the content view
	[(self.contentViewController) fillViewWithInnerView:(controller.view)];
	
	return YES;
}

- (NSArray *)plannedProjectsDummyContent
{
	return @[
			 @"Eat a thousand muffins in one day",
			 @"Another, yet another project",
			 @"The one that just won’t die",
			 @"Could this be my favourite project ever?",
			 @"Freelance project #82"
			 ];
}

- (BOOL)setUpPlannedProjectsViewController
{
	if (self.plannedProjectsViewController) {
		return NO;
	}
	
	GLAProjectsListViewController *controller = [[GLAProjectsListViewController alloc] initWithNibName:@"GLAProjectsListViewController" bundle:nil];
	(controller.view.identifier) = @"plannedProjects";
	(controller.projects) = (self.plannedProjectsDummyContent);
	
	(self.plannedProjectsViewController) = controller;
	
	// Add it to the content view
	[self addViewToContentViewIfNeeded:(controller.view) layout:YES];
	//[(self.contentViewController) fillViewWithInnerView:(controller.view)];
	// Put it into position
	//[self hideChildContentView:(controller.view) offsetBy:500.0 animate:NO];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectListViewControllerDidClickOnProjectNotification:) name:GLAProjectListViewControllerDidClickOnProjectNotification object:controller];
	
	return YES;
}

- (BOOL)setUpEditedProjectViewController
{
	if (self.editedProjectViewController) {
		return NO;
	}
	
	GLAProjectViewController *controller = [[GLAProjectViewController alloc] initWithNibName:@"GLAProjectViewController" bundle:nil];
	(controller.view.identifier) = @"editedProject";
	
	(self.editedProjectViewController) = controller;
	
	// Add it to the content view
	[self addViewToContentViewIfNeeded:(controller.view) layout:YES];
	//[self addViewToContentViewIfNeeded:(controller.view) layout:YES];
	//[(self.contentViewController) fillViewWithInnerView:(controller.view)];
	// Put it into position
	//[self hideChildContentView:(controller.view) offsetBy:500.0 animate:NO];
	
	return YES;
}

#pragma mark Editing Projects

- (void)editProject:(id)project
{
	[self setUpEditedProjectViewController];
	(self.editedProjectViewController.project) = project;
	
	GLAMainWindowControllerSection currentSection = (self.currentSection);
	if (currentSection == GLAMainWindowControllerSectionAll) {
		[self transitionToSection:GLAMainWindowControllerSectionAllEditProject animate:YES];
	}
	else if (currentSection == GLAMainWindowControllerSectionPlanned) {
		[self transitionToSection:GLAMainWindowControllerSectionPlannedEditProject animate:YES];
	}
	
	[(self.mainNavigationBarController) enterProject:project];
	
	[self projectViewControllerDidBecomeActive:(self.editedProjectViewController)];
}

- (void)endEditingProject:(id)project
{
	[self projectViewControllerDidBecomeInactive:(self.editedProjectViewController)];
	
	GLAMainWindowControllerSection currentSection = (self.currentSection);
	if (currentSection == GLAMainWindowControllerSectionAllEditProject) {
		[self transitionToSection:GLAMainWindowControllerSectionAll animate:YES];
	}
	else if (currentSection == GLAMainWindowControllerSectionPlannedEditProject) {
		[self transitionToSection:GLAMainWindowControllerSectionPlanned animate:YES];
	}
}

#pragma mark Working with Project List View Controllers

- (void)projectListViewControllerDidClickOnProjectNotification:(NSNotification *)note
{
	id project = (note.userInfo)[@"project"];
	[self editProject:project];
}

#pragma mark Working with Project View Controllers

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
}

- (void)projectViewControllerDidBecomeInactive:(GLAProjectViewController *)projectViewController
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:GLAProjectViewControllerDidBeginEditingItemsNotification object:projectViewController];
	[nc removeObserver:self name:GLAProjectViewControllerDidBeginEditingPlanNotification object:projectViewController];
	[nc removeObserver:self name:GLAProjectViewControllerDidEndEditingItemsNotification object:projectViewController];
	[nc removeObserver:self name:GLAProjectViewControllerDidEndEditingPlanNotification object:projectViewController];
}

- (void)activeProjectViewControllerDidBeginEditing:(NSNotification *)note
{
	(self.mainNavigationBarController.enabled) = NO;
}

- (void)activeProjectViewControllerDidEndEditing:(NSNotification *)note
{
	(self.mainNavigationBarController.enabled) = YES;
}

#pragma mark Main Navigation

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller didChangeCurrentSection:(GLAMainNavigationSection)newNavigationSection
{
	GLAMainWindowControllerSection newSection;
	
	switch (newNavigationSection) {
		case GLAMainNavigationSectionAll:
			newSection = GLAMainWindowControllerSectionAll;
			break;
		
		case GLAMainNavigationSectionPlanned:
			newSection = GLAMainWindowControllerSectionPlanned;
			break;
		
		case GLAMainNavigationSectionToday:
			newSection = GLAMainWindowControllerSectionToday;
			break;
		
		default:
			return;
	}
	
	[self transitionToSection:newSection animate:YES];
}

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller didExitProject:(id)project
{
	[self endEditingProject:project];
}

#pragma mark Content Transitioning

- (void)transitionToSection:(GLAMainWindowControllerSection)newSection animate:(BOOL)animate
{
	GLAMainWindowControllerSection previousSection = (self.currentSection);
	(self.currentSection) = newSection;
	
	if (newSection == GLAMainWindowControllerSectionAll) {
		if (previousSection == GLAMainWindowControllerSectionAllEditProject) {
			[self hideChildContentView:(self.allProjectsViewController.view) offsetBy:-500.0 animate:NO];
			
			[self showChildContentView:(self.allProjectsViewController.view) animate:YES];
			[self hideChildContentView:(self.editedProjectViewController.view) offsetBy:500.0 animate:YES];
		}
		else {
			[self setUpAllProjectsViewController];
			[self hideChildContentView:(self.allProjectsViewController.view) offsetBy:-500.0 animate:NO];
			
			[self showChildContentView:(self.allProjectsViewController.view) animate:YES];
			[self hideChildContentView:(self.nowProjectViewController.view) offsetBy:500.0 animate:YES];
			
			if (self.plannedProjectsViewController) {
				[self hideChildContentView:(self.plannedProjectsViewController.view) offsetBy:1000.0 animate:YES];
			}
		}
	}
	else if (newSection == GLAMainWindowControllerSectionToday) {
		[self setUpNowProjectViewController];
		
		if (previousSection == GLAMainWindowControllerSectionAll) {
			[self hideChildContentView:(self.nowProjectViewController.view) offsetBy:500.0 animate:NO];
		}
		else if (previousSection == GLAMainWindowControllerSectionPlanned) {
			[self hideChildContentView:(self.nowProjectViewController.view) offsetBy:-500.0 animate:NO];
		}
		[self showChildContentView:(self.nowProjectViewController.view) animate:YES];
		
		if (self.allProjectsViewController) {
			[self hideChildContentView:(self.allProjectsViewController.view) offsetBy:-500.0 animate:YES];
		}
		
		if (self.plannedProjectsViewController) {
			[self hideChildContentView:(self.plannedProjectsViewController.view) offsetBy:500.0 animate:YES];
		}
	}
	else if (newSection == GLAMainWindowControllerSectionPlanned) {
		if (previousSection == GLAMainWindowControllerSectionPlannedEditProject) {
			[self hideChildContentView:(self.plannedProjectsViewController.view) offsetBy:-500.0 animate:NO];
			
			[self showChildContentView:(self.plannedProjectsViewController.view) animate:YES];
			[self hideChildContentView:(self.editedProjectViewController.view) offsetBy:500.0 animate:YES];
		}
		else {
			[self setUpPlannedProjectsViewController];
			[self hideChildContentView:(self.plannedProjectsViewController.view) offsetBy:500.0 animate:NO];
			
			[self hideChildContentView:(self.nowProjectViewController.view) offsetBy:-500.0 animate:YES];
			[self showChildContentView:(self.plannedProjectsViewController.view) animate:YES];
			
			if (self.allProjectsViewController) {
				[self hideChildContentView:(self.allProjectsViewController.view) offsetBy:-1000.0 animate:YES];
			}
		}
	}
	else if (newSection == GLAMainWindowControllerSectionAllEditProject) {
		[self setUpEditedProjectViewController];
		[self hideChildContentView:(self.editedProjectViewController.view) offsetBy:500.0 animate:NO];
		
		[self hideChildContentView:(self.allProjectsViewController.view) offsetBy:-500.0 animate:YES];
		[self showChildContentView:(self.editedProjectViewController.view) animate:YES];
	}
	else if (newSection == GLAMainWindowControllerSectionPlannedEditProject) {
		[self setUpEditedProjectViewController];
		[self hideChildContentView:(self.editedProjectViewController.view) offsetBy:500.0 animate:NO];
		
		[self hideChildContentView:(self.plannedProjectsViewController.view) offsetBy:-500.0 animate:YES];
		[self showChildContentView:(self.editedProjectViewController.view) animate:YES];
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

- (void)addViewToContentViewIfNeeded:(NSView *)view layout:(BOOL)layout
{
	if (!(view.superview)) {
		[(self.contentViewController) fillViewWithInnerView:view];
		
		if (layout) {
			[(self.contentViewController.view) layoutSubtreeIfNeeded];
		}
	}
}

- (void)hideChildContentView:(NSView *)view offsetBy:(CGFloat)offset animate:(BOOL)animate
{
	[self addViewToContentViewIfNeeded:view layout:YES];
	
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithBaseIdentifier:@"leading" view:view inHolderView:(self.contentView)];
	if (!leadingConstraint) {
		return;
	}
	
	//GLAMainNavigationSection currentSection = (self.currentSection);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		//NSLog(@"HIDE RUNNING %@", (view.identifier));
		if (animate) {
			(context.duration) = [self contentViewTransitionDurationGoingInNotOut:NO];
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(view.animator.alphaValue) = 0.0;
			(leadingConstraint.animator.constant) = offset;
		}
		else {
			(context.duration) = 0;
			(view.alphaValue) = 0.0;
			(leadingConstraint.constant) = offset;
		}
		
		//(context.allowsImplicitAnimation) = YES;
		//[view layoutSubtreeIfNeeded];
	} completionHandler:^ {
		// If the current section hasn't been changed back before the animation finishes:
		if ((self.currentSection) != GLAMainWindowControllerSectionToday) {
			//(view.hidden) = YES;
		}
		
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
			[view removeFromSuperview];
			//[(view.superview) layoutSubtreeIfNeeded];
		}
		//[(self.contentViewController.view) layoutSubtreeIfNeeded];
		//NSLog(@"HIDE COMPLETED %@", (view.identifier));
	}];
}

- (void)showChildContentView:(NSView *)view animate:(BOOL)animate
{
	[self addViewToContentViewIfNeeded:view layout:YES];
	
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithBaseIdentifier:@"leading" view:view inHolderView:(self.contentView)];
	if (!leadingConstraint) {
		return;
	}
	/*
	// Run a zero duration animation to get any previous ones to complete.
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 0;
		(view.hidden) = NO;
	} completionHandler:nil];
	*/
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(view.hidden) = NO;
		
		//NSLog(@"Show running %@", (view.identifier));
		//NSLog(@"SHOW RUNNING %f %f %@", (leadingConstraint.constant), (leadingConstraint.animator.constant), (leadingConstraint.animations));
		CGFloat fractionFromDestination = ((leadingConstraint.constant) / (leadingConstraint.animator.constant));
		//NSLog(@"%f", fractionFromDestination);
		
		if (animate) {
			(context.duration) = fractionFromDestination * [self contentViewTransitionDurationGoingInNotOut:YES];
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(view.animator.alphaValue) = 1.0;
			(leadingConstraint.animator.constant) = 0.0;
		}
		else {
			(context.duration) = 0;
			(view.alphaValue) = 1.0;
			(leadingConstraint.constant) = 0.0;
		}
		
		//(context.allowsImplicitAnimation) = YES;
		//[view layoutSubtreeIfNeeded];
	} completionHandler:^ {
		//NSLog(@"SHOW COMPLETED %@", (view.identifier));
	}];
}

@end
