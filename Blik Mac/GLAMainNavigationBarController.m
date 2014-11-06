//
//  GLAMainNavigationBarController.m
//  Blik
//
//  Created by Patrick Smith on 10/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAMainNavigationBarController.h"
@import QuartzCore;
#import "GLAButton.h"
#import "GLAUIStyle.h"
#import "GLAProjectManager.h"
#import "GLAEditCollectionDetailsPopover.h"


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

- (GLACollection *)currentCollection;

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
	else if (previousSection.isEditProject) {
		[self hideButtonsForEditingExistingProject];
	}
	else if (previousSection.isEditCollection) {
		[self hideButtonsForCurrentCollection];
	}
	else if (previousSection.isAddNewProject) {
		[self hideButtonsForAddingNewProject];
	}
	else if (previousSection.isAddNewCollection) {
		[self hideButtonsForAddingNewCollection];
	}
	
	if ((newSection.isAllProjects) || (newSection.isPlannedProjects) || (newSection.isNow)) {
		[self showMainButtons];
	}
	else if (newSection.isEditProject) {
		[self showButtonsForEditingExistingProject];
	}
	else if (newSection.isEditCollection) {
		[self showButtonsForCurrentCollection];
	}
	else if (newSection.isAddNewProject) {
		[self showButtonsForAddingNewProject];
	}
	else if (newSection.isAddNewCollection) {
		[self showButtonsForAddingNewCollection];
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
		[delegate mainNavigationBarController:self handleChangeCurrentSectionTo:newSection];
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
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	[projectManager loadNowProject];
	GLAProject *nowProject = (projectManager.nowProject);
	
	[self performChangeCurrentSectionTo:[GLAMainContentEditProjectSection nowProjectSectionWithProject:nowProject]];
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

#pragma mark Accessing State

- (GLAProject *)currentProject
{
	GLAMainContentSection *currentSection = (self.currentSection);
	NSAssert([currentSection isKindOfClass:[GLAMainContentEditProjectSection class]], @"Current section (%@) must be a GLAMainContentEditProjectSection when calling -currentProject", currentSection);
	
	GLAMainContentEditProjectSection *editProjectSection = (GLAMainContentEditProjectSection *)currentSection;
	return (editProjectSection.project);
}

- (GLACollection *)currentCollection
{
	GLAMainContentSection *currentSection = (self.currentSection);
	NSAssert([currentSection isKindOfClass:[GLAMainContentEditCollectionSection class]], @"Current section (%@) must be a GLAMainContentEditCollectedSection when calling -currentCollection", currentSection);
	
	GLAMainContentEditCollectionSection *editCollectionSection = (GLAMainContentEditCollectionSection *)currentSection;
	return (editCollectionSection.collection);
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
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	GLAProject *nowProject = (pm.nowProject);
	GLAProject *currentProject = (self.currentProject);
	
	NSString *backTitle = (self.titleForEditingProjectBackButton);
	GLAButton *backButton = [self addLeadingButtonWithTitle:backTitle action:@selector(exitEditedProject:) identifier:@"back-editingProject"];
	(self.editingProjectBackButton) = backButton;
	
	NSString *workOnNowTitle = nil;
	if ((nowProject != nil) && [(nowProject.UUID) isEqual:(currentProject.UUID)]) {
		workOnNowTitle = NSLocalizedString(@"Already Working on Now", @"Title for Work on Now button in an edited project that is already the now project");
	}
	else {
		workOnNowTitle = NSLocalizedString(@"Work on Now", @"Title for Work on Now button in an edited project");
	}
	
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
	
	NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Title for cancel creating new project button");
	(self.addingNewProjectCancelButton) = [buttonGroup makeLeadingButtonWithTitle:cancelTitle action:@selector(cancelAddingNewProject:) identifier:@"cancelAddNewProject"];
	
	NSString *title = NSLocalizedString(@"New Project", @"Title label for creating new project");
	GLAButton *titleButton = [buttonGroup makeCenterButtonWithTitle:title action:nil identifier:@"confirmAddNewProject"];
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
	GLACollection *collection = (self.currentCollection);
	
	// Back
	NSString *backTitle = NSLocalizedString(@"Back", @"Title for collection back button to go back");
	(self.collectionBackButton) = [buttonGroup makeLeadingButtonWithTitle:backTitle action:@selector(exitEditedCollection:) identifier:@"back-collection"];
	
	// Collection title
	NSString *collectionTitle = (collection.name);
	GLAButton *titleButton = [buttonGroup makeCenterButtonWithTitle:collectionTitle action:@selector(editCollectionDetails:) identifier:@"collectionTitle"];
	(titleButton.hasSecondaryStyle) = NO;
	(titleButton.textHighlightColor) = [uiStyle colorForCollectionColor:(collection.color)];
	(self.collectionTitleButton) = titleButton;
	

	(buttonGroup.centerButtonInDuration) = 2.0 / 12.0;
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

- (void)showButtonsForAddingNewCollection
{
	GLAMainNavigationButtonGroup *buttonGroup = [GLAMainNavigationButtonGroup buttonGroupWithBarController:self];
	
	NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Title for cancel creating new collection button");
	[buttonGroup makeLeadingButtonWithTitle:cancelTitle action:@selector(cancelAddingNewProject:) identifier:@"cancelAddNewProject"];
	
	NSString *title = NSLocalizedString(@"New Collection", @"Title label for creating new collection");
	GLAButton *titleButton = [buttonGroup makeCenterButtonWithTitle:title action:nil identifier:@"confirmAddNewCollection"];
	(titleButton.hasSecondaryStyle) = NO;
	
	(buttonGroup.leadingButtonInDuration) = 3.0 / 12.0;
	(buttonGroup.centerButtonInDuration) = 2.7 / 12.0;
	[buttonGroup animateButtonsIn];
	
	(self.addNewCollectionButtonGroup) = buttonGroup;
}

- (void)hideButtonsForAddingNewCollection
{
	[(self.addNewCollectionButtonGroup) animateButtonsOutWithCompletionHandler:^{
		(self.addNewCollectionButtonGroup) = nil;
	}];
}

#pragma mark Projects

- (IBAction)addNewProject:(id)sender
{
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainNavigationBarController:self handleAddNewProject:sender];
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
		[delegate mainNavigationBarControllerHandleExitEditedProject:self];
	}
}

- (IBAction)workOnCurrentProjectNow:(id)sender
{
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		GLAMainContentSection *currentSection = (self.currentSection);
		NSAssert([currentSection isKindOfClass:[GLAMainContentEditProjectSection class]], @"Current section (%@) must be a GLAMainContentEditProjectSection when calling -workOnCurrentProjectNow: action", currentSection);
		
		GLAMainContentEditProjectSection *editProjectSection = (GLAMainContentEditProjectSection *)currentSection;
		[delegate mainNavigationBarController:self handleWorkNowOnProject:(editProjectSection.project)];
	}
}

- (IBAction)cancelAddingNewProject:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	[self exitEditedProject:sender];
}

#pragma mark Collections

- (IBAction)editCollectionDetails:(GLAButton *)sender
{
	if (self.isAnimating) {
		return;
	}
	
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		GLACollection *collection = (self.currentCollection);
		[delegate mainNavigationBarController:self handleEditDetailsForCollection:collection fromButton:sender];
	}
}

- (IBAction)exitEditedCollection:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainNavigationBarControllerHandleExitEditedCollection:self];
	}
}

#pragma mark Creating Buttons

- (GLAButton *)addButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAButton *button = [GLAButton new];
	(button.cell) = [(self.templateButton.cell) copy];
	(button.identifier) = identifier;
	(button.title) = title;
	if (action) {
		(button.target) = self;
		(button.action) = action;
	}
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

#pragma mark -

#if 0

- (GLAEditCollectionDetailsPopover *)editCollectionPopover
{
	return [GLAEditCollectionDetailsPopover sharedEditCollectionDetailsPopover];
}

- (void)editCollectionDetailsPopoverChosenNameDidChangeNotification:(NSNotification *)note
{
	GLAEditCollectionDetailsPopover *popover = (note.object);
	NSString *name = (popover.chosenName);
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	[projectManager renameCollection:(self.currentCollection) inProject:(self.project) toString:name];
}

- (void)editCollectionDetailsPopoverChosenColorDidChangeNotification:(NSNotification *)note
{
	GLAEditCollectionDetailsPopover *popover = (note.object);
	GLACollectionColor *color = (popover.chosenCollectionColor);
	[self changeColor:color forCollection:(self.collectionWithDetailsBeingEdited)];
}

- (void)editCollectionDetailsPopupDidCloseNotification:(NSNotification *)note
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:nil object:(self.editCollectionPopover)];
	
	(self.collectionWithDetailsBeingEdited) = nil;
}

- (void)editDetailsOfCollection:(GLACollection *)collection fromNavigationButton:(GLAButton *)button
{
	(self.collectionWithDetailsBeingEdited) = collection;
	
	GLAEditCollectionDetailsPopover *popover = (self.editCollectionPopover);
	
	if (popover.isShown) {
		[popover close];
		//(self.collectionWithDetailsBeingEdited) = nil;
	}
	else {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(editCollectionDetailsPopoverChosenNameDidChangeNotification:) name:GLAEditCollectionDetailsPopoverChosenNameDidChangeNotification object:popover];
		[nc addObserver:self selector:@selector(editCollectionDetailsPopoverChosenColorDidChangeNotification:) name:GLAEditCollectionDetailsPopoverChosenColorDidChangeNotification object:popover];
		[nc addObserver:self selector:@selector(editCollectionDetailsPopupDidCloseNotification:) name:NSPopoverDidCloseNotification object:popover];
		
		[popover setUpWithCollection:collection];
		
		NSTableView *tableView = (self.tableView);
		NSRect rowRect = [tableView rectOfRow:collectionRow];
		// Show underneath.
		[popover showRelativeToRect:rowRect ofView:tableView preferredEdge:NSMaxXEdge];
	}
}

#endif

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
