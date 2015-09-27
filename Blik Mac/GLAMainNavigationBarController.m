//
//  GLAMainNavigationBarController.m
//  Blik
//
//  Created by Patrick Smith on 10/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAMainNavigationBarController.h"
@import QuartzCore;
#import "NSViewController+PGWSConstraintConvenience.h"
#import "GLAButton.h"
#import "GLAUIStyle.h"
#import "GLAProjectManager.h"
#import "GLAEditCollectionDetailsPopover.h"

#import "GLAEnabledFeatures.h"


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

@end


@interface GLAMainNavigationBarController ()

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

- (void)dealloc
{
	[self stopSectionNavigatorObserving];
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

#pragma mark Section Navigator Notifications

- (void)sectionNavigatorDidChangeCurrentSection:(NSNotification *)note
{
#if DEBUG
	NSLog(@"sectionNavigatorDidChangeCurrentSection");
#endif
	GLAMainSectionNavigator *sectionNavigator = (self.sectionNavigator);
	GLAMainSection *newSection = (sectionNavigator.currentSection);
	GLAMainSection *previousSection = nil;
	
	NSDictionary *userInfo = (note.userInfo);
	if (userInfo) {
		previousSection = userInfo[GLAMainSectionNavigatorNotificationUserInfoPreviousSection];
	}
	
	[self didChangeCurrentSectionFrom:previousSection to:newSection];
}

#pragma mark -

- (BOOL)isAnimating
{
	return (self.animatingCounter) > 0;
}

- (void)updateSelectedSectionUI
{
	GLAMainSection *currentSection = (self.currentSection);
	(self.allButton.state) = (currentSection.isAllProjects) ? NSOnState : NSOffState;
	(self.todayButton.state) = (currentSection.isNow) ? NSOnState : NSOffState;
	(self.plannedButton.state) = (currentSection.isPlannedProjects) ? NSOnState : NSOffState;
}

- (void)didChangeCurrentSectionFrom:(GLAMainSection *)previousSection to:(GLAMainSection *)newSection
{
	if (previousSection) {
		if ((previousSection.isAllProjects) || (previousSection.isPlannedProjects) || (previousSection.isNow)) {
			[self hideMainButtons];
		}
		else if (previousSection.isEditProject) {
			[self hideButtonsForEditingExistingProject];
		}
		else if (previousSection.isEditProjectPrimaryFolders) {
			[self hideButtonForEditingProjectPrimaryFolders];
		}
		else if (previousSection.isEditCollection) {
			if (newSection.isEditCollection) {
				[self updateUIForCurrentCollection];
				return;
			}
			
			[self hideButtonsForCurrentCollection];
		}
		else if (previousSection.isAddNewProject) {
			[self hideButtonsForAddingNewProject];
		}
		else if (previousSection.isAddNewCollection) {
			if (newSection.isAddNewCollection) {
				return;
			}
			
			[self hideButtonsForAddingNewCollection];
		}
	}
	
	if ((newSection.isAllProjects) || (newSection.isPlannedProjects) || (newSection.isNow)) {
		[self showMainButtons];
	}
	else if (newSection.isEditProject) {
		[self showButtonsForEditingExistingProject];
	}
	else if (newSection.isEditProjectPrimaryFolders) {
		[self showButtonForEditingProjectPrimaryFolders];
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

- (IBAction)goToAll:(id)sender
{
	[(self.sectionNavigator) goToAllProjects];
	
	[self updateSelectedSectionUI];
}

- (IBAction)goToNowProject:(id)sender
{
	[(self.sectionNavigator) goToNowProject];
	
	[self updateSelectedSectionUI];
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
	GLAMainSection *currentSection = (self.currentSection);
	NSAssert([currentSection isKindOfClass:[GLAEditProjectSection class]], @"Current section (%@) must be a GLAMainContentEditProjectSection when calling -currentProject", currentSection);
	
	GLAEditProjectSection *editProjectSection = (GLAEditProjectSection *)currentSection;
	return (editProjectSection.project);
}

- (GLACollection *)currentCollection
{
	GLAMainSection *currentSection = (self.currentSection);
	NSAssert([currentSection isKindOfClass:[GLAEditCollectionSection class]], @"Current section (%@) must be a GLAMainContentEditCollectedSection when calling -currentCollection", currentSection);
	
	GLAEditCollectionSection *editCollectionSection = (GLAEditCollectionSection *)currentSection;
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
	GLANavigationButtonGroup *buttonGroup = [GLANavigationButtonGroup buttonGroupWithViewController:self templateButton:(self.templateButton)];
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	GLAProject *nowProject = (pm.nowProject);
	GLAProject *currentProject = (self.currentProject);
	
	NSString *backTitle = (self.titleForEditingProjectBackButton);
	[buttonGroup makeLeadingButtonWithTitle:backTitle action:@selector(exitEditedProject:) identifier:@"back-editingProject"];
	
	NSString *workOnNowTitle = nil;
	if ((nowProject != nil) && [(nowProject.UUID) isEqual:(currentProject.UUID)]) {
		workOnNowTitle = NSLocalizedString(@"Already Working on Now", @"Title for Work on Now button in an edited project that is already the now project");
	}
	else {
		workOnNowTitle = NSLocalizedString(@"Work on Now", @"Title for Work on Now button in an edited project");
	}
	
	GLAButton *workOnNowButton = [buttonGroup makeTrailingButtonWithTitle:workOnNowTitle action:@selector(workOnCurrentProjectNow:) identifier:@"workOnNow-editingProject"];
	(workOnNowButton.hasSecondaryStyle) = NO;
	(workOnNowButton.hasPrimaryStyle) = YES;
	
	
	(buttonGroup.leadingButtonInDuration) = 4.0 / 12.0;
	(buttonGroup.trailingButtonInDuration) = 4.0 / 12.0;
	[buttonGroup animateButtonsIn];
	
	(self.viewProjectButtonGroup) = buttonGroup;
}

- (void)hideButtonsForEditingExistingProject
{
	GLANavigationButtonGroup *buttonGroup = (self.viewProjectButtonGroup);
	[buttonGroup animateButtonsOutWithCompletionHandler:^{
	}];
}

- (void)showButtonForEditingProjectPrimaryFolders
{
#if 0
	NSString *backTitle = (self.titleForEditingProjectPrimaryFoldersBackButton);
	GLAButton *backButton = [self addLeadingButtonWithTitle:backTitle action:@selector(exitEditPrimaryFoldersOfProject:) identifier:@"back-editingProjectPrimaryFolders"];
	(self.editingProjectPrimaryFoldersBackButton) = backButton;
	
	NSLayoutConstraint *backLeadingConstraint = [self layoutConstraintWithIdentifier:@"leading" forChildView:backButton];
	
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
	} completionHandler:^ {
		(self.animatingCounter)--;
	}];
#endif

	GLAEditProjectPrimaryFoldersSection *editProjectPrimaryFoldersSection = (id)(self.currentSection);
	GLAProject *project = (editProjectPrimaryFoldersSection.project);
	
	
	GLAMainNavigationButtonGroup *buttonGroup = [GLAMainNavigationButtonGroup buttonGroupWithBarController:self];
	
	NSString *backTitle = (self.titleForEditingProjectPrimaryFoldersBackButton);
	[buttonGroup makeLeadingButtonWithTitle:backTitle action:@selector(exitEditPrimaryFoldersOfProject:) identifier:@"back-editingProjectPrimaryFolders"];
	
	NSString *title = [NSString localizedStringWithFormat:NSLocalizedString(@"Project ‘%@’", @"String format for projec title when editing master folders."), (project.name)];
	GLAButton *titleButton = [buttonGroup makeCenterButtonWithTitle:title action:nil identifier:@"projectTitle-editingProjectPrimaryFolders"];
	(titleButton.hasSecondaryStyle) = NO;
	
	(buttonGroup.leadingButtonInDuration) = 3.0 / 12.0;
	(buttonGroup.centerButtonInDuration) = 2.7 / 12.0;
	[buttonGroup animateButtonsIn];

	(self.editingProjectPrimaryFoldersButtonGroup) = buttonGroup;
}

- (void)hideButtonForEditingProjectPrimaryFolders
{
	[(self.editingProjectPrimaryFoldersButtonGroup) animateButtonsOutWithCompletionHandler:^{
		(self.editingProjectPrimaryFoldersButtonGroup) = nil;
	}];
}

- (void)showButtonsForAddingNewProject
{
	GLAMainNavigationButtonGroup *buttonGroup = [GLAMainNavigationButtonGroup buttonGroupWithBarController:self];
	
	NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Title for cancel creating new project button");
	(self.addingNewProjectCancelButton) = [buttonGroup makeLeadingButtonWithTitle:cancelTitle action:@selector(cancelGoingToPreviousUnrelatedSection:) identifier:@"cancelAddNewProject"];
	
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

#pragma mark -

- (void)showButtonsForCurrentCollection
{
	GLANavigationButtonGroup *buttonGroup = [GLANavigationButtonGroup buttonGroupWithViewController:self templateButton:(self.templateButton)];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	GLACollection *collection = (self.currentCollection);
	
	// Back
	NSString *backTitle = NSLocalizedString(@"Back", @"Title for collection back button to go back");
	[buttonGroup makeLeadingButtonWithTitle:backTitle action:@selector(exitEditedCollection:) identifier:@"back-collection"];
	
	// Collection title
	NSString *collectionTitle = (collection.name);
	GLAButton *titleButton = [buttonGroup makeCenterButtonWithTitle:collectionTitle action:@selector(editCollectionDetails:) identifier:@"collectionTitle"];
	(titleButton.hasSecondaryStyle) = NO;
	(titleButton.textHighlightColor) = [uiStyle colorForCollectionColor:(collection.color)];
	
#if GLA_ENABLE_COLLECTIONS_STACK_VIEW
	// View mode
	GLASegmentedControl *viewModeSegmentedControl = [[GLASegmentedControl alloc] init];
	(viewModeSegmentedControl.target) = self;
	(viewModeSegmentedControl.action) = @selector(changeCollectionViewMode:);
	(viewModeSegmentedControl.segmentCount) = 2;
	[viewModeSegmentedControl setLabel:NSLocalizedString(@"Two Pane", @"Title for collection view mode button for list view") forSegment:0];
	[viewModeSegmentedControl setLabel:NSLocalizedString(@"Expanded", @"Title for collection view mode button for expanded view") forSegment:1];
	(viewModeSegmentedControl.font) = (uiStyle.buttonFont);
	[viewModeSegmentedControl sizeToFit];
	(viewModeSegmentedControl.backgroundInsetXAmount) = 0.0;
	(viewModeSegmentedControl.backgroundInsetYAmount) = 8.0;
	(viewModeSegmentedControl.cell.verticalOffsetDown) = -1.0;
	
	[buttonGroup addTrailingView:viewModeSegmentedControl];
	(self.collectionViewModeSegmentedControl) = viewModeSegmentedControl;
	[self updateUIForCurrentCollection];
#endif
	
	(buttonGroup.centerButtonInDuration) = 2.0 / 12.0;
	(buttonGroup.leadingButtonInDuration) = 2.4 / 12.0;
	(buttonGroup.trailingViewOffset) = -8.0;
	
	[buttonGroup animateButtonsIn];
	
	(self.collectionButtonGroup) = buttonGroup;
	
	NSColor *collectionColor = [uiStyle colorForCollectionColor:(collection.color)];
	//[self animateBackgroundColorTo:collectionColor];
	[(self.navigationBar) highlightWithColor:collectionColor animate:YES];
}

- (void)hideButtonsForCurrentCollection
{
	[(self.collectionButtonGroup) animateButtonsOutWithCompletionHandler:^{
		
	}];
	
	[(self.navigationBar) highlightWithColor:nil animate:YES];
}

- (void)updateUIForCurrentCollection
{
#if GLA_ENABLE_COLLECTIONS_STACK_VIEW
	GLAEditCollectionSection *section = (id)(self.currentSection);
	GLASegmentedControl *viewModeSegmentedControl = (self.collectionViewModeSegmentedControl);
	
	NSString *viewMode = (section.viewMode);
	BOOL viewModeIsList = !viewMode || [viewMode isEqualToString:GLACollectionViewModeList];
	[viewModeSegmentedControl setSelectedSegment:( viewModeIsList ? 0 : 1 )];
#endif
}

- (IBAction)changeCollectionViewMode:(id)sender
{
	GLASegmentedControl *viewModeSegmentedControl = (self.collectionViewModeSegmentedControl);
	GLAMainSectionNavigator *sectionNavigator = (self.sectionNavigator);
	
	switch (viewModeSegmentedControl.selectedSegment) {
		case 0:
			[sectionNavigator collectionMakeViewModeList];
			break;
		case 1:
		default:
			[sectionNavigator collectionMakeViewModeExpanded];
	}
}

#pragma mark -

- (void)showButtonsForAddingNewCollection
{
	GLAMainNavigationButtonGroup *buttonGroup = [GLAMainNavigationButtonGroup buttonGroupWithBarController:self];
	
	NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Title for cancel creating new collection button");
	[buttonGroup makeLeadingButtonWithTitle:cancelTitle action:@selector(cancelGoingToPreviousUnrelatedSection:) identifier:@"cancelAddNewProject"];
	
	GLAAddNewCollectionSection *currentSection = (GLAAddNewCollectionSection *)(self.currentSection);
	BOOL hasPendingFiles = NO;
	
	if ([currentSection isKindOfClass:[GLAAddNewCollectedFilesCollectionSection class]]) {
		GLAAddNewCollectedFilesCollectionSection *collectedFilesSection = (GLAAddNewCollectedFilesCollectionSection *)currentSection;
		hasPendingFiles = (collectedFilesSection.pendingAddedCollectedFilesInfo != nil);
	}
	
	NSString *title;
	if (hasPendingFiles) {
		//GLAPendingAddedCollectedFilesInfo *filesInfo = (currentSection.pendingAddedCollectedFilesInfo);
		//NSUInteger fileCount = (filesInfo.fileURLs.count);
		title = NSLocalizedString(@"New Collection with Files", @"Title label for creating new collection with pending files");
	}
	else {
		title = NSLocalizedString(@"New Collection", @"Title label for creating new collection");
	}
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
	[(self.sectionNavigator) addNewProject];
}

- (NSString *)titleForEditingProjectBackButton
{
	GLAMainSection *currentSection = (self.currentSection);
	GLAMainSection *previousSection = (currentSection.previousSection);
	
	if (previousSection.isAllProjects) {
		return NSLocalizedString(@"Back to All Projects", @"Title for editing project back button to all projects");
	}
	else {
		return NSLocalizedString(@"Back", @"Title for editing project back button");
	}
}

- (NSString *)titleForEditingProjectPrimaryFoldersBackButton
{
	return NSLocalizedString(@"Done", @"Title for editing primary folders of project back button");
}

- (IBAction)exitEditedProject:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	[(self.sectionNavigator) goToPreviousSection];
}

- (IBAction)exitEditPrimaryFoldersOfProject:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	[(self.sectionNavigator) goToPreviousSection];
}

- (IBAction)workOnCurrentProjectNow:(id)sender
{
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		GLAMainSection *currentSection = (self.currentSection);
		NSAssert([currentSection isKindOfClass:[GLAEditProjectSection class]], @"Current section (%@) must be a GLAMainContentEditProjectSection when calling -workOnCurrentProjectNow: action", currentSection);
		
		GLAEditProjectSection *editProjectSection = (GLAEditProjectSection *)currentSection;
		
		[delegate mainNavigationBarController:self handleWorkNowOnProject:(editProjectSection.project)];
	}
}

- (IBAction)cancelGoingToPreviousUnrelatedSection:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	[(self.sectionNavigator) goToPreviousUnrelatedSection];
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
	
	[(self.sectionNavigator) goToPreviousSection];
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


#pragma mark -


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
