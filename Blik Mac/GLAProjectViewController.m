//
//  GLAPrototypeBProjectViewController.m
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import QuartzCore;
#import "GLAProjectViewController.h"
#import "GLAProjectCollectionsViewController.h"
#import "GLAProjectHighlightsViewController.h"
#import "GLAInstructionsViewController.h"
//#import "GLAProjectPlanViewController.h"
#import "GLAUIStyle.h"
#import "GLAProjectManager.h"
#import "GLAReminderManager.h"
#import "GLAChooseRemindersViewController.h"
#import <objc/runtime.h>


NSString *GLAProjectViewControllerDidBeginEditingCollectionsNotification = @"GLA.projectViewController.didBeginEditingCollections";
NSString *GLAProjectViewControllerDidEndEditingCollectionsNotification = @"GLA.projectViewController.didEndEditingCollections";

NSString *GLAProjectViewControllerDidBeginEditingPlanNotification = @"GLA.projectViewController.didBeginEditingPlan";
NSString *GLAProjectViewControllerDidEndEditingPlanNotification = @"GLA.projectViewController.didEndEditingPlan";

NSString *GLAProjectViewControllerDidEnterCollectionNotification = @"GLA.projectViewController.didEnterCollection";

NSString *GLAProjectViewControllerRequestAddNewCollectionNotification = @"GLA.projectViewController.requestAddNewCollection";


@interface GLAProjectViewController ()
{
	GLAProject *_project;
}

@property(readwrite, nonatomic) BOOL editingCollections;
@property(readwrite, nonatomic) BOOL editingPlan;
@property(readwrite, nonatomic) BOOL choosingExistingReminders;

@property(nonatomic, getter = isAnimatingFocusChange) BOOL animatingFocusChange;

@property(strong, nonatomic) NSLayoutConstraint *itemsViewXConstraint;
@property(strong, nonatomic) NSLayoutConstraint *planViewXConstraint;

@property(nonatomic) CGFloat collectionsViewLeadingConstraintDefaultConstant;
@property(nonatomic) CGFloat collectionsViewHeightConstraintDefaultConstant;

@property(nonatomic) CGFloat highlightsViewTrailingConstraintDefaultConstant;
@property(nonatomic) CGFloat highlightsViewHeightConstraintDefaultConstant;

@end

@interface GLAProjectViewController (addCollectedFilesChoiceActionsDelegate) <GLAAddCollectedFilesChoiceActionsDelegate>

@end

@implementation GLAProjectViewController

- (GLAProjectView *)projectView
{
	return (id)(self.view);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		
	}
    return self;
}


- (void)loadView
{
	[super loadView];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	GLAUIStyle *activeStyle = [GLAUIStyle activeStyle];
	
	(self.projectView.delegate) = self;
	
	[nc addObserver:self selector:@selector(collectionsViewControllerDidClickCollection:) name:GLAProjectCollectionsViewControllerDidClickCollectionNotification object:(self.collectionsViewController)];
	
	
	(self.collectionsViewController.addCollectedFilesChoiceActionsDelegate) = self;
	
	
	NSTextField *nameTextField = (self.nameTextField);
	(nameTextField.delegate) = self;
	
	[activeStyle prepareProjectNameField:nameTextField];
	/*
	[nc addObserver:self selector:@selector(nameTextDidBeginEditing:) name:NSControlTextDidBeginEditingNotification object:nameTextField];
	[nc addObserver:self selector:@selector(nameTextDidEndEditing:) name:NSControlTextDidEndEditingNotification object:nameTextField];
	[nc addObserver:self selector:@selector(nameTextDidBecomeFirstResponder:) name:GLATextFieldDidBecomeFirstResponder object:nameTextField];
	[nc addObserver:self selector:@selector(nameTextDidResignFirstResponder:) name:GLATextFieldDidResignFirstResponder object:nameTextField];
	*/
	//GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	//(nameTextField.textColor) = (uiStyle.editedTextColor);
	//(nameTextField.drawsBackground) = YES;
	//(nameTextField.backgroundColor) = (uiStyle.editedTextBackgroundColor);
	//(nameTextField.backgroundColor) = [NSColor redColor];
	//[nameTextField setNeedsDisplay:YES];
	
	CGFloat defaultListsHeight = 174.0;
	(self.collectionsViewHeightConstraint.constant) = defaultListsHeight;
	(self.highlightsViewHeightConstraint.constant) = defaultListsHeight;
	
	
	(self.collectionsViewLeadingConstraintDefaultConstant) = (self.collectionsViewLeadingConstraint.constant);
	(self.collectionsViewHeightConstraintDefaultConstant) = (self.collectionsViewHeightConstraint.constant);
	
	(self.highlightsViewTrailingConstraintDefaultConstant) = (self.highlightsViewTrailingConstraint.constant);
	(self.highlightsViewHeightConstraintDefaultConstant) = (self.highlightsViewHeightConstraint.constant);
	
	
	NSView *actionsBarView = (self.actionsBarController.view);
	(actionsBarView.wantsLayer) = YES;
	(actionsBarView.layer.backgroundColor) = (activeStyle.contentBackgroundColor.CGColor);
	
	
	[activeStyle prepareContentTextField:(self.nameTextField)];
}

- (void)viewWillTransitionIn
{
	[super viewWillTransitionIn];
	
	[(self.collectionsViewController) viewWillTransitionIn];
	[(self.highlightsViewController) viewWillTransitionIn];
}

- (void)viewDidTransitionIn
{
	[super viewDidTransitionIn];
	
	[(self.collectionsViewController) viewDidTransitionIn];
	[(self.highlightsViewController) viewDidTransitionIn];
	
	[(self.collectionsScrollView.contentView) scrollToPoint:NSZeroPoint];
	[(self.highlightsScrollView.contentView) scrollToPoint:NSZeroPoint];
}

- (void)viewWillTransitionOut
{
	[super viewWillTransitionOut];
	
	[(self.collectionsViewController) viewWillTransitionOut];
	[(self.highlightsViewController) viewWillTransitionOut];
}

- (void)viewDidTransitionOut
{
	[super viewDidTransitionOut];
	
	[(self.collectionsViewController) viewDidTransitionOut];
	[(self.highlightsViewController) viewDidTransitionOut];
}

@synthesize project = _project;

- (void)setProject:(GLAProject *)project
{
	// Project instances are immutable objects. If they are the same object, no changes have been made.
	if (_project == project) {
		return;
	}
	
	//BOOL isSameProject = (_project != nil) && [(_project.UUID) isEqual:(project.UUID)];
	
	_project = project;
	
	//if (!isSameProject) {
		(self.collectionsViewController.project) = project;
		(self.highlightsViewController.project) = project;
	//}
	
	(self.nameTextField.stringValue) = (project.name);
}

#pragma mark Actions

- (IBAction)editCollections:(id)sender
{
	if (self.animatingFocusChange) {
		return;
	}
	
	if (!(self.editingCollections)) {
		[self beginEditingCollections];
		[(self.actionsBarController) showBarForEditingItems];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectViewControllerDidBeginEditingCollectionsNotification object:self];
	}
	else {
		[self endEditingCollections];
		[(self.actionsBarController) hideBarForEditingItems];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectViewControllerDidEndEditingCollectionsNotification object:self];
	}
}

- (IBAction)addNewCollection:(id)sender
{
	[(self.sectionNavigator) addNewCollectionToProject:(self.project)];
}

#if 0

- (IBAction)editPlan:(id)sender
{
	if (self.animatingFocusChange) {
		return;
	}
	
	if (!(self.editingPlan)) {
		[self beginEditingPlan];
		[(self.actionsBarController) showBarForEditingPlan];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectViewControllerDidBeginEditingPlanNotification object:self];
	}
	else {
		[self endEditingPlan];
		[(self.actionsBarController) hideBarForEditingPlan];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectViewControllerDidEndEditingPlanNotification object:self];
	}
}

#endif

- (void)clearName
{
	(self.nameTextField.stringValue) = @"";
}

- (void)focusNameTextField
{
	[(self.view.window) makeFirstResponder:(self.nameTextField)];
}

- (void)changeName:(id)sender
{
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	
	NSString *newName = (self.nameTextField.stringValue);
	newName = [pm normalizeName:newName];
	if ([pm nameIsValid:newName]) {
		(self.project) = [pm renameProject:(self.project) toName:newName];
		[(self.view.window) makeFirstResponder:nil];
	}
	else {
		NSBeep();
	}
}

#pragma mark Notifications

- (void)collectionsViewControllerDidClickCollection:(NSNotification *)note
{
	if (self.editingCollections) {
		return;
	}
	
	GLACollection *collection = (note.userInfo)[@"collection"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectViewControllerDidEnterCollectionNotification object:self userInfo:
	 @{
	   @"collection": collection
	   }];
}

#pragma mark -

- (NSScrollView *)collectionsScrollView
{
	return (self.collectionsViewController.tableView.enclosingScrollView);
}

- (NSScrollView *)highlightsScrollView
{
	return (self.highlightsViewController.tableView.enclosingScrollView);
}

- (void)matchWithOtherProjectViewController:(GLAProjectViewController *)otherController
{
	[(self.collectionsScrollView.contentView) scrollToPoint:(otherController.collectionsScrollView.contentView.bounds).origin];
	
	[(self.highlightsScrollView.contentView) scrollToPoint:(otherController.highlightsScrollView.contentView.bounds).origin];
	
}

#pragma mark - Editing Sections

- (CGFloat)opacityOfNameTextFieldWhenEditingInnerSection
{
	return 4.0 / 12.0;
}

- (void)didBeginEditingInnerSection
{
	NSTextField *nameTextField = (self.nameTextField);
	
	//(nameTextField.editable) = NO;
	(nameTextField.selectable) = NO;
	[(nameTextField.window) makeFirstResponder:nil];
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 12.0;
		
		(nameTextField.animator.alphaValue) = (self.opacityOfNameTextFieldWhenEditingInnerSection);
	} completionHandler:nil];
}

- (void)didFinishEditingInnerSection
{
	NSTextField *nameTextField = (self.nameTextField);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 12.0;
		
		(nameTextField.animator.alphaValue) = 1.0;
	} completionHandler:^ {
		(nameTextField.editable) = YES;
		//(nameTextField.selectable) = YES;
	}];
}

#pragma mark Editing Collections

- (void)animateCollectionsViewForEditingChange:(BOOL)isEditing
{
	(self.animatingFocusChange) = YES;
	
	GLAProjectView *projectView = (self.projectView);
	NSScrollView *collectionsScrollView = (self.collectionsScrollView);
	
	if (isEditing) {
		[self didBeginEditingInnerSection];
		
		// Center items view
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 6.0 / 12.0;
			(context.allowsImplicitAnimation) = YES;
			
			//(self.itemsViewXConstraint) = [self addConstraintForCenteringView:collectionsScrollView inView:projectView];
			(self.itemsViewXConstraint) = [self addConstraintForCenteringView:(self.collectionsViewController.view) inView:projectView];
			
			[projectView layoutSubtreeIfNeeded];
		} completionHandler:^ {
			(self.animatingFocusChange) = NO;
		}];
		
		// Resize item view to be taller, and animate plan view off.
		(self.collectionsViewHeightConstraintDefaultConstant) = NSHeight(collectionsScrollView.frame);
		[projectView removeConstraint:(self.highlightsViewBottomConstraint)];
		
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 4.0 / 12.0;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(self.collectionsViewHeightConstraint.animator.constant) = 300;
			(self.highlightsViewTrailingConstraint.animator.constant) = -600;
		} completionHandler:nil];
		
		// Fade out plan view
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 2.5 / 12.0;
			
			(self.highlightsViewController.view.animator.alphaValue) = 0.0;
			//(highlightsScrollView.animator.alphaValue) = 0.0;
		} completionHandler:nil];
	}
	else {
		[self didFinishEditingInnerSection];
		
		// Remove centering constraint
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 6.0 / 12.0;
			(context.allowsImplicitAnimation) = YES;
			
			[projectView removeConstraint:(self.itemsViewXConstraint)];
			
			[projectView layoutSubtreeIfNeeded];
		} completionHandler:^ {
			(self.animatingFocusChange) = NO;
		}];
		
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 3.0 / 12.0;
			
			(self.collectionsViewHeightConstraint.animator.constant) = (self.collectionsViewHeightConstraintDefaultConstant);
		} completionHandler:^ {
			[projectView addConstraint:(self.highlightsViewBottomConstraint)];
		}];
		
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 6.0 / 12.0;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
			
			(self.highlightsViewController.view.animator.alphaValue) = 1.0;
			//(highlightsScrollView.animator.alphaValue) = 1.0;
			(self.highlightsViewTrailingConstraint.animator.constant) = (self.highlightsViewTrailingConstraintDefaultConstant);
		} completionHandler:nil];
	}
}

- (void)beginEditingCollections
{
	(self.editingCollections) = YES;
	//(self.editingPlan) = NO;
	
	(self.collectionsViewController.editing) = YES;
	
	[self animateCollectionsViewForEditingChange:YES];
}

- (void)endEditingCollections
{
	(self.editingCollections) = NO;
	
	(self.collectionsViewController.editing) = NO;
	
	[self animateCollectionsViewForEditingChange:NO];
}

#pragma mark Editing Plan

- (void)animatePlanViewForEditingChange:(BOOL)isEditing
{
	(self.animatingFocusChange) = YES;
	
	GLAProjectView *projectView = (self.projectView);
	NSScrollView *collectionsScrollView = (self.collectionsScrollView);
	NSScrollView *highlightsScrollView = (self.highlightsScrollView);
	
	if (isEditing) {
		[self didBeginEditingInnerSection];
		
		// Center items view
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 6.0 / 12.0;
			(context.allowsImplicitAnimation) = YES;
			
			//(self.planViewXConstraint) = [self addConstraintForCenteringView:highlightsScrollView inView:projectView];
			(self.planViewXConstraint) = [self addConstraintForCenteringView:(self.highlightsViewController.view) inView:projectView];
			
			[projectView layoutSubtreeIfNeeded];
		} completionHandler:^ {
			(self.animatingFocusChange) = NO;
		}];
		
		// Store the current height so it can be animated back to later.
		(self.highlightsViewHeightConstraintDefaultConstant) = NSHeight(highlightsScrollView.frame);
		// Stop allowing the items view to affect the window height.
		[projectView removeConstraint:(self.collectionsViewBottomConstraint)];
		// Resize item view to be taller, and animate plan view off.
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 4.0 / 12.0;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(self.highlightsViewHeightConstraint.animator.constant) = 300;
			(self.collectionsViewLeadingConstraint.animator.constant) = -600;
		} completionHandler:nil];
		
		// Fade out plan view
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 2.5 / 12.0;
			
			(collectionsScrollView.animator.alphaValue) = 0.0;
		} completionHandler:nil];
	}
	else {
		[self didFinishEditingInnerSection];
		
		// Remove centering constraint
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 6.0 / 12.0;
			(context.allowsImplicitAnimation) = YES;
			
			[projectView removeConstraint:(self.planViewXConstraint)];
			
			[projectView layoutSubtreeIfNeeded];
		} completionHandler:^ {
			(self.animatingFocusChange) = NO;
		}];
		
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 4.0 / 12.0;
			
			(self.highlightsViewHeightConstraint.animator.constant) = (self.highlightsViewHeightConstraintDefaultConstant);
		} completionHandler:^ {
			[projectView addConstraint:(self.collectionsViewBottomConstraint)];
		}];
		
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 6.0 / 12.0;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
			
			(collectionsScrollView.animator.alphaValue) = 1.0;
			(self.collectionsViewLeadingConstraint.animator.constant) = (self.collectionsViewLeadingConstraintDefaultConstant);
		} completionHandler:nil];
	}
}

#if 0

- (void)beginEditingPlan
{
	//(self.editingCollections) = NO;
	(self.editingPlan) = YES;
	
	(self.planViewController.editing) = YES;
	
	[self animatePlanViewForEditingChange:YES];
	//[self updateConstraintsWithAnimatedDuration:7.0 / 12.0];
	
	/*
	GLAReminderManager *reminderManager = [GLAReminderManager sharedReminderManager];
	if (!(reminderManager.isAuthorized)) {
		[reminderManager requestAccessToReminders:^(BOOL granted, NSError *error) {
			BOOL hasNoAccess = !granted;
			
			(self.planViewController.showsDoesNotHaveAccessToReminders) = hasNoAccess;
		}];
	}
	else {
		if (YES) {
			CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
			[reminderManager useAllReminders:^(NSArray *allReminders) {
				CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
				NSLog(@"Took %f seconds to get all reminders", endTime - startTime);
				//NSLog(@"%lu %@", (allReminders.count), allReminders);
			}];
		}
	}
	 */
}

- (void)endEditingPlan
{
	(self.editingPlan) = NO;
	
	(self.highlightsViewController.editing) = NO;
	
	if (self.choosingExistingReminders) {
		[self endChoosingExistingReminders];
	}
	
	[self animatePlanViewForEditingChange:NO];
	
	//[self updateConstraintsWithAnimatedDuration:7.0 / 12.0];
}

#endif

#pragma mark Choosing Existing Reminders

- (void)animatePlanViewLeft
{
	GLAProjectView *projectView = (self.projectView);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 6.0 / 12.0;
		(context.allowsImplicitAnimation) = YES;
		
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		[projectView removeConstraint:(self.planViewXConstraint)];
		//(self.planViewXConstraint.priority) = 250;
		(self.highlightsViewTrailingConstraint.constant) = 500;
		(self.nameTextField.alphaValue) = 0.0;
		
		[projectView layoutSubtreeIfNeeded];
		
	} completionHandler:^ {
		(self.nameTextField.hidden) = YES;
	}];
}

#if 0

- (IBAction)chooseExistingReminders:(id)sender
{
	if (self.choosingExistingReminders) {
		return;
	}
	
	if (!(self.chooseRemindersViewController)) {
		GLAChooseRemindersViewController *chooseRemindersViewController = [[GLAChooseRemindersViewController alloc] initWithNibName:@"GLAChooseRemindersViewController" bundle:nil];
		
		(chooseRemindersViewController.view.identifier) = @"chooseRemindersView";
		(chooseRemindersViewController.view.wantsLayer) = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chooseExistingRemindersDidExit:) name:GLAChooseRemindersViewControllerDidPerformExitNotification object:chooseRemindersViewController];
		
		(self.chooseRemindersViewController) = chooseRemindersViewController;
	}
	
	(self.choosingExistingReminders) = YES;
	
	//NSLayoutConstraint *scrollLeadingConstraint = (self.planViewController.scrollLeadingConstraint);
	
	GLAChooseRemindersViewController *chooseRemindersViewController = (self.chooseRemindersViewController);
	[chooseRemindersViewController viewWillTransitionIn];
	
	NSView *chooseRemindersView = (chooseRemindersViewController.view);
	[self fillViewWithChildView:chooseRemindersView];
	
	// Copy bottom constraint from plan view to choose reminders view
	GLAProjectView *projectView = (self.projectView);
	NSLayoutConstraint *planViewBottomConstraint = (self.planViewBottomConstraint);
	__block NSLayoutConstraint *newBottomConstraint;
	[GLAViewController copyLayoutConstraints:@[planViewBottomConstraint] replacingUsesOf:(self.planViewController.view) with:chooseRemindersView constraintVisitor:^(NSLayoutConstraint *oldConstraint, NSLayoutConstraint *newConstraint) {
		newBottomConstraint = newConstraint;
		(newBottomConstraint.identifier) = [GLAViewController layoutConstraintIdentifierWithBaseIdentifier:@"bottom" forChildView:chooseRemindersView];
	}];
	
	[projectView removeConstraint:[self layoutConstraintWithIdentifier:@"height" forChildView:chooseRemindersView]];
	[projectView addConstraint:newBottomConstraint];
	
	[chooseRemindersViewController viewDidTransitionIn];
	
	
	NSLayoutConstraint *chooseRemindersLeadingConstraint = [self layoutConstraintWithIdentifier:@"leading" forChildView:chooseRemindersView];
	
	(chooseRemindersView.alphaValue) = 0.0;
	(chooseRemindersLeadingConstraint.constant) = 300.0;
	
	[projectView layoutSubtreeIfNeeded];
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 6.0 / 12.0;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		//(context.allowsImplicitAnimation) = NO;
		
		//(chooseRemindersView.alphaValue) = 0.0;
		(chooseRemindersView.animator.alphaValue) = 1.0;
		
		//(chooseRemindersLeadingConstraint.constant) = 300.0;
		(chooseRemindersLeadingConstraint.animator.constant) = 0.0;
		
		//[projectView layoutSubtreeIfNeeded];
	} completionHandler:nil];
	
	
	[self animatePlanViewLeft];
	//[chooseRemindersViewController showRemindersTable];
}

- (void)endChoosingExistingReminders
{
	GLAProjectView *projectView = (self.projectView);
	
	GLAChooseRemindersViewController *chooseRemindersViewController = (self.chooseRemindersViewController);
	
	NSView *chooseRemindersView = (chooseRemindersViewController.view);
	
	// Animate choose view out
	NSLayoutConstraint *chooseRemindersLeadingConstraint = [self layoutConstraintWithIdentifier:@"leading" forChildView:chooseRemindersView];
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 6.0 / 12.0;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		
		//(chooseRemindersView.alphaValue) = 1.0;
		(chooseRemindersView.animator.alphaValue) = 1.0;
		
		//(chooseRemindersLeadingConstraint.constant) = 500.0;
		(chooseRemindersLeadingConstraint.animator.constant) = 500.0;
	} completionHandler:^ {
		[chooseRemindersViewController viewWillTransitionOut];
		[chooseRemindersView removeFromSuperview];
		[chooseRemindersViewController viewDidTransitionOut];
	}];
	
	// Animate plan view back in
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 6.0 / 12.0;
		(context.allowsImplicitAnimation) = YES;
		
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		(self.nameTextField.hidden) = NO;
		(self.nameTextField.alphaValue) = (self.opacityOfNameTextFieldWhenEditingInnerSection);
		
		[projectView addConstraint:(self.planViewXConstraint)];
		(self.planViewTrailingConstraint.constant) = 0;
		
		[projectView layoutSubtreeIfNeeded];
		
	} completionHandler:^ {
		//(self.nameTextField.hidden) = YES;
	}];
	
	(self.choosingExistingReminders) = NO;
}

- (void)chooseExistingRemindersDidExit:(NSNotification *)note
{
	[self endChoosingExistingReminders];
}

#endif

- (NSLayoutConstraint *)addConstraintForCenteringView:(NSView *)view inView:(NSView *)holderView
{
	return [self addLayoutConstraintToMatchAttribute:NSLayoutAttributeCenterX withChildView:view identifier:@"centerX" priority:999];
}

/*
- (void)styleNameFieldForEditing:(BOOL)isEditing
{
	NSTextField *nameTextField = (self.nameTextField);
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	if (isEditing) {
		(nameTextField.textColor) = (uiStyle.editedTextColor);
		//(nameTextField.drawsBackground) = YES;
		(nameTextField.backgroundColor) = (uiStyle.editedTextBackgroundColor);
		
		NSText *fieldEditor = [(nameTextField.window) fieldEditor:YES forObject:nameTextField];
		(fieldEditor.textColor) = (nameTextField.textColor);
	}
	else {
		(nameTextField.textColor) = (uiStyle.lightTextColor);
		//(nameTextField.drawsBackground) = NO;
		(nameTextField.backgroundColor) = (uiStyle.contentBackgroundColor);
	}
}

- (void)nameTextDidBeginEditing:(NSNotification *)note
{
	
}



- (void)nameTextDidBecomeFirstResponder:(NSNotification *)note
{NSLog(@"nameTextDidBecomeFirstResponder");
	[self styleNameFieldForEditing:YES];
}

- (void)nameTextDidResignFirstResponder:(NSNotification *)note
{
}
*/
/*
- (void)nameTextDidEndEditing:(NSNotification *)note
{
	(self.nameTextField);
}
*/
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	// Return or Enter
	if (sel_isEqual(@selector(insertNewline:), command)) {
		[(textView.window) makeFirstResponder:nil];
		return YES;
	}
	// Option-Return
	else if (sel_isEqual(@selector(insertNewlineIgnoringFieldEditor:), command)) {
		return YES;
	}
	
	return NO;
}

@end


@implementation GLAProjectViewController (GLAAddCollectedFilesChoiceActions)

- (void)performAddCollectedFilesToExistingCollection:(NSResponder *)responder info:(GLAPendingAddedCollectedFilesInfo *)info
{
	
}

- (void)performAddCollectedFilesToNewCollection:(NSResponder *)responder info:(GLAPendingAddedCollectedFilesInfo *)info
{
	id<GLAProjectViewControllerDelegate> delegate = (self.delegate);
	if (!delegate) {
		return;
	}
	
	if ([delegate respondsToSelector:@selector(projectViewController:performAddCollectedFilesToNewCollection:)]) {
		[delegate projectViewController:self performAddCollectedFilesToNewCollection:info];
	}
}

@end
