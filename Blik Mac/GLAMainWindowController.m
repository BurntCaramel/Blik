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
#import "GLAProjectManager.h"
#import <objc/runtime.h>
@import QuartzCore;


#define USE_MAIN_CONTENT_VIEW_CONTROLLER 1


@interface GLAMainWindowController ()

@end

@implementation GLAMainWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        
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
	
	//TODO: add waiting to load animation
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	[projectManager useAllProjects:^(NSArray *allProjects) {
		GLAProject *dummyProject = allProjects[0];
		[self workOnProjectNow:dummyProject];
	}];
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
	GLAMainContentViewController *controller = [[GLAMainContentViewController alloc] init];
	(controller.delegate) = self;
	(controller.view) = (self.contentView);
	(controller.view.identifier) = @"contentView";
	
	(self.mainContentViewController) = controller;
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
		[(self.mainContentViewController) fillViewWithChildView:view];
		
		if (layout) {
			[(self.mainContentViewController.view) layoutSubtreeIfNeeded];
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

#pragma mark Editing Projects

- (void)goToSection:(GLAMainContentSection *)newSection
{
	if ([newSection isEqual:(self.currentSection)]) {
		return;
	}
	
	(self.currentSection) = newSection;
	
	[(self.mainContentViewController) goToSection:newSection];
	[(self.mainNavigationBarController) changeCurrentSectionTo:newSection];
}

- (void)goToPreviousSection
{
	NSLog(@"-goToPreviousSection %@", (self.currentSection.previousSection));
	[self goToSection:(self.currentSection.previousSection)];
}

- (void)workOnProjectNow:(GLAProject *)project
{
	[[GLAProjectManager sharedProjectManager] changeNowProject:project];
	
	[(self.mainContentViewController) changeNowProject:project];
	
	[self goToSection:[GLAMainContentSection nowSection]];
}

- (void)editProject:(GLAProject *)project
{
	NSLog(@"editProject; %@", (self.currentSection));
	[self goToSection:[GLAMainContentEditProjectSection editProjectSectionWithProject:project previousSection:(self.currentSection)]];
}

#pragma mark New Project

- (IBAction)addNewProject:(id)sender
{
	[self goToSection:[GLAMainContentSection addNewProjectSectionWithPreviousSection:(self.currentSection)]];
}

- (void)confirmAddingNewProject
{
	
}

#pragma mark Collections

- (void)enterCollection:(GLACollection *)collection
{
	GLAMainContentSection *currentSection = (self.currentSection);
	NSAssert1((currentSection.isNow) || [currentSection isKindOfClass:[GLAMainContentEditProjectSection class]], @"When entering a collection, the previously current section (%@) must be now or an edit project section", currentSection);
	
	[self goToSection:[GLAMainContentEditCollectionSection editCollectionSectionWithCollection:collection previousSection:currentSection]];
}

#pragma mark Actions

- (IBAction)goToAll:(id)sender
{
	[(self.mainNavigationBarController) goToAll:sender];
}

- (IBAction)goToToday:(id)sender
{
	[(self.mainNavigationBarController) goToToday:sender];
}

- (IBAction)goToPlanned:(id)sender
{
	[(self.mainNavigationBarController) goToPlanned:sender];
}

- (IBAction)workOnEditedProjectNow:(id)sender
{
	if ([self canWorkOnEditedProjectNow]) {
		GLAProjectViewController *activeProjectViewController = (self.mainContentViewController.activeProjectViewController);
		[self workOnProjectNow:(activeProjectViewController.project)];
	}
}

- (BOOL)canWorkOnEditedProjectNow
{
	GLAMainContentViewController *mainContentViewController = (self.mainContentViewController);
	GLAProjectViewController *activeProjectViewController = (mainContentViewController.activeProjectViewController);
	if (!!activeProjectViewController && (activeProjectViewController == (mainContentViewController.editedProjectViewController))) {
		return YES;
	}
	else {
		return NO;
	}
}

#pragma mark Validating UI Items

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
	SEL action = (anItem.action);
	if (sel_isEqual(@selector(workOnEditedProjectNow:), action)) {
		return [self canWorkOnEditedProjectNow];
	}
	
	return YES;
}

#pragma mark Project View Controller Notifications

- (void)activeProjectViewControllerDidBeginEditing:(NSNotification *)note
{NSLog(@"activeProjectViewControllerDidBeginEditing");
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
	[self enterCollection:collection];
}

#pragma mark GLAMainContentViewControllerDelegate

- (void)mainContentViewController:(GLAMainContentViewController *)contentViewController projectViewControllerDidBecomeActive:(GLAProjectViewController *)projectViewController
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

- (void)mainContentViewController:(GLAMainContentViewController *)contentViewController projectViewControllerDidBecomeInactive:(GLAProjectViewController *)projectViewController
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	// Remove all that were added in -projectViewControllerDidBecomeActive:
	[nc removeObserver:self name:nil object:projectViewController];
}

- (void)mainContentViewController:(GLAMainContentViewController *)contentViewController projectsListViewController:(GLAProjectsListViewController *)projectsListViewController didClickOnProject:(GLAProject *)project
{
	[self editProject:project];
}

- (void)mainContentViewController:(GLAMainContentViewController *)contentViewController projectsListViewController:(GLAProjectsListViewController *)projectsListViewController didPerformWorkOnProject:(GLAProject *)project
{
	[self workOnProjectNow:project];
}

#pragma mark Main Navigation

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller performChangeCurrentSectionTo:(GLAMainContentSection *)newSection
{
	[self goToSection:newSection];
}

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller performAddNewProject:(id)sender
{
	[self addNewProject:sender];
}

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller performConfirmNewProject:(id)sender
{
	[self confirmAddingNewProject];
}

- (void)mainNavigationBarControllerDidExitEditedProject:(GLAProject *)project
{
	[self goToPreviousSection];
}

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller performWorkOnProjectNow:(GLAProject *)project
{
	[self workOnProjectNow:project];
}

- (void)mainNavigationBarControllerDidExitEditedCollection:(GLAMainNavigationBarController *)controller
{
	[self goToPreviousSection];
}

@end
