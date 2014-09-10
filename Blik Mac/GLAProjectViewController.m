//
//  GLAPrototypeBProjectViewController.m
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import QuartzCore;
#import "GLAProjectViewController.h"
#import "GLAUIStyle.h"
#import "GLAReminderManager.h"
#import "GLACollectionFilesListContent.h"
#import "GLAChooseRemindersViewController.h"
#import <objc/runtime.h>


NSString *GLAProjectViewControllerDidBeginEditingItemsNotification = @"GLA.projectViewController.didBeginEditingItems";
NSString *GLAProjectViewControllerDidEndEditingItemsNotification = @"GLA.projectViewController.didEndEditingItems";

NSString *GLAProjectViewControllerDidBeginEditingPlanNotification = @"GLA.projectViewController.didBeginEditingPlan";
NSString *GLAProjectViewControllerDidEndEditingPlanNotification = @"GLA.projectViewController.didEndEditingPlan";

NSString *GLAProjectViewControllerDidEnterCollectionNotification = @"GLA.projectViewController.didEnterCollection";


@interface GLAProjectViewController ()

@property(nonatomic) GLAProject *private_project;

@property(readwrite, nonatomic) BOOL editingCollections;
@property(readwrite, nonatomic) BOOL editingPlan;
@property(readwrite, nonatomic) BOOL choosingExistingReminders;

@property(nonatomic, getter = isAnimatingFocusChange) BOOL animatingFocusChange;

@property(strong, nonatomic) NSLayoutConstraint *itemsViewXConstraint;
@property(strong, nonatomic) NSLayoutConstraint *planViewXConstraint;

@property(nonatomic) CGFloat itemsViewLeadingConstraintDefaultConstant;
@property(nonatomic) CGFloat itemsViewHeightConstraintDefaultConstant;

@property(nonatomic) CGFloat planViewTrailingConstraintDefaultConstant;
@property(nonatomic) CGFloat planViewHeightConstraintDefaultConstant;

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
	
	
	NSTextField *nameTextField = (self.nameTextField);
	(nameTextField.delegate) = self;
	(nameTextField.font) = (activeStyle.projectTitleFont);
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
	(self.itemsViewHeightConstraint.constant) = defaultListsHeight;
	(self.planViewHeightConstraint.constant) = defaultListsHeight;
	
	
	(self.itemsViewLeadingConstraintDefaultConstant) = (self.itemsViewLeadingConstraint.constant);
	(self.itemsViewHeightConstraintDefaultConstant) = (self.itemsViewHeightConstraint.constant);
	
	(self.planViewTrailingConstraintDefaultConstant) = (self.planViewTrailingConstraint.constant);
	(self.planViewHeightConstraintDefaultConstant) = (self.planViewHeightConstraint.constant);
	
	
	GLAView *actionsBarView = (self.actionsBarController.view);
	(actionsBarView.wantsLayer) = YES;
	(actionsBarView.layer.backgroundColor) = (activeStyle.contentBackgroundColor.CGColor);
	
	
	[activeStyle prepareContentTextField:(self.nameTextField)];
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	[(self.itemsScrollView.contentView) scrollToPoint:NSZeroPoint];
	[(self.planScrollView.contentView) scrollToPoint:NSZeroPoint];
}

- (GLAProject *)project
{
	return (self.private_project);
}

- (void)setProject:(GLAProject *)project
{NSLog(@"SET PROJECT %@", project);
	if ((self.private_project) != project) {
		(self.private_project) = project;
		
		(self.collectionsViewController.project) = project;
		(self.planViewController.project) = project;
		
		(self.nameTextField.stringValue) = (project.name);
		
		
	}
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectViewControllerDidBeginEditingItemsNotification object:self];
	}
	else {
		[self endEditingCollections];
		[(self.actionsBarController) hideBarForEditingItems];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectViewControllerDidEndEditingItemsNotification object:self];
	}
}

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

- (void)clearName
{
	(self.nameTextField.stringValue) = @"";
}

- (void)focusNameTextField
{
	[(self.view.window) makeFirstResponder:(self.nameTextField)];
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

- (NSScrollView *)planScrollView
{
	return (self.planViewController.tableView.enclosingScrollView);
}

- (void)matchWithOtherProjectViewController:(GLAProjectViewController *)otherController
{
	[(self.itemsScrollView.contentView) scrollToPoint:(otherController.itemsScrollView.contentView.bounds).origin];
	
	[(self.planScrollView.contentView) scrollToPoint:(otherController.planScrollView.contentView.bounds).origin];
	
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
	NSScrollView *itemsScrollView = [self collectionsScrollView];
	NSScrollView *planScrollView = [self planScrollView];
	
	if (isEditing) {
		[self didBeginEditingInnerSection];
		
		// Center items view
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 6.0 / 12.0;
			(context.allowsImplicitAnimation) = YES;
			
			(self.itemsViewXConstraint) = [self addConstraintForCenteringView:itemsScrollView inView:projectView];
			
			[projectView layoutSubtreeIfNeeded];
		} completionHandler:^ {
			(self.animatingFocusChange) = NO;
		}];
		
		// Resize item view to be taller, and animate plan view off.
		(self.itemsViewHeightConstraintDefaultConstant) = NSHeight(itemsScrollView.frame);
		NSLog(@"(self.planViewBottomConstraint) %@", (self.planViewBottomConstraint));
		[projectView removeConstraint:(self.planViewBottomConstraint)];
		
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 4.0 / 12.0;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(self.itemsViewHeightConstraint.animator.constant) = 300;
			(self.planViewTrailingConstraint.animator.constant) = -600;
		} completionHandler:nil];
		
		// Fade out plan view
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 2.5 / 12.0;
			
			(self.planViewController.view.animator.alphaValue) = 0.0;
			//(planScrollView.animator.alphaValue) = 0.0;
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
			
			(self.itemsViewHeightConstraint.animator.constant) = (self.itemsViewHeightConstraintDefaultConstant);
		} completionHandler:^ {
			[projectView addConstraint:(self.planViewBottomConstraint)];
		}];
		
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 6.0 / 12.0;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
			
			(self.planViewController.view.animator.alphaValue) = 1.0;
			//(planScrollView.animator.alphaValue) = 1.0;
			(self.planViewTrailingConstraint.animator.constant) = (self.planViewTrailingConstraintDefaultConstant);
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
	NSScrollView *itemsScrollView = [self collectionsScrollView];
	NSScrollView *planScrollView = [self planScrollView];
	
	if (isEditing) {
		[self didBeginEditingInnerSection];
		
		// Center items view
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 6.0 / 12.0;
			(context.allowsImplicitAnimation) = YES;
			
			(self.planViewXConstraint) = [self addConstraintForCenteringView:planScrollView inView:projectView];
			
			[projectView layoutSubtreeIfNeeded];
		} completionHandler:^ {
			(self.animatingFocusChange) = NO;
		}];
		
		// Store the current height so it can be animated back to later.
		(self.planViewHeightConstraintDefaultConstant) = NSHeight(planScrollView.frame);
		// Stop allowing the items view to affect the window height.
		[projectView removeConstraint:(self.itemsViewBottomConstraint)];
		// Resize item view to be taller, and animate plan view off.
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 4.0 / 12.0;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(self.planViewHeightConstraint.animator.constant) = 300;
			(self.itemsViewLeadingConstraint.animator.constant) = -600;
		} completionHandler:nil];
		
		// Fade out plan view
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 2.5 / 12.0;
			
			(itemsScrollView.animator.alphaValue) = 0.0;
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
			
			(self.planViewHeightConstraint.animator.constant) = (self.planViewHeightConstraintDefaultConstant);
		} completionHandler:^ {
			[projectView addConstraint:(self.itemsViewBottomConstraint)];
		}];
		
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 6.0 / 12.0;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
			
			(itemsScrollView.animator.alphaValue) = 1.0;
			(self.itemsViewLeadingConstraint.animator.constant) = (self.itemsViewLeadingConstraintDefaultConstant);
		} completionHandler:nil];
	}
}

- (void)beginEditingPlan
{
	//(self.editingCollections) = NO;
	(self.editingPlan) = YES;
	
	(self.planViewController.editing) = YES;
	
	[self animatePlanViewForEditingChange:YES];
	//[self updateConstraintsWithAnimatedDuration:7.0 / 12.0];
	
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
}

- (void)endEditingPlan
{
	(self.editingPlan) = NO;
	
	(self.planViewController.editing) = NO;
	
	if (self.choosingExistingReminders) {
		[self endChoosingExistingReminders];
	}
	
	[self animatePlanViewForEditingChange:NO];
	
	//[self updateConstraintsWithAnimatedDuration:7.0 / 12.0];
}

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
		(self.planViewTrailingConstraint.constant) = 500;
		(self.nameTextField.alphaValue) = 0.0;
		
		[projectView layoutSubtreeIfNeeded];
		
	} completionHandler:^ {
		(self.nameTextField.hidden) = YES;
	}];
}

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
	[chooseRemindersViewController viewWillAppear];
	
	NSView *chooseRemindersView = (chooseRemindersViewController.view);
	[self fillViewWithChildView:chooseRemindersView];
	
	// Copy bottom constraint from plan view to choose reminders view
	GLAProjectView *projectView = (self.projectView);
	NSLayoutConstraint *planViewBottomConstraint = (self.planViewBottomConstraint);
	NSArray *adjustedConstraints = [GLAViewController copyLayoutConstraints:@[planViewBottomConstraint] replacingUsesOf:(self.planViewController.view) with:chooseRemindersView];
	NSLayoutConstraint *newBottomConstraint = adjustedConstraints[0];
	(newBottomConstraint.identifier) = [GLAViewController layoutConstraintIdentifierWithBaseIdentifier:@"bottom" forChildView:chooseRemindersView];
	[projectView removeConstraint:[self layoutConstraintWithIdentifier:@"height" forChildView:chooseRemindersView]];
	[projectView addConstraint:newBottomConstraint];
	
	[chooseRemindersViewController viewDidAppear];
	
	
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
		[chooseRemindersViewController viewWillDisappear];
		[chooseRemindersView removeFromSuperview];
		[chooseRemindersViewController viewDidDisappear];
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


#pragma mark -


NSString *GLAProjectCollectionsViewControllerDidClickCollectionNotification = @"GLA.projectCollectionsViewController.didClickCollection";

@interface GLAProjectCollectionsViewController ()

@property(nonatomic) GLAProject *private_project;

@property(nonatomic) NSIndexSet *draggedRowIndexes;

- (IBAction)tableViewWasClicked:(id)sender;

@end

@implementation GLAProjectCollectionsViewController

- (NSTableView *)tableView
{
	return (id)(self.view);
}

- (GLAProject *)project
{
	return (self.private_project);
}

- (void)setProject:(GLAProject *)project
{
	if ((self.private_project) != project) {
		(self.private_project) = project;
		
		[self prepareDummyContent];
	}
}

- (void)prepareDummyContent
{
	GLAProject *project = (self.project);
	id<GLAArrayEditing> collectionListEditing = (project.collectionsEditing);
	
	GLACollectionFilesListContent *filesListContent = [GLACollectionFilesListContent new];
	
	[collectionListEditing addChildren:
	 @[
	   [GLACollection dummyCollectionWithTitle:@"Working Files" colorIdentifier:GLACollectionColorLightBlue content:filesListContent],
	   [GLACollection dummyCollectionWithTitle:@"Briefs" colorIdentifier:GLACollectionColorGreen content:filesListContent],
	   [GLACollection dummyCollectionWithTitle:@"Contacts" colorIdentifier:GLACollectionColorPinkyPurple content:filesListContent],
	   [GLACollection dummyCollectionWithTitle:@"Apps" colorIdentifier:GLACollectionColorRed content:filesListContent],
	   [GLACollection dummyCollectionWithTitle:@"Research" colorIdentifier:GLACollectionColorYellow content:filesListContent]
	   ]];
	
	[self reloadCollections];
}

- (void)reloadCollections
{
	(self.collections) = (self.project.copyCollections);
	[(self.tableView) reloadData];
}

- (void)prepareViews
{
	NSTableView *tableView = (self.tableView);
	[[GLAUIStyle activeStyle] prepareContentTableView:tableView];
	
	(tableView.target) = self;
	(tableView.action) = @selector(tableViewWasClicked:);
	
	(tableView.menu) = (self.contextualMenu);
	
	[tableView registerForDraggedTypes:@[GLACollectionJSONPasteboardType]];
	
	// I think Apple (from a WWDC video) says this is better for scrolling performance.
	(tableView.enclosingScrollView.wantsLayer) = YES;
	
	//(tableView.draggingDestinationFeedbackStyle) = NSTableViewDraggingDestinationFeedbackStyleGap;
}

- (void)loadView
{
	[super loadView];
	
	[self prepareViews];
}

- (void)awakeFromNib
{
	[self prepareViews];
	//[self prepareDummyContent];
}

- (IBAction)tableViewWasClicked:(id)sender
{
	NSTableView *tableView = (self.tableView);
	NSInteger clickedRow = (tableView.clickedRow);
	
	GLACollection *collection = (self.collections)[clickedRow];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectCollectionsViewControllerDidClickCollectionNotification object:self userInfo:
	 @{
	   @"row": @(clickedRow),
	   @"collection": collection
	   }];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.collections.count);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLACollection *collection = (self.collections)[row];
	return collection;
}

/*
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{NSLog(@"writeRowsWithIndexes");
	NSArray *collections = (self.collections);
	NSArray *draggedCollections = [collections objectsAtIndexes:rowIndexes];
	
	[GLACollection writeCollections:draggedCollections toPasteboard:pboard];
	
	return YES;
}*/

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
	GLACollection *collection = (self.collections)[row];
	return collection;
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes
{
	(self.draggedRowIndexes) = rowIndexes;
	//(tableView.draggingDestinationFeedbackStyle) = NSTableViewDraggingDestinationFeedbackStyleGap;
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	// Does not work for some reason.
	if (operation == NSDragOperationDelete) {
		id<GLAArrayEditing> collectionListEditing = (self.project.collectionsEditing);
		
		NSIndexSet *sourceRowIndexes = (self.draggedRowIndexes);
		(self.draggedRowIndexes) = nil;
		
		[collectionListEditing removeChildrenAtIndexes:sourceRowIndexes];
		
		[self reloadCollections];
	}
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	//NSLog(@"proposed row %ld %ld", (long)row, (long)dropOperation);
	
	NSPasteboard *pboard = (info.draggingPasteboard);
	if (![GLACollection canCopyCollectionsFromPasteboard:pboard]) {
		return NSDragOperationNone;
	}
	
	if (dropOperation == NSTableViewDropOn) {
		[tableView setDropRow:row dropOperation:NSTableViewDropAbove];
	}
	
	NSDragOperation sourceOperation = (info.draggingSourceOperationMask);
	if (sourceOperation & NSDragOperationMove) {
		return NSDragOperationMove;
	}
	else if (sourceOperation & NSDragOperationCopy) {
		return NSDragOperationCopy;
	}
	else if (sourceOperation & NSDragOperationDelete) {
		return NSDragOperationDelete;
	}
	else {
		return NSDragOperationNone;
	}
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pboard = (info.draggingPasteboard);
	if (![GLACollection canCopyCollectionsFromPasteboard:pboard]) {
		return NO;
	}
	
	id<GLAArrayEditing> collectionListEditing = (self.project.collectionsEditing);
	
	NSIndexSet *sourceRowIndexes = (self.draggedRowIndexes);
	(self.draggedRowIndexes) = nil;
	
	NSDragOperation sourceOperation = (info.draggingSourceOperationMask);
	if (sourceOperation & NSDragOperationMove) {
		// The row index is the final destination, so reduce it by the number of rows being moved before it.
		row -= [sourceRowIndexes countOfIndexesInRange:NSMakeRange(0, row)];
		
		[collectionListEditing moveChildrenAtIndexes:sourceRowIndexes toIndex:row];
	}
	else if (sourceOperation & NSDragOperationCopy) {
		//TODO: actually make copies.
		NSArray *childrenToCopy = [collectionListEditing childrenAtIndexes:sourceRowIndexes];
		[collectionListEditing insertChildren:childrenToCopy atIndexes:[NSIndexSet indexSetWithIndex:row]];
	}
	else if (sourceOperation & NSDragOperationDelete) {
		[collectionListEditing removeChildrenAtIndexes:sourceRowIndexes];
	}
	else {
		return NO;
	}
	
	[self reloadCollections];
	
	return YES;
}

#pragma mark Table View Delegate

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView
{
	return NO;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	(cellView.canDrawSubviewsIntoLayer) = YES;
	
	GLACollection *collection = (self.collections)[row];
	NSString *title = (collection.title);
	(cellView.objectValue) = collection;
	(cellView.textField.stringValue) = title;
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	(cellView.textField.textColor) = [uiStyle colorForProjectItemColorIdentifier:(collection.colorIdentifier)];
	
	return cellView;
}

@end


#pragma mark -

@interface GLAProjectPlanViewController ()

@property(nonatomic) BOOL hasPreparedViews;

@property(nonatomic) GLAProject *private_project;
@property(nonatomic) BOOL private_editing;

@property(nonatomic) NSTableCellView *measuringTableCellView;

@end

@implementation GLAProjectPlanViewController
/*
- (NSTableView *)tableView
{
	return (id)(self.view);
}
*/
- (GLAProject *)project
{
	return (self.private_project);
}

- (void)setProject:(GLAProject *)project
{
	if ((self.private_project) != project) {
		(self.private_project) = project;
		
		[self prepareDummyContent];
	}
}

- (BOOL)editing
{
	return (self.private_editing);
}

- (void)setEditing:(BOOL)editing
{
	(self.private_editing) = editing;
	
	[self reloadReminders];
	
	NSView *editingActionsView = (self.editingActionsView);
	NSLayoutConstraint *actionsHeightConstraint = (self.actionsHeightConstraint);
	NSLayoutConstraint *scrollToActionsConstraint = (self.scrollToActionsConstraint);
	NSLayoutConstraint *actionsBottomConstraint = (self.actionsBottomConstraint);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 3.0 / 12.0;
		
		if (editing) {
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
			(editingActionsView.alphaValue) = 0.0;
			(editingActionsView.animator.alphaValue) = 1.0;
			(actionsHeightConstraint.animator.constant) = 70.0;
			(scrollToActionsConstraint.animator.constant) = 8.0;
			(actionsBottomConstraint.animator.constant) = 12.0;
		}
		else {
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
			(editingActionsView.animator.alphaValue) = 0.0;
			(actionsHeightConstraint.animator.constant) = 0.0;
			(scrollToActionsConstraint.animator.constant) = 0.0;
			(actionsBottomConstraint.animator.constant) = 0.0;
		}
		
		//[projectView layoutSubtreeIfNeeded];
	} completionHandler:^ {
		//(self.animatingFocusChange) = NO;
	}];
}

- (void)prepareDummyContent
{
	(self.mutableReminders) =
	[
	 @[
	   //[GLAReminder dummyReminderWithTitle:@"About page redesign blah blah blah blah longer name"],
	   [GLAReminder dummyReminderWithTitle:@"About page"],
	   [GLAReminder dummyReminderWithTitle:@"Straight to the point"],
	   [GLAReminder dummyReminderWithTitle:@"Prototyping landing page blah blah blah longer name oh so long long long long"],
	   [GLAReminder dummyReminderWithTitle:@"Brief Stage D completed blah blah blah longer name blah blah"],
	   [GLAReminder dummyReminderWithTitle:@"Brief Stage E completed blah blah blah longer name blah blah"],
	   [GLAReminder dummyReminderWithTitle:@"Brief Stage F completed blah blah blah longer name blah blah"],
	   ] mutableCopy];
	
	[self reloadReminders];
}

- (void)reloadReminders
{
	[(self.tableView) reloadData];
}

- (void)prepareViewsIfNeeded
{
	if (self.hasPreparedViews) {
		return;
	}
	
	NSTableView *tableView = (self.tableView);
	[[GLAUIStyle activeStyle] prepareContentTableView:tableView];
	
	NSScrollView *scrollView = (tableView.enclosingScrollView);
	// I think Apple says this is better for scrolling performance.
	(scrollView.wantsLayer) = YES;
	
	NSTableColumn *mainColumn = (tableView.tableColumns)[0];
	(self.measuringTableCellView) = [tableView makeViewWithIdentifier:(mainColumn.identifier) owner:nil];
	
	[self wrapScrollView];
	
	
	NSDateFormatter *dueDateFormatter = [NSDateFormatter new];
	(dueDateFormatter.timeStyle) = NSDateFormatterShortStyle;
	(dueDateFormatter.dateStyle) = NSDateFormatterMediumStyle;
	//(dueDateFormatter.doesRelativeDateFormatting) = YES;
	NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEE h:mm a" options:0 locale:[NSLocale autoupdatingCurrentLocale]];
	(dueDateFormatter.dateFormat) = dateFormat;
	(self.dueDateFormatter) = dueDateFormatter;
	
	
	GLAReminderManager *reminderManager = [GLAReminderManager sharedReminderManager];
	[reminderManager createEventStoreIfNeeded];
	
	(self.hasPreparedViews) = YES;
}

- (void)loadView
{
	[super loadView];
	
	//[self prepareViewsIfNeeded];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self prepareViewsIfNeeded];
	//[self prepareDummyContent];
}

- (void)wrapScrollView
{
	NSScrollView *scrollView = (self.tableView.enclosingScrollView);
	(scrollView.identifier) = @"tableScrollView";
	(scrollView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	GLAView *holderView = [[GLAView alloc] init];
	(holderView.identifier) = @"planListHolderView";
	(holderView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	GLAProjectViewController *projectViewController = (self.parentViewController);
	
	
	NSLayoutConstraint *planViewTrailingConstraint = (projectViewController.planViewTrailingConstraint);
	(planViewTrailingConstraint.identifier) = [GLAViewController layoutConstraintIdentifierWithBaseIdentifier:@"trailing" forChildView:scrollView];
	
	NSLayoutConstraint *planViewBottomConstraint = (projectViewController.planViewBottomConstraint);
	(planViewBottomConstraint.identifier) = [GLAViewController layoutConstraintIdentifierWithBaseIdentifier:@"bottom" forChildView:scrollView];
	
	
	[projectViewController wrapChildViewKeepingOutsideConstraints:scrollView withView:holderView];
	
	
	planViewTrailingConstraint = [projectViewController layoutConstraintWithIdentifier:(planViewTrailingConstraint.identifier)];
	(planViewTrailingConstraint.identifier) = [GLAViewController layoutConstraintIdentifierWithBaseIdentifier:@"trailing" forChildView:holderView];
	(projectViewController.planViewTrailingConstraint) = planViewTrailingConstraint;
	
	planViewBottomConstraint = [projectViewController layoutConstraintWithIdentifier:(planViewBottomConstraint.identifier)];
	(planViewBottomConstraint.identifier) = [GLAViewController layoutConstraintIdentifierWithBaseIdentifier:@"bottom" forChildView:holderView];
	(projectViewController.planViewBottomConstraint) = planViewBottomConstraint;
	
	
	(self.view) = holderView;
	
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeWidth withChildView:scrollView identifier:@"width"];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeTop withChildView:scrollView identifier:@"top"];
	(self.scrollLeadingConstraint) = [self addLayoutConstraintToMatchAttribute:NSLayoutAttributeLeading withChildView:scrollView identifier:@"leading"];
	
	[self setUpEditingActionsView];
}

- (void)setUpEditingActionsView
{
	GLAViewController *editingActionsViewController = [[GLAViewController alloc] init];
	NSView *editingActionsView = (self.editingActionsView);
	(editingActionsView.translatesAutoresizingMaskIntoConstraints) = NO;
	(editingActionsViewController.view) = editingActionsView;
	
	NSScrollView *scrollView = (self.tableView.enclosingScrollView);
	NSView *view = (self.view);
	
	NSLayoutConstraint *actionsHeightConstraint = [NSLayoutConstraint constraintWithItem:editingActionsView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.0];
	(actionsHeightConstraint.priority) = 999;
	
	NSLayoutConstraint *scrollToActionsConstraint = [NSLayoutConstraint constraintWithItem:editingActionsView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
	(scrollToActionsConstraint.priority) = 750;
	
	NSLayoutConstraint *actionsBottomConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:editingActionsView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
	(actionsBottomConstraint.priority) = 750;
	
	(self.actionsHeightConstraint) = actionsHeightConstraint;
	(self.scrollToActionsConstraint) = scrollToActionsConstraint;
	(self.actionsBottomConstraint) = actionsBottomConstraint;
	
	NSArray *constraints =
	@[
	  // Leading
	  [NSLayoutConstraint constraintWithItem:editingActionsView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
	  // Width
	  [NSLayoutConstraint constraintWithItem:editingActionsView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0],
	  scrollToActionsConstraint,
	  actionsBottomConstraint,
	  actionsHeightConstraint
	  ];
	
	[view addSubview:editingActionsView];
	[view addConstraints:constraints];
	//[view setNeedsLayout:YES];
}

- (IBAction)chooseExistingReminders:(id)sender
{
	[(self.parentViewController) chooseExistingReminders:sender];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.mutableReminders.count);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAReminder *reminderItem = (self.mutableReminders)[row];
	return (reminderItem.title);
}

#pragma mark Table View Delegate

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView
{
	return NO;
}

- (void)setUpTableCellView:(NSTableCellView *)cellView forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	(cellView.backgroundStyle) = NSBackgroundStyleDark;
	
	NSTextField *textField = (cellView.textField);
	
	GLAReminder *reminderItem = (self.mutableReminders)[row];
	NSString *title = (reminderItem.title);
	NSString *dividerText = @" \u00b7 ";
	NSString *dueDateText = @"";
	//NSString *dividerText = @" ";
	
	BOOL hasDueDate = (reminderItem.dueDateComponents) != nil;
	if (hasDueDate) {
		NSDateFormatter *dueDateFormatter = (self.dueDateFormatter);
		NSDateComponents *dateComponents = (reminderItem.dueDateComponents);
		dueDateText = [dueDateFormatter stringFromDate:(dateComponents.date)];
		NSLog(@"DUE DATE %@ %@; %@", dateComponents, (dateComponents.date), dueDateFormatter);
		//dueDateText = @"4PM today";
	}
	
	GLAUIStyle *activeStyle = [GLAUIStyle activeStyle];
	
	NSFont *titleFont = (activeStyle.smallReminderFont);
	NSFont *dueDateFont = (activeStyle.smallReminderDueDateFont);
	
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	(paragraphStyle.alignment) = NSRightTextAlignment;
	(paragraphStyle.maximumLineHeight) = 18.0;
	
	NSColor *textColor = (self.editing) ? (activeStyle.lightTextColor) : [activeStyle lightTextColorAtLevel:row];
	
	BOOL firstLineBigger = YES;
	
	if ((row == 0) && firstLineBigger) {
		titleFont = (activeStyle.highlightedReminderFont);
		dueDateFont = (activeStyle.highlightedReminderDueDateFont);
		(paragraphStyle.maximumLineHeight) = 21.0; //(font.pointSize);
		(paragraphStyle.lineSpacing) = 0.0;
	}
	
	NSDictionary *titleAttributes =
	@{
	  NSFontAttributeName: titleFont,
	  NSParagraphStyleAttributeName: paragraphStyle,
	  NSForegroundColorAttributeName: textColor
	  };
	
	NSDictionary *dueDateAttributes =
	@{
	  NSFontAttributeName: dueDateFont,
	  NSParagraphStyleAttributeName: paragraphStyle,
	  NSForegroundColorAttributeName: textColor
	  };
	
	NSMutableAttributedString *wholeAttrString = [NSMutableAttributedString new];
	if (hasDueDate) {
		// Due date
		NSRange dueDateRange = NSMakeRange((wholeAttrString.length), (dueDateText.length) + (dividerText.length));
		[(wholeAttrString.mutableString) appendString:dueDateText];
		[(wholeAttrString.mutableString) appendString:dividerText];
		[wholeAttrString setAttributes:dueDateAttributes range:dueDateRange];
	}
	
	// Title
	NSRange titleRange = NSMakeRange((wholeAttrString.length), (title.length));
	[(wholeAttrString.mutableString) appendString:title];
	[wholeAttrString setAttributes:titleAttributes range:titleRange];
	
	(textField.attributedStringValue) = wholeAttrString;
	
	//(textField.preferredMaxLayoutWidth) = (tableColumn.width);
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	NSTableCellView *cellView = (self.measuringTableCellView);
	[self setUpTableCellView:cellView forTableColumn:nil row:row];
	
	NSTableColumn *tableColumn = (tableView.tableColumns)[0];
	CGFloat cellWidth = (tableColumn.width);
	(cellView.frameSize) = NSMakeSize(cellWidth, 100.0);
	[cellView layoutSubtreeIfNeeded];
	
	NSTextField *textField = (cellView.textField);
	//(textField.preferredMaxLayoutWidth) = (tableColumn.width);
	(textField.preferredMaxLayoutWidth) = NSWidth(textField.bounds);
	NSLog(@"textField.intrinsicContentSize %@ %f %f", [textField valueForKey:@"intrinsicContentSize"], (textField.preferredMaxLayoutWidth), (tableColumn.width));
	
	CGFloat extraPadding = 8.0;
	
	return (textField.intrinsicContentSize.height) + extraPadding;

	/*
	if (row == 0) {
		return 2.0 * 21.0;
	}
	else {
		//return 2.0 * 18.0;
		return 2.0 * 21.0;
	}*/
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	(cellView.canDrawSubviewsIntoLayer) = YES;
	
	[self setUpTableCellView:cellView forTableColumn:tableColumn row:row];
	
	//(cellView.layer.backgroundColor) = [NSColor redColor].CGColor;
	
	return cellView;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	return [tableView makeViewWithIdentifier:NSTableViewRowViewKey owner:nil];
}

@end