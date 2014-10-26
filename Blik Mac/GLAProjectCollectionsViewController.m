//
//  GLAPrototypeBProjectViewController.m
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import QuartzCore;
#import "GLAProjectCollectionsViewController.h"
#import "GLAProjectViewController.h"
#import "GLAUIStyle.h"
#import "GLAProjectManager.h"
#import "GLAEditCollectionDetailsPopover.h"
#import <objc/runtime.h>


NSString *GLAProjectCollectionsViewControllerDidClickCollectionNotification = @"GLA.projectCollectionsViewController.didClickCollection";

@interface GLAProjectCollectionsViewController ()

@property(nonatomic) NSIndexSet *draggedRowIndexes;

- (IBAction)tableViewWasClicked:(id)sender;

@end

@implementation GLAProjectCollectionsViewController

- (void)dealloc
{
	[self stopProjectObserving];
}

@synthesize project = _project;

- (void)setProject:(GLAProject *)project
{
	if (_project == project) {
		return;
	}
	
	BOOL isSameProject = (_project != nil) && [(_project.UUID) isEqual:(project.UUID)];
	
	[self stopProjectObserving];
	
	_project = project;
	
	[self startProjectObserving];
		
	if (!isSameProject) {
		GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
		[projectManager loadCollectionsForProject:project];
	}
}

- (void)reloadCollections
{
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	NSArray *collections = [projectManager copyCollectionsForProject:(self.project)];
	
	if (!collections) {
		collections = @[];
	}
	(self.collections) = collections;
	
	[(self.tableView) reloadData];
}

- (void)prepareView
{
	[super prepareView];
	
	NSTableView *tableView = (self.tableView);
	[[GLAUIStyle activeStyle] prepareContentTableView:tableView];
	
	(tableView.target) = self;
	(tableView.action) = @selector(tableViewWasClicked:);
	
	(tableView.menu) = (self.contextualMenu);
	
	[tableView registerForDraggedTypes:@[GLACollectionJSONPasteboardType]];
	
	// I think Apple (from a WWDC video) says this is better for scrolling performance.
	(tableView.enclosingScrollView.wantsLayer) = YES;
	
	[self wrapScrollView];
	[self setUpEditingActionsView];
	
	//(tableView.draggingDestinationFeedbackStyle) = NSTableViewDraggingDestinationFeedbackStyleGap;
}

- (void)startProjectObserving
{
	GLAProject *project = (self.project);
	if (!project) {
		return;
	}
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Project Collection List
	[nc addObserver:self selector:@selector(projectCollectionsDidChangeNotification:) name:GLAProjectCollectionsDidChangeNotification object:[pm notificationObjectForProject:project]];
}

- (void)stopProjectObserving
{
	GLAProject *project = (self.project);
	if (!project) {
		return;
	}
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Stop observing any notifications on the project manager.
	[nc removeObserver:self name:nil object:[pm notificationObjectForProject:project]];
}

- (void)wrapScrollView
{
	// Wrap the plan scroll view with a holder view
	// to allow constraints to be more easily worked with
	// and enable an actions view to be added underneath.
	
	NSScrollView *scrollView = (self.tableView.enclosingScrollView);
	(scrollView.identifier) = @"tableScrollView";
	(scrollView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	GLAView *holderView = [GLAView new];
	(holderView.identifier) = @"collectionListHolderView";
	(holderView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	GLAProjectViewController *projectViewController = (self.parentViewController);
	NSLayoutConstraint *itemsViewLeadingConstraint = (projectViewController.itemsViewLeadingConstraint);
	NSLayoutConstraint *itemsViewBottomConstraint = (projectViewController.itemsViewBottomConstraint);
	
	[projectViewController wrapChildViewKeepingOutsideConstraints:scrollView withView:holderView constraintVisitor:^ (NSLayoutConstraint *oldConstraint, NSLayoutConstraint *newConstraint) {
		if (oldConstraint == itemsViewLeadingConstraint) {
			(newConstraint.identifier) = [GLAViewController layoutConstraintIdentifierWithBaseIdentifier:@"leading" forChildView:holderView];
			(projectViewController.itemsViewLeadingConstraint) = newConstraint;
		}
		else if (oldConstraint == itemsViewBottomConstraint) {
			(newConstraint.identifier) = [GLAViewController layoutConstraintIdentifierWithBaseIdentifier:@"bottom" forChildView:holderView];
			(projectViewController.itemsViewBottomConstraint) = newConstraint;
		}
	}];
	
	(self.view) = holderView;
	
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeWidth withChildView:scrollView identifier:@"width"];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeTop withChildView:scrollView identifier:@"top"];
	//(self.scrollLeadingConstraint) = [self addLayoutConstraintToMatchAttribute:NSLayoutAttributeLeading withChildView:scrollView identifier:@"leading"];
}

- (void)setUpEditingActionsView
{
	GLATableActionsViewController *editingActionsViewController = [GLATableActionsViewController new];
	(self.editingActionsViewController) = editingActionsViewController;
	
	NSView *editingActionsView = (self.editingActionsView);
	(editingActionsView.identifier) = @"collectionsEditingActions";
	(editingActionsView.translatesAutoresizingMaskIntoConstraints) = NO;
	(editingActionsViewController.view) = editingActionsView;
	
	NSScrollView *scrollView = (self.tableView.enclosingScrollView);
	NSView *view = (self.view);
	
	[editingActionsViewController addInsideView:view underRelativeToView:scrollView];
	[editingActionsViewController addBottomConstraintToView:view];
}

@synthesize editing = _editing;

- (void)setEditing:(BOOL)editing
{
	if (_editing == editing) {
		return;
	}
	
	_editing = editing;
	
	//[self reloadReminders];
	
	GLATableActionsViewController *editingActionsViewController = (self.editingActionsViewController);
	NSView *editingActionsView = (editingActionsViewController.view);
	NSLayoutConstraint *actionsHeightConstraint = (editingActionsViewController.heightConstraint);
	NSLayoutConstraint *scrollToActionsConstraint = (editingActionsViewController.topConstraint);
	NSLayoutConstraint *actionsBottomConstraint = (editingActionsViewController.bottomConstraint);
	
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

#pragma mark -

- (void)changeName:(NSString *)name forCollection:(GLACollection *)collection
{
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	[projectManager renameCollection:collection inProject:(self.project) toString:name];
	
	[self reloadCollections];
}

- (void)changeColor:(GLACollectionColor *)color forCollection:(GLACollection *)collection
{NSLog(@"CHANGE COLOR FROM VC");
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	[projectManager changeColorOfCollection:collection inProject:(self.project) toColor:color];
	
	[self reloadCollections];
}

#pragma mark -

- (GLAEditCollectionDetailsPopover *)editCollectionPopover
{
	return [GLAEditCollectionDetailsPopover sharedEditCollectionDetailsPopover];
}

- (void)editCollectionDetailsPopoverChosenNameDidChangeNotification:(NSNotification *)note
{
	GLAEditCollectionDetailsPopover *popover = (note.object);
	NSString *name = (popover.chosenName);
	[self changeName:name forCollection:(self.collectionWithDetailsBeingEdited)];
}

- (void)editCollectionDetailsPopoverChosenColorDidChangeNotification:(NSNotification *)note
{NSLog(@"editCollectionDetailsPopoverChosenColorDidChangeNotification");
	GLAEditCollectionDetailsPopover *popover = (note.object);
	GLACollectionColor *color = (popover.chosenCollectionColor);
	[self changeColor:color forCollection:(self.collectionWithDetailsBeingEdited)];
}

- (void)editCollectionDetailsPopupDidCloseNotification:(NSNotification *)note
{NSLog(@"EC DID CLOSE");
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:nil object:(self.editCollectionPopover)];
	
	(self.collectionWithDetailsBeingEdited) = nil;
}

- (void)editDetailsOfCollection:(GLACollection *)collection atRow:(NSInteger)collectionRow
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

#pragma mark -

- (GLACollectionColorPickerPopover *)colorPickerPopover
{
	return [GLACollectionColorPickerPopover sharedColorPickerPopover];
}

- (void)collectionColorPickerPopoverChosenColorDidChangeNotification:(NSNotification *)note
{
	GLACollectionColorPickerPopover *popover = (note.object);
	GLACollectionColor *color = (popover.chosenCollectionColor);
	[self changeColor:color forCollection:(self.collectionWithDetailsBeingEdited)];
}

- (void)collectionColorPickerPopupDidCloseNotification:(NSNotification *)note
{NSLog(@"COLOR POPUP CLOSE");
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:nil object:(self.colorPickerPopover)];
	
	(self.collectionWithDetailsBeingEdited) = nil;
}

- (void)chooseColorForCollection:(GLACollection *)collection atRow:(NSInteger)collectionRow
{
	(self.collectionWithDetailsBeingEdited) = collection;
	
	GLACollectionColorPickerPopover *colorPickerPopover = (self.colorPickerPopover);
	
	if (colorPickerPopover.isShown) {
		[colorPickerPopover close];
		(self.collectionWithDetailsBeingEdited) = nil;
	}
	else {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(collectionColorPickerPopoverChosenColorDidChangeNotification:) name:GLACollectionColorPickerPopoverChosenColorDidChangeNotification object:colorPickerPopover];
		[nc addObserver:self selector:@selector(collectionColorPickerPopupDidCloseNotification:) name:NSPopoverDidCloseNotification object:colorPickerPopover];
		
		(colorPickerPopover.chosenCollectionColor) = (collection.color);
		
		NSTableView *tableView = (self.tableView);
		NSRect rowRect = [tableView rectOfRow:collectionRow];
		// Show underneath.
		[colorPickerPopover showRelativeToRect:rowRect ofView:tableView preferredEdge:NSMaxYEdge];
	}
}

#pragma mark Notifications

- (void)projectCollectionsDidChangeNotification:(NSNotification *)note
{
	[self reloadCollections];
}

#pragma mark Actions

- (IBAction)tableViewWasClicked:(id)sender
{
	NSInteger clickedRow = (self.tableView.clickedRow);
	if (clickedRow == -1) {
		return;
	}
	
	GLACollection *collection = (self.collections)[clickedRow];
	
	if (self.editing) {
		[self chooseColorForCollection:collection atRow:clickedRow];
	}
	else {
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectCollectionsViewControllerDidClickCollectionNotification object:self userInfo:
		 @{
		   @"row": @(clickedRow),
		   @"collection": collection
		   }];
	}
}

- (GLACollection *)clickedCollection
{
	NSTableView *tableView = (self.tableView);
	NSInteger clickedRow = (tableView.clickedRow);
	if (clickedRow == -1) {
		return nil;
	}
	
	return (self.collections)[clickedRow];
}

- (IBAction)permanentlyDeleteClickedCollection:(id)sender
{
	GLACollection *collection = (self.clickedCollection);
	if (!collection) {
		return;
	}
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	NSAlert *alert = [NSAlert new];
	[alert addButtonWithTitle:NSLocalizedString(@"Delete", @"Button title to delete collection.")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Button title to cancel deleting collection.")];
	(alert.messageText) = NSLocalizedString(@"Delete the collection?", @"Message for deleting a collection.");
	(alert.informativeText) = NSLocalizedString(@"The collection will permanently deleted and not able to be restored.", @"Informative text for deleting a collection.");
	(alert.alertStyle) = NSWarningAlertStyle;
	
	[alert beginSheetModalForWindow:(self.view.window) completionHandler:^(NSModalResponse returnCode) {
		if (returnCode == NSAlertFirstButtonReturn) {
			[projectManager permanentlyDeleteCollection:collection fromProject:(self.project)];
		}
	}];
}

- (IBAction)renameClickedCollection:(id)sender
{
	NSInteger clickedRow = (self.tableView.clickedRow);
	if (clickedRow == -1) {
		return;
	}
	
	GLACollection *collection = (self.collections)[clickedRow];
	
	[self editDetailsOfCollection:collection atRow:clickedRow];
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
		GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
		
		[projectManager editProjectCollections:(self.project) usingBlock:^(id<GLAArrayEditing> collectionsEditor) {
			NSIndexSet *sourceRowIndexes = (self.draggedRowIndexes);
			(self.draggedRowIndexes) = nil;
			
			[collectionsEditor removeChildrenAtIndexes:sourceRowIndexes];
		}];
		
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
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	__block BOOL acceptDrop = YES;
	NSIndexSet *sourceRowIndexes = (self.draggedRowIndexes);
	(self.draggedRowIndexes) = nil;
	
	[projectManager editProjectCollections:(self.project) usingBlock:^(id<GLAArrayEditing> collectionsEditor) {
		NSDragOperation sourceOperation = (info.draggingSourceOperationMask);
		if (sourceOperation & NSDragOperationMove) {
			// The row index is the final destination, so reduce it by the number of rows being moved before it.
			NSInteger adjustedRow = row - [sourceRowIndexes countOfIndexesInRange:NSMakeRange(0, row)];
			
			[collectionsEditor moveChildrenAtIndexes:sourceRowIndexes toIndex:adjustedRow];
		}
		else if (sourceOperation & NSDragOperationCopy) {
			//TODO: actually make copies.
			NSArray *childrenToCopy = [collectionsEditor childrenAtIndexes:sourceRowIndexes];
			[collectionsEditor insertChildren:childrenToCopy atIndexes:[NSIndexSet indexSetWithIndex:row]];
		}
		else if (sourceOperation & NSDragOperationDelete) {
			[collectionsEditor removeChildrenAtIndexes:sourceRowIndexes];
		}
		else {
			acceptDrop = NO;
		}
	}];
	
	[self reloadCollections];
	
	return acceptDrop;
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
	NSString *title = (collection.name);
	(cellView.objectValue) = collection;
	(cellView.textField.stringValue) = title;
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	(cellView.textField.textColor) = [uiStyle colorForCollectionColor:(collection.color)];
	
	return cellView;
}

@end
