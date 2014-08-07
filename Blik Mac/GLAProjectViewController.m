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
#import "GLAChooseRemindersMainViewController.h"


NSString *GLAProjectViewControllerDidBeginEditingItemsNotification = @"GLA.projectViewController.didBeginEditingItems";
NSString *GLAProjectViewControllerDidEndEditingItemsNotification = @"GLA.projectViewController.didEndEditingItems";

NSString *GLAProjectViewControllerDidBeginEditingPlanNotification = @"GLA.projectViewController.didBeginEditingPlan";
NSString *GLAProjectViewControllerDidEndEditingPlanNotification = @"GLA.projectViewController.didEndEditingPlan";

NSString *GLAProjectViewControllerDidEnterCollectionNotification = @"GLA.projectViewController.didEnterCollection";


@interface GLAProjectViewController ()

@property(nonatomic) GLAProject *private_project;

@property(nonatomic) BOOL focusedOnItemsView;
@property(nonatomic) BOOL focusedOnPlanView;

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
	
	(self.projectView.delegate) = self;
	
	[nc addObserver:self selector:@selector(collectionsViewControllerDidClickCollection:) name:GLAProjectCollectionsViewControllerDidClickCollectionNotification object:(self.itemsViewController)];
	
	//(self.itemsViewController.parentViewController) = self;
	//(self.planViewController.parentViewController) = self;
	
	/*
	NSTextField *nameTextField = (self.nameTextField);
	(nameTextField.delegate) = self;
	
	[nc addObserver:self selector:@selector(nameTextDidBeginEditing:) name:NSControlTextDidBeginEditingNotification object:nameTextField];
	[nc addObserver:self selector:@selector(nameTextDidEndEditing:) name:NSControlTextDidEndEditingNotification object:nameTextField];
	*/
	(self.itemsViewLeadingConstraintDefaultConstant) = (self.itemsViewLeadingConstraint.constant);
	(self.itemsViewHeightConstraintDefaultConstant) = (self.itemsViewHeightConstraint.constant);
	
	(self.planViewTrailingConstraintDefaultConstant) = (self.planViewTrailingConstraint.constant);
	(self.planViewHeightConstraintDefaultConstant) = (self.planViewHeightConstraint.constant);
	
	GLAView *actionsBarView = (self.actionsBarController.view);
	(actionsBarView.wantsLayer) = YES;
	(actionsBarView.layer.backgroundColor) = ([GLAUIStyle activeStyle].contentBackgroundColor.CGColor);
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	[(self.itemsScrollView.contentView) scrollToPoint:NSZeroPoint];
	[(self.planScrollView.contentView) scrollToPoint:NSZeroPoint];
}

- (GLAProject *)project
{
	return (self.private_project);
}

- (void)setProject:(GLAProject *)project
{
	if ((self.private_project) != project) {
		(self.private_project) = project;
		
		(self.itemsViewController.project) = project;
		(self.planViewController.project) = project;
		
		(self.nameTextField.stringValue) = (project.name);
		
		
	}
}

- (void)collectionsViewControllerDidClickCollection:(NSNotification *)note
{
	if (self.focusedOnItemsView) {
		return;
	}
	
	GLACollection *collection = (note.userInfo)[@"collection"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectViewControllerDidEnterCollectionNotification object:self userInfo:
	 @{
	   @"collection": collection
	   }];
}

#pragma mark Actions

- (IBAction)editItems:(id)sender
{
	if (self.animatingFocusChange) {
		return;
	}
	
	if (!(self.focusedOnItemsView)) {
		[self focusOnItemsView];
		[(self.actionsBarController) showBarForEditingItems];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectViewControllerDidBeginEditingItemsNotification object:self];
	}
	else {
		[self endFocusingOnItemsView];
		[(self.actionsBarController) hideBarForEditingItems];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectViewControllerDidEndEditingItemsNotification object:self];
	}
}

- (IBAction)editPlan:(id)sender
{
	if (self.animatingFocusChange) {
		return;
	}
	
	if (!(self.focusedOnPlanView)) {
		[self focusOnPlanView];
		[(self.actionsBarController) showBarForEditingPlan];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectViewControllerDidBeginEditingPlanNotification object:self];
	}
	else {
		[self endFocusingOnPlanView];
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

- (NSScrollView *)itemsScrollView
{
	return (self.itemsViewController.tableView.enclosingScrollView);
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

- (void)animateItemsViewForFocusChange:(BOOL)isFocused
{
	(self.animatingFocusChange) = YES;
	
	GLAProjectView *projectView = (self.projectView);
	NSScrollView *itemsScrollView = [self itemsScrollView];
	NSScrollView *planScrollView = [self planScrollView];
	
	if (isFocused) {
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
		
		
		[self didBeginEditingInnerSection];
	}
	else {
		// Remove centering constraint
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 6.0 / 12.0;
			(context.allowsImplicitAnimation) = YES;
			
			[projectView removeConstraint:(self.itemsViewXConstraint)];
			
			[projectView layoutSubtreeIfNeeded];
		} completionHandler:^ {
			(self.animatingFocusChange) = NO;
			
			[self didFinishEditingInnerSection];
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

- (void)animatePlanViewForFocusChange:(BOOL)isFocused
{
	(self.animatingFocusChange) = YES;
	
	GLAProjectView *projectView = (self.projectView);
	NSScrollView *itemsScrollView = [self itemsScrollView];
	NSScrollView *planScrollView = [self planScrollView];
	
	if (isFocused) {
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

- (void)didBeginEditingInnerSection
{
	NSTextField *nameTextField = (self.nameTextField);
	(nameTextField.editable) = NO;
	[(nameTextField.window) makeFirstResponder:nil];
}

- (void)didFinishEditingInnerSection
{
	NSTextField *nameTextField = (self.nameTextField);
	(nameTextField.editable) = YES;
}

- (void)focusOnItemsView
{
	(self.focusedOnItemsView) = YES;
	(self.focusedOnPlanView) = NO;
	
	(self.itemsViewController.editing) = YES;
	
	[self animateItemsViewForFocusChange:YES];
}

- (void)endFocusingOnItemsView
{
	(self.focusedOnItemsView) = NO;
	
	(self.itemsViewController.editing) = NO;
	
	[self animateItemsViewForFocusChange:NO];
}

- (void)focusOnPlanView
{
	(self.focusedOnItemsView) = NO;
	(self.focusedOnPlanView) = YES;
	
	(self.planViewController.editing) = YES;
	
	[self animatePlanViewForFocusChange:YES];
	//[self updateConstraintsWithAnimatedDuration:7.0 / 12.0];
	
	GLAReminderManager *reminderManager = [GLAReminderManager sharedReminderManager];
	if (!(reminderManager.isAuthorized)) {
		[reminderManager requestAccessToReminders:^(BOOL granted, NSError *error) {
			BOOL hasNoAccess = !granted;
			
			(self.planViewController.showsDoesNotHaveAccessToReminders) = hasNoAccess;
		}];
	}
	else {
		CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
		[reminderManager useAllReminders:^(NSArray *allReminders) {
			CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
			NSLog(@"Took %f second to get all reminders", endTime - startTime);
			//NSLog(@"%lu %@", (allReminders.count), allReminders);
		}];
	}
}

- (void)endFocusingOnPlanView
{
	(self.focusedOnPlanView) = NO;
	
	(self.planViewController.editing) = NO;
	
	[self animatePlanViewForFocusChange:NO];
	//[self updateConstraintsWithAnimatedDuration:7.0 / 12.0];
}

- (IBAction)chooseExistingReminders:(id)sender
{
	if (!(self.chooseRemindersMainViewController)) {
		GLAChooseRemindersMainViewController *chooseRemindersMainViewController = [[GLAChooseRemindersMainViewController alloc] initWithNibName:@"GLAChooseRemindersMainViewController" bundle:nil];
		
		(chooseRemindersMainViewController.view.identifier) = @"chooseRemindersMainView";
		(chooseRemindersMainViewController.view.wantsLayer) = YES;
		(self.chooseRemindersMainViewController) = chooseRemindersMainViewController;
	}
	
	//NSLayoutConstraint *scrollLeadingConstraint = (self.planViewController.scrollLeadingConstraint);
	GLAProjectView *projectView = (self.projectView);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 6.0 / 12.0;
		(context.allowsImplicitAnimation) = YES;
		
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		[projectView removeConstraint:(self.planViewXConstraint)];
		(self.planViewTrailingConstraint.constant) = 500;
		(self.nameTextField.alphaValue) = 0.0;
		
		[projectView layoutSubtreeIfNeeded];
		
	} completionHandler:^ {
		(self.nameTextField.hidden) = YES;
	}];
	
	GLAChooseRemindersMainViewController *chooseRemindersMainViewController = (self.chooseRemindersMainViewController);
	[chooseRemindersMainViewController viewWillAppear];
	
	NSView *chooseRemindersMainView = (chooseRemindersMainViewController.view);
	[self fillViewWithChildView:chooseRemindersMainView];
	
	NSLog(@"%@", [(self.view.constraints) valueForKey:@"identifier"]);
	
	NSLayoutConstraint *planViewBottomConstraint = (self.planViewBottomConstraint);
	NSArray *adjustedConstraints = [GLAViewController copyLayoutConstraints:@[planViewBottomConstraint] replacingUsesOf:(self.planViewController.view) with:chooseRemindersMainView];
	NSLayoutConstraint *newBottomConstraint = adjustedConstraints[0];
	(newBottomConstraint.identifier) = [GLAViewController layoutConstraintIdentifierWithBaseIdentifier:@"bottom" forChildView:chooseRemindersMainView];
	[projectView removeConstraint:[self layoutConstraintWithIdentifier:@"height" forChildView:chooseRemindersMainView]];
	[projectView addConstraint:newBottomConstraint];
	
	NSLog(@"newBottomConstraint %@", newBottomConstraint);
	
	[chooseRemindersMainViewController viewDidAppear];
	
	[chooseRemindersMainViewController showRemindersTable];
}

- (NSLayoutConstraint *)addConstraintForCenteringView:(NSView *)view inView:(NSView *)holderView
{
	return [self addLayoutConstraintToMatchAttribute:NSLayoutAttributeCenterX withChildView:view identifier:@"centerX" priority:999];
	
	NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:holderView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
	[holderView addConstraint:constraint];
	
	return constraint;
}

/*
- (void)nameTextDidBeginEditing:(NSNotification *)obj
{
	NSLog(@"nameTextDidBeginEditing:");
	NSTextField *nameTextField = (self.nameTextField);
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	(nameTextField.textColor) = (uiStyle.editedTextColor);
	(nameTextField.backgroundColor) = (uiStyle.editedTextBackgroundColor);
}

- (void)nameTextDidEndEditing:(NSNotification *)obj
{
	
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	NSLog(@"%@", NSStringFromSelector(command));
	return NO;
}
*/
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
	   [GLAReminder dummyReminderWithTitle:@"About page redesign blah blah blah blah longer name"],
	   [GLAReminder dummyReminderWithTitle:@"Double check Muted Light logo and gallery sliders"],
	   [GLAReminder dummyReminderWithTitle:@"Prototyping landing page blah blah blah longer name blah blah"],
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
	
	[self wrapScrollView];
	
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

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	(cellView.canDrawSubviewsIntoLayer) = YES;
	
	GLAReminder *reminderItem = (self.mutableReminders)[row];
	NSString *title = (reminderItem.title);
	NSString *middleDot = @"\u00b7";
	NSString *displayText = [NSString stringWithFormat:@"4PM Today %@ %@", middleDot, title];
	//NSString *displayText = @"dfs";
	//(cellView.objectValue) = displayText;
	//(cellView.textField.stringValue) = displayText;
	
	GLAUIStyle *activeStyle = [GLAUIStyle activeStyle];
	
	NSFont *font;
	NSColor *textColor;
	
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	(paragraphStyle.alignment) = NSRightTextAlignment;
	
	if (row == 0) {
		font = (activeStyle.highlightedReminderFont);
		(paragraphStyle.maximumLineHeight) = 21.0; //(font.pointSize);
		(paragraphStyle.lineSpacing) = 0.0;
		textColor = (activeStyle.lightTextColor);
	}
	else {
		font = (activeStyle.smallReminderFont);
		(paragraphStyle.maximumLineHeight) = 18.0; //(font.pointSize);
		
		if (self.editing) {
			textColor = (activeStyle.lightTextColor);
		}
		else {
			textColor = (activeStyle.lightTextSecondaryColor);
		}
	}
	
	NSDictionary *attributes =
  @{
	NSFontAttributeName: font,
	NSParagraphStyleAttributeName: paragraphStyle,
	NSForegroundColorAttributeName: textColor
	};
	(cellView.textField.attributedStringValue) = [[NSMutableAttributedString alloc] initWithString:displayText attributes:attributes];
	//(cellView.textField.font) = font;
	
	(cellView.textField.preferredMaxLayoutWidth) = (tableColumn.width);
	
	return cellView;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	/*
	NSTableCellView *cellView = [tableView viewAtColumn:0 row:row makeIfNecessary:YES];
	NSTextField *textField = (cellView.textField);
	return (textField.intrinsicContentSize.height);
	 */
	
	if (row == 0) {
		return 2.0 * 21.0;
	}
	else {
		//return 2.0 * 18.0;
		return 2.0 * 21.0;
	}
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	return [tableView makeViewWithIdentifier:NSTableViewRowViewKey owner:nil];
}

@end