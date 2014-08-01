//
//  GLAMainNavigationBarController.m
//  Blik
//
//  Created by Patrick Smith on 10/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAMainNavigationBarController.h"
@import QuartzCore;
#import "GLAButton.h"
#import "GLAUIStyle.h"

@interface GLAMainNavigationBarController ()

@property(readwrite, nonatomic) GLAMainNavigationSection currentSection;

@property(nonatomic) BOOL private_enabled;

@property(readonly, getter = isAnimating, nonatomic) BOOL animating;
@property(nonatomic) NSUInteger animatingCounter;

@property(readonly, nonatomic) NSString *titleForEditingProjectBackButton;

@end

@implementation GLAMainNavigationBarController

- (GLANavigationBar *)navigationBar
{
	return (GLANavigationBar *)(self.view);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		(self.currentSection) = GLAMainNavigationSectionToday;
		[self updateSelectedSectionUI];
		(self.private_enabled) = YES;
    }
    return self;
}

- (void)loadView
{
	[super loadView];
	
	(self.navigationBar.delegate) = self;
	
	(self.templateButton.canDrawSubviewsIntoLayer) = YES;
	[(self.templateButton) removeFromSuperview];
}

- (BOOL)isAnimating
{
	return (self.animatingCounter) > 0;
}

- (void)updateSelectedSectionUI
{
	GLAMainNavigationSection currentSection = (self.currentSection);
	(self.allButton.state) = (currentSection == GLAMainNavigationSectionAll) ? NSOnState : NSOffState;
	(self.todayButton.state) = (currentSection == GLAMainNavigationSectionToday) ? NSOnState : NSOffState;
	(self.plannedButton.state) = (currentSection == GLAMainNavigationSectionPlanned) ? NSOnState : NSOffState;
}

- (void)changeCurrentSectionTo:(GLAMainNavigationSection)newSection
{
	if (self.isAnimating) {
		return;
	}
	
	//GLAMainNavigationSection previousSection = (self.currentSection);
	
	(self.currentSection) = newSection;
	
	if (self.currentProject) {
		if (self.currentProjectIsAddedNew) {
			[self hideButtonsForAddingNewProject];
		}
		else {
			[self hideButtonsForEditingExistingProject];
		}
		[self showMainButtons];
	}
	
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainNavigationBarController:self didChangeCurrentSection:newSection];
	}
	
	[self updateSelectedSectionUI];
}

- (IBAction)goToAll:(id)sender
{
	[self changeCurrentSectionTo:GLAMainNavigationSectionAll];
}

- (IBAction)goToToday:(id)sender
{
	[self changeCurrentSectionTo:GLAMainNavigationSectionToday];
}

- (IBAction)goToPlanned:(id)sender
{
	[self changeCurrentSectionTo:GLAMainNavigationSectionPlanned];
}

#pragma mark Hiding and Showing Buttons

- (void)showMainButtons
{
	(self.animatingCounter)++;
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 12.0;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		(self.allButtonTopConstraint.animator.constant) = 0;
		(self.todayButtonTopConstraint.animator.constant) = 0;
		(self.plannedButtonTopConstraint.animator.constant) = 0;
		(self.addProjectButtonTopConstraint.animator.constant) = 0;
	} completionHandler:^ {
		(self.animatingCounter)--;
	}];
}

- (void)hideMainButtons
{
	(self.animatingCounter)++;
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 12.0;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		(self.allButtonTopConstraint.animator.constant) = -50;
		(self.todayButtonTopConstraint.animator.constant) = -50;
		(self.plannedButtonTopConstraint.animator.constant) = -50;
		(self.addProjectButtonTopConstraint.animator.constant) = -50;
	} completionHandler:^ {
		(self.animatingCounter)--;
	}];
}

- (void)showButtonsForEditingExistingProject
{
	NSString *backTitle = (self.titleForEditingProjectBackButton);
	GLAButton *backButton = [self addLeadingButtonWithTitle:backTitle action:@selector(exitCurrentProject:) identifier:@"back-editingProject"];
	(self.editingProjectBackButton) = backButton;
	
	NSString *workOnNowTitle = NSLocalizedString(@"Work on Now", @"Title for Work on Now button in an edited project");
	GLAButton *workOnNowButton = [self addTrailingButtonWithTitle:workOnNowTitle action:@selector(workOnCurrentProjectNow:) identifier:@"workOnNow-editingProject"];
	(self.editingProjectWorkOnNowButton) = workOnNowButton;
	
	NSLayoutConstraint *backLeadingConstraint = [self layoutConstraintWithIdentifier:@"leading" forChildView:backButton];
	
	NSLayoutConstraint *workOnNowTrailingConstraint = [self layoutConstraintWithIdentifier:@"trailing" forChildView:workOnNowButton];
	
	(self.animatingCounter)++;
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 12.0;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		// Back button
		(backButton.alphaValue) = 0.0;
		(backButton.animator.alphaValue) = 1.0;
		// Constraint
		(backLeadingConstraint.constant) = -250.0;
		(backLeadingConstraint.animator.constant) = 0.0;
		
		// Back button
		(workOnNowButton.alphaValue) = 0.0;
		(workOnNowButton.animator.alphaValue) = 1.0;
		// Constraint
		(workOnNowTrailingConstraint.constant) = 250.0;
		(workOnNowTrailingConstraint.animator.constant) = 0.0;
	} completionHandler:^ {
		(self.animatingCounter)--;
	}];
}

- (void)hideButtonsForEditingExistingProject
{
	NSButton *backButton = (self.editingProjectBackButton);
	NSButton *workOnNowButton = (self.editingProjectWorkOnNowButton);
	
	NSLayoutConstraint *backLeadingConstraint = [self layoutConstraintWithIdentifier:@"leading" forChildView:backButton];
	NSLayoutConstraint *workOnNowTrailingConstraint = [self layoutConstraintWithIdentifier:@"trailing" forChildView:workOnNowButton];
	
	(self.animatingCounter)++;
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 12.0;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		// Back button
		(backButton.animator.alphaValue) = 0.0;
		// Constraint
		(backLeadingConstraint.animator.constant) = -250.0;
		
		// Work on Now button
		(workOnNowButton.animator.alphaValue) = 0.0;
		// Constraint
		(workOnNowTrailingConstraint.animator.constant) = 250.0;
	} completionHandler:^ {
		(self.animatingCounter)--;
		
		[backButton removeFromSuperview];
		(self.editingProjectBackButton) = nil;
		
		[workOnNowButton removeFromSuperview];
		(self.editingProjectWorkOnNowButton) = nil;
	}];
}

- (void)showButtonsForAddingNewProject
{
	NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Title for cancel adding new project button");
	GLAButton *cancelButton = [self addLeadingButtonWithTitle:cancelTitle action:@selector(cancelAddingNewProject:) identifier:@"cancelAddNewProject"];
	(self.addingNewProjectCancelButton) = cancelButton;
	
	NSString *confirmCreateTitle = NSLocalizedString(@"Create New Project", @"Title for confirming creating new project button");
	GLAButton *confirmButton = [self addTrailingButtonWithTitle:confirmCreateTitle action:@selector(confirmAddingNewProject:) identifier:@"confirmAddNewProject"];
	(self.addingNewProjectConfirmButton) = confirmButton;
	
	NSLayoutConstraint *cancelLeadingConstraint = [self layoutConstraintWithIdentifier:@"leading" forChildView:cancelButton];
	NSLayoutConstraint *confirmTrailingConstraint = [self layoutConstraintWithIdentifier:@"trailing" forChildView:confirmButton];
	
	(self.animatingCounter)++;
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 12.0;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		// Cancel button
		(cancelButton.alphaValue) = 0.0;
		(cancelButton.animator.alphaValue) = 1.0;
		// Constraint
		(cancelLeadingConstraint.constant) = -250.0;
		(cancelLeadingConstraint.animator.constant) = 0.0;
		
		// Confirm button
		(confirmButton.alphaValue) = 0.0;
		(confirmButton.animator.alphaValue) = 1.0;
		// Constraint
		(confirmTrailingConstraint.constant) = 250.0;
		(confirmTrailingConstraint.animator.constant) = 0.0;
	} completionHandler:^ {
		(self.animatingCounter)--;
	}];
}

- (void)hideButtonsForAddingNewProject
{
	NSButton *cancelButton = (self.addingNewProjectCancelButton);
	NSButton *confirmButton = (self.addingNewProjectConfirmButton);
	
	NSLayoutConstraint *cancelLeadingConstraint = [self layoutConstraintWithIdentifier:@"leading" forChildView:cancelButton];
	NSLayoutConstraint *confirmTrailingConstraint = [self layoutConstraintWithIdentifier:@"trailing" forChildView:confirmButton];
	
	(self.animatingCounter)++;
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 12.0;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		// Cancel button
		(cancelButton.animator.alphaValue) = 0.0;
		// Constraint
		(cancelLeadingConstraint.animator.constant) = -250.0;
		
		// Confirm button
		(confirmButton.animator.alphaValue) = 0.0;
		// Constraint
		(confirmTrailingConstraint.animator.constant) = 250.0;
	} completionHandler:^ {
		(self.animatingCounter)--;
		
		[cancelButton removeFromSuperview];
		[confirmButton removeFromSuperview];
		
		(self.addingNewProjectCancelButton) = nil;
		(self.addingNewProjectConfirmButton) = nil;
	}];
}

- (void)showButtonsForCurrentCollection
{
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	GLACollection *collection = (self.currentCollection);
	
	NSString *collectionTitle = (collection.title);
	GLAButton *collectionButton = [self addCenterButtonWithTitle:collectionTitle action:nil identifier:@"collectionTitle"];
	(collectionButton.textHighlightColor) = [uiStyle colorForProjectItemColorIdentifier:(collection.colorIdentifier)];
	(self.collectionTitleButton) = collectionButton;
}

- (void)hideButtonsForCurrentCollection
{
	NSButton *collectionTitleButton = (self.collectionTitleButton);
	[collectionTitleButton removeFromSuperview];
	(self.collectionTitleButton) = nil;
}

#pragma mark Projects

- (IBAction)addNewProject:(id)sender
{
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainNavigationBarController:self performAddNewProject:sender];
	}
}

- (NSString *)titleForEditingProjectBackButton
{
	GLAMainNavigationSection currentSection = (self.currentSection);
	
	if (currentSection == GLAMainNavigationSectionAll) {
		return NSLocalizedString(@"Back to All Projects", @"Title for editing project back button to go back to all projects");
	}
	else if (currentSection == GLAMainNavigationSectionPlanned) {
		return NSLocalizedString(@"Back to Planned Projects", @"Title for editing project back button to go back to planned projects");
	}
	else {
		return NSLocalizedString(@"Back", @"Title for editing project back button to go back");
	}
}

- (void)setCurrentProject:(id)project isAddedNew:(BOOL)isAddedNew
{
	(self.currentProject) = project;
	(self.currentProjectIsAddedNew) = isAddedNew;
}

- (void)enterProject:(id)project
{
	[self setCurrentProject:project isAddedNew:NO];
	
	[self hideMainButtons];
	[self showButtonsForEditingExistingProject];
}

- (void)enterAddedProject:(id)project
{
	[self setCurrentProject:project isAddedNew:YES];
	
	[self hideMainButtons];
	[self showButtonsForAddingNewProject];
}

- (IBAction)exitCurrentProject:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	[self showMainButtons];
	
	if (self.currentProjectIsAddedNew) {
		[self hideButtonsForAddingNewProject];
	}
	else {
		[self hideButtonsForEditingExistingProject];
	}
	
	
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainNavigationBarController:self didExitProject:(self.currentProject)];
	}
	
	(self.currentProject) = nil;
}

- (IBAction)workOnCurrentProjectNow:(id)sender
{
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainNavigationBarController:self performWorkOnProjectNow:(self.currentProject)];
	}
}

- (IBAction)cancelAddingNewProject:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	[self exitCurrentProject:sender];
}

- (IBAction)confirmAddingNewProject:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	[self hideButtonsForAddingNewProject];
	[self showButtonsForEditingExistingProject];
	
	(self.currentProjectIsAddedNew) = NO;
}

#pragma mark Collections

- (void)enterProjectCollection:(GLACollection *)collection
{
	(self.currentCollection) = collection;
	
	[self hideMainButtons];
	[self hideButtonsForCurrentCollection];
	[self showButtonsForCurrentCollection];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	NSColor *collectionColor = [uiStyle colorForProjectItemColorIdentifier:(collection.colorIdentifier)];
	//[self animateBackgroundColorTo:collectionColor];
	GLANavigationBar *view = (self.navigationBar);
	[view highlightWithColor:collectionColor animate:YES];
}

- (void)exitCurrentCollection:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	(self.currentCollection) = nil;
}

#pragma mark -

- (void)setEnabled:(BOOL)enabled
{
	if (enabled != (self.private_enabled)) {
		(self.private_enabled) = enabled;
		
		(self.allButton.enabled) = enabled;
		(self.todayButton.enabled) = enabled;
		(self.plannedButton.enabled) = enabled;
		(self.addProjectButton.enabled) = enabled;
		(self.templateButton.enabled) = enabled;
	}
}

- (BOOL)isEnabled
{
	return (self.private_enabled);
}

- (GLAButton *)addButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAButton *button = [GLAButton new];
	(button.cell) = [(self.templateButton.cell) copy];
	(button.identifier) = identifier;
	(button.title) = title;
	(button.target) = self;
	(button.action) = action;
	(button.translatesAutoresizingMaskIntoConstraints) = NO;
	
	GLANavigationBar *navigationBar = (self.navigationBar);
	[navigationBar addSubview:button];
	
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeTop withChildView:button identifier:@"top"];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeBottom withChildView:button identifier:@"bottom"];
	
	return button;
}

- (GLAButton *)addLeadingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAButton *button = [self addButtonWithTitle:title action:action identifier:identifier];
	
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeLeading withChildView:button identifier:@"leading"];
	
	return button;
}

- (GLAButton *)addTrailingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAButton *button = [self addButtonWithTitle:title action:action identifier:identifier];
	
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeTrailing withChildView:button identifier:@"trailing"];
	
	return button;
}

- (GLAButton *)addCenterButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAButton *button = [self addButtonWithTitle:title action:action identifier:identifier];
	
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeCenterX withChildView:button identifier:@"centerX"];
	
	return button;
}

- (void)viewUpdateConstraints:(GLANavigationBar *)view
{
	
}

@end
