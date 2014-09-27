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


@interface GLAMainNavigationButtonGroup : NSObject

+ (instancetype)buttonGroupWithBarController:(GLAMainNavigationBarController *)barController;

@property(weak, nonatomic) GLAMainNavigationBarController *barController;

- (GLAButton *)makeLeadingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier;
- (GLAButton *)makeCenterButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier;
- (GLAButton *)makeTrailingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier;

@property(nonatomic) GLAButton *leadingButton;
@property(nonatomic) GLAButton *centerButton;
@property(nonatomic) GLAButton *trailingButton;

@property(nonatomic) NSTimeInterval leadingButtonInDuration;
@property(nonatomic) NSTimeInterval leadingButtonOutDuration;
@property(nonatomic) NSTimeInterval centerButtonInDuration;
@property(nonatomic) NSTimeInterval centerButtonOutDuration;
@property(nonatomic) NSTimeInterval trailingButtonInDuration;
@property(nonatomic) NSTimeInterval trailingButtonOutDuration;

- (void)animateButtonsIn;
- (void)animateButtonsOutWithCompletionHandler:(dispatch_block_t)completionHandler;

- (void)animateInButtons:(NSArray *)buttons duration:(NSTimeInterval)duration;

@end


@interface GLAMainNavigationBarController ()

@property(readwrite, nonatomic) GLAMainContentSection *currentSection;

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
		[self updateSelectedSectionUI];
		(self.private_enabled) = YES;
    }
    return self;
}

- (void)loadView
{
	[super loadView];
	
	GLANavigationBar *navigationBar = (self.navigationBar);
	(navigationBar.delegate) = self;
	(navigationBar.showBottomEdgeLine) = YES;
	
	(self.templateButton.canDrawSubviewsIntoLayer) = YES;
	[(self.templateButton) removeFromSuperview];
}

- (BOOL)isAnimating
{
	return (self.animatingCounter) > 0;
}

- (void)updateSelectedSectionUI
{
	GLAMainContentSection *currentSection = (self.currentSection);
	(self.allButton.state) = (currentSection.isAllProjects) ? NSOnState : NSOffState;
	(self.todayButton.state) = (currentSection.isNow) ? NSOnState : NSOffState;
	(self.plannedButton.state) = (currentSection.isPlannedProjects) ? NSOnState : NSOffState;
}

- (void)didChangeCurrentSectionFrom:(GLAMainContentSection *)previousSection to:(GLAMainContentSection *)newSection
{
	if ((previousSection.isAllProjects) || (previousSection.isPlannedProjects) || (previousSection.isNow)) {
		[self hideMainButtons];
	}
	else if (previousSection.isAddNewProject) {
		[self hideButtonsForAddingNewProject];
	}
	else if (previousSection.isEditProject) {
		[self hideButtonsForEditingExistingProject];
	}
	else if (previousSection.isEditCollection) {
		[self hideButtonsForCurrentCollection];
	}
	
	if ((newSection.isAllProjects) || (newSection.isPlannedProjects) || (newSection.isNow)) {
		[self showMainButtons];
	}
	else if (newSection.isAddNewProject) {
		[self showButtonsForAddingNewProject];
	}
	else if (newSection.isEditProject) {
		[self showButtonsForEditingExistingProject];
	}
	else if (newSection.isEditCollection) {
		[self showButtonsForCurrentCollection];
	}
	
	[self updateSelectedSectionUI];
}

- (void)changeCurrentSectionTo:(GLAMainContentSection *)newSection
{
	GLAMainContentSection *previousSection = (self.currentSection);
	if ([previousSection isEqual:newSection]) {
		return;
	}
	
	(self.currentSection) = newSection;
	
	[self didChangeCurrentSectionFrom:previousSection to:newSection];
}

- (void)performChangeCurrentSectionTo:(GLAMainContentSection *)newSection
{
	/*if (self.isAnimating) {
		return;
	}*/
	
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainNavigationBarController:self performChangeCurrentSectionTo:newSection];
	}
	
	[self updateSelectedSectionUI];
	
	//[self changeCurrentSectionTo:newSection];
}

- (IBAction)goToAll:(id)sender
{
	[self performChangeCurrentSectionTo:[GLAMainContentSection allProjectsSection]];
}

- (IBAction)goToToday:(id)sender
{
	[self performChangeCurrentSectionTo:[GLAMainContentSection nowSection]];
}

- (IBAction)goToPlanned:(id)sender
{
	[self performChangeCurrentSectionTo:[GLAMainContentSection plannedProjectsSection]];
}

- (NSArray *)allVisibleButtons
{
	NSArray *subviews = (self.view.subviews);
	return [subviews filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSView *view, NSDictionary *bindings) {
		return [view isKindOfClass:[NSButton class]] && !(view.isHidden);
	}]];
}

- (void)setEnabled:(BOOL)enabled
{
	if (enabled != (self.private_enabled)) {
		(self.private_enabled) = enabled;
		
		NSArray *buttons = (self.allVisibleButtons);
		[buttons setValue:@(enabled) forKey:@"enabled"];
	}
}

- (BOOL)isEnabled
{
	return (self.private_enabled);
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

- (void)hideLeadingButton:(NSButton *)leadingButton trailingButton:(NSButton *)trailingButton centerButton:(NSButton *)centerButton completionHandler:(dispatch_block_t)completionHandler
{
	(self.animatingCounter)++;
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 12.0;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		if (leadingButton) {
			(leadingButton.animator.alphaValue) = 0.0;
			
			NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithIdentifier:@"leading" forChildView:leadingButton];
			(leadingConstraint.animator.constant) = -250.0;
		}
		
		if (trailingButton) {
			(trailingButton.animator.alphaValue) = 0.0;
			
			NSLayoutConstraint *trailingConstraint = [self layoutConstraintWithIdentifier:@"trailing" forChildView:trailingButton];
			(trailingConstraint.animator.constant) = 250.0;
		}
		
		if (centerButton) {
			(centerButton.animator.alphaValue) = 0.0;
			
			NSLayoutConstraint *topConstraint = [self layoutConstraintWithIdentifier:@"top" forChildView:centerButton];
			(topConstraint.animator.constant) = 50.0;
		}
	} completionHandler:^ {
		(self.animatingCounter)--;
		
		if (leadingButton) {
			[leadingButton removeFromSuperview];
		}
		if (trailingButton) {
			[trailingButton removeFromSuperview];
		}
		if (centerButton) {
			[centerButton removeFromSuperview];
		}
		
		completionHandler();
	}];
}

- (void)showButtonsForEditingExistingProject
{
	NSString *backTitle = (self.titleForEditingProjectBackButton);
	GLAButton *backButton = [self addLeadingButtonWithTitle:backTitle action:@selector(exitEditedProject:) identifier:@"back-editingProject"];
	(self.editingProjectBackButton) = backButton;
	
	NSString *workOnNowTitle = NSLocalizedString(@"Work on Now", @"Title for Work on Now button in an edited project");
	GLAButton *workOnNowButton = [self addTrailingButtonWithTitle:workOnNowTitle action:@selector(workOnCurrentProjectNow:) identifier:@"workOnNow-editingProject"];
	(workOnNowButton.hasSecondaryStyle) = NO;
	(workOnNowButton.hasPrimaryStyle) = YES;
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
		
		// Work on now button
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
	[self hideLeadingButton:(self.editingProjectBackButton) trailingButton:(self.editingProjectWorkOnNowButton) centerButton:nil completionHandler:^{
		(self.editingProjectBackButton) = nil;
		(self.editingProjectWorkOnNowButton) = nil;
	}];
}

- (void)showButtonsForAddingNewProject
{
	GLAMainNavigationButtonGroup *buttonGroup = [GLAMainNavigationButtonGroup buttonGroupWithBarController:self];
	
	NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Title for cancel adding new project button");
	(self.addingNewProjectCancelButton) = [buttonGroup makeLeadingButtonWithTitle:cancelTitle action:@selector(cancelAddingNewProject:) identifier:@"cancelAddNewProject"];
	
	NSString *title = NSLocalizedString(@"New Project", @"Title label for creating new project");
	GLAButton *titleButton = [buttonGroup makeCenterButtonWithTitle:title action:@selector(confirmAddingNewProject:) identifier:@"confirmAddNewProject"];
	(titleButton.hasSecondaryStyle) = NO;
	
	(buttonGroup.leadingButtonInDuration) = 3.0 / 12.0;
	(buttonGroup.centerButtonInDuration) = 2.7 / 12.0;
	[buttonGroup animateButtonsIn];
	
	(self.addingNewProjectButtonGroup) = buttonGroup;
}

- (void)hideButtonsForAddingNewProject
{
	[(self.addingNewProjectButtonGroup) animateButtonsOutWithCompletionHandler:^{
		(self.addingNewProjectCancelButton) = nil;
		(self.addingNewProjectButtonGroup) = nil;
	}];
}

- (void)showButtonsForCurrentCollection
{
	GLAMainNavigationButtonGroup *buttonGroup = [GLAMainNavigationButtonGroup buttonGroupWithBarController:self];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	GLAMainContentSection *currentSection = (self.currentSection);
	NSAssert([currentSection isKindOfClass:[GLAMainContentEditCollectionSection class]], @"Current section (%@) must be a GLAMainContentEditCollectedSection when calling -showButtonsForCurrentCollection", currentSection);
	
	GLAMainContentEditCollectionSection *editCollectionSection = (GLAMainContentEditCollectionSection *)currentSection;
	GLACollection *collection = (editCollectionSection.collection);
	
	// Back
	NSString *backTitle = NSLocalizedString(@"Back", @"Title for collection back button to go back");
	(self.collectionBackButton) = [buttonGroup makeLeadingButtonWithTitle:backTitle action:@selector(exitEditedCollection:) identifier:@"back-collection"];
	
	// Collection title
	NSString *collectionTitle = (collection.title);
	GLAButton *titleButton = [buttonGroup makeCenterButtonWithTitle:collectionTitle action:nil identifier:@"collectionTitle"];
	(titleButton.textHighlightColor) = [uiStyle colorForCollectionColor:(collection.color)];
	(self.collectionTitleButton) = titleButton;
	

	(buttonGroup.centerButtonInDuration) = 2.3 / 12.0;
	(buttonGroup.leadingButtonInDuration) = 2.4 / 12.0;
	[buttonGroup animateButtonsIn];
	
	(self.collectionButtonGroup) = buttonGroup;
	/*
	 GLAMainNavigationButtonGroup *buttonGroup = ...
	 [buttonGroup animateInButtonsInWithIDs:@[@"collectionTitle"] duration:(2.1 / 12.0)];
	*/
	
	NSColor *collectionColor = [uiStyle colorForCollectionColor:(collection.color)];
	//[self animateBackgroundColorTo:collectionColor];
	[(self.navigationBar) highlightWithColor:collectionColor animate:YES];
}

- (void)hideButtonsForCurrentCollection
{
	[(self.collectionButtonGroup) animateButtonsOutWithCompletionHandler:^{
		(self.collectionBackButton) = nil;
		(self.collectionTitleButton) = nil;
		(self.collectionButtonGroup) = nil;
	}];
	
	[(self.navigationBar) highlightWithColor:nil animate:YES];
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
	GLAMainContentSection *currentSection = (self.currentSection);
	
	if (currentSection.isAllProjects) {
		return NSLocalizedString(@"Back to All Projects", @"Title for editing project back button to all projects");
	}
	else if (currentSection.isPlannedProjects) {
		return NSLocalizedString(@"Back to Planned Projects", @"Title for editing project back button to planned projects");
	}
	else {
		return NSLocalizedString(@"Back", @"Title for editing project back button");
	}
}

- (IBAction)exitEditedProject:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainNavigationBarControllerDidExitEditedProject:self];
	}
}

- (IBAction)workOnCurrentProjectNow:(id)sender
{
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		GLAMainContentSection *currentSection = (self.currentSection);
		NSAssert([currentSection isKindOfClass:[GLAMainContentEditProjectSection class]], @"Current section (%@) must be a GLAMainContentEditProjectSection when calling -workOnCurrentProjectNow: action", currentSection);
		
		GLAMainContentEditProjectSection *editProjectSection = (GLAMainContentEditProjectSection *)currentSection;
		[delegate mainNavigationBarController:self performWorkOnProjectNow:(editProjectSection.project)];
	}
}

- (IBAction)cancelAddingNewProject:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	[self exitEditedProject:sender];
}

- (IBAction)confirmAddingNewProject:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainNavigationBarController:self performConfirmNewProject:sender];
	}
	
	//TODO remove these:
	
	[self hideButtonsForAddingNewProject];
	[self showButtonsForEditingExistingProject];
}

#pragma mark Collections

- (void)exitEditedCollection:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainNavigationBarControllerDidExitEditedCollection:self];
	}
}

#pragma mark Creating Buttons

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
	//[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeBottom withChildView:button identifier:@"bottom"];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeHeight withChildView:button identifier:@"height"];
	
	return button;
}

- (GLAButton *)addLeadingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAButton *button = [self addButtonWithTitle:title action:action identifier:identifier];
	
	(button.hasSecondaryStyle) = YES;
	
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeLeading withChildView:button identifier:@"leading"];
	
	return button;
}

- (GLAButton *)addTrailingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAButton *button = [self addButtonWithTitle:title action:action identifier:identifier];
	
	(button.hasSecondaryStyle) = YES;
	
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeTrailing withChildView:button identifier:@"trailing"];
	
	return button;
}

- (GLAButton *)addCenterButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	GLAButton *button = [self addButtonWithTitle:title action:action identifier:identifier];
	
	(button.font) = (uiStyle.labelFont);
	
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeCenterX withChildView:button identifier:@"centerX"];
	
	return button;
}

- (void)viewUpdateConstraints:(GLANavigationBar *)view
{
	
}

@end


@implementation GLAMainNavigationButtonGroup

+ (instancetype)buttonGroupWithBarController:(GLAMainNavigationBarController *)barController
{
	GLAMainNavigationButtonGroup *buttonGroup = [GLAMainNavigationButtonGroup new];
	(buttonGroup.barController) = barController;
	
	return buttonGroup;
}

- (GLAButton *)makeLeadingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAMainNavigationBarController *barController = (self.barController);
	
	GLAButton *button = [barController addLeadingButtonWithTitle:title action:action identifier:identifier];
	(self.leadingButton) = button;
	
	return button;
}

- (GLAButton *)makeCenterButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAMainNavigationBarController *barController = (self.barController);
	
	GLAButton *button = [barController addCenterButtonWithTitle:title action:action identifier:identifier];
	(self.centerButton) = button;
	
	return button;
}

- (GLAButton *)makeTrailingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAMainNavigationBarController *barController = (self.barController);
	
	GLAButton *button = [barController addTrailingButtonWithTitle:title action:action identifier:identifier];
	(self.trailingButton) = button;
	
	return button;
}

- (void)willBeginAnimating
{
	GLAMainNavigationBarController *barController = (self.barController);
	(barController.animatingCounter)++;
}

- (void)didEndAnimating
{
	GLAMainNavigationBarController *barController = (self.barController);
	(barController.animatingCounter)--;
}

- (void)animateInButton:(GLAButton *)button duration:(NSTimeInterval)duration constraintIdentifier:(NSString *)constraintIdentifier constraintStartValue:(CGFloat)constraintStartValue
{
	GLAMainNavigationBarController *barController = (self.barController);
	
	[self willBeginAnimating];
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = duration;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		NSLayoutConstraint *constraint = [barController layoutConstraintWithIdentifier:constraintIdentifier forChildView:button];
		
		(button.alphaValue) = 0.0;
		(button.animator.alphaValue) = 1.0;
		
		(constraint.constant) = constraintStartValue;
		(constraint.animator.constant) = 0.0;
	} completionHandler:^ {
		[self didEndAnimating];
	}];
}

- (void)animateOutButton:(GLAButton *)button duration:(NSTimeInterval)duration constraintIdentifier:(NSString *)constraintIdentifier constraintEndValue:(CGFloat)constraintEndValue completionHandler:(dispatch_block_t)completionHandler
{
	GLAMainNavigationBarController *barController = (self.barController);
	
	[self willBeginAnimating];
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = duration;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		NSLayoutConstraint *constraint = [barController layoutConstraintWithIdentifier:constraintIdentifier forChildView:button];
		
		(button.animator.alphaValue) = 0.0;
		
		(constraint.animator.constant) = constraintEndValue;
	} completionHandler:^ {
		[button removeFromSuperview];
		
		completionHandler();
		
		[self didEndAnimating];
	}];
}

- (void)animateButtonsIn
{
	GLAButton *leadingButton = (self.leadingButton);
	GLAButton *centerButton = (self.centerButton);
	GLAButton *trailingButton = (self.trailingButton);
	
	if (leadingButton) {
		[self animateInButton:leadingButton duration:(self.leadingButtonInDuration) constraintIdentifier:@"leading" constraintStartValue:-250.0];
	}
	
	if (centerButton) {
		[self animateInButton:centerButton duration:(self.centerButtonInDuration) constraintIdentifier:@"top" constraintStartValue:50.0];
	}
	
	if (trailingButton) {
		[self animateInButton:trailingButton duration:(self.trailingButtonInDuration) constraintIdentifier:@"trailing" constraintStartValue:250.0];
	}
}

- (void)animateButtonsOutWithCompletionHandler:(dispatch_block_t)completionHandler
{
	GLAButton *leadingButton = (self.leadingButton);
	GLAButton *centerButton = (self.centerButton);
	GLAButton *trailingButton = (self.trailingButton);
	__block NSUInteger buttonsAnimating = 0;
	
	dispatch_block_t individualButtonCompletionHandler = ^{
		buttonsAnimating--;
		if (buttonsAnimating == 0) {
			completionHandler();
		}
	};
	
	if (leadingButton) {
		buttonsAnimating++;
		[self animateOutButton:leadingButton duration:(self.leadingButtonInDuration) constraintIdentifier:@"leading" constraintEndValue:-250.0 completionHandler:individualButtonCompletionHandler];
	}
	
	if (centerButton) {
		buttonsAnimating++;
		[self animateOutButton:centerButton duration:(self.centerButtonInDuration) constraintIdentifier:@"top" constraintEndValue:50.0 completionHandler:individualButtonCompletionHandler];
	}
	
	if (trailingButton) {
		buttonsAnimating++;
		[self animateOutButton:trailingButton duration:(self.trailingButtonInDuration) constraintIdentifier:@"trailing" constraintEndValue:250.0 completionHandler:individualButtonCompletionHandler];
	}
}
@end
