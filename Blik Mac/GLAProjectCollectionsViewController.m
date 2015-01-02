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
#import "GLAAddCollectedFilesChoicePopover.h"
#import "GLAArrayTableDraggingHelper.h"
#import "GLAPendingAddedCollectedFilesInfo.h"
#import <objc/runtime.h>


NSString *GLAProjectCollectionsViewControllerDidClickCollectionNotification = @"GLA.projectCollectionsViewController.didClickCollection";

@interface GLAProjectCollectionsViewController () <GLAArrayTableDraggingHelperDelegate>

@property(nonatomic) GLAArrayTableDraggingHelper *tableDraggingHelper;

- (IBAction)tableViewWasClicked:(id)sender;

@end

@interface GLAProjectCollectionsViewController (GLAAddCollectedFilesChoice)

- (GLAAddCollectedFilesChoicePopover *)addCollectedFilesChoicePopup;
- (void)showAddCollectedFilesChoiceForFileURLs:(NSArray *)fileURLs;

@end

@implementation GLAProjectCollectionsViewController

- (void)dealloc
{
	[self stopProjectObserving];
}

- (void)prepareView
{
	[super prepareView];
	
	NSTableView *tableView = (self.tableView);
	[[GLAUIStyle activeStyle] prepareContentTableView:tableView];
	
	(tableView.target) = self;
	(tableView.action) = @selector(tableViewWasClicked:);
	
	(tableView.menu) = (self.contextualMenu);
	
	[tableView registerForDraggedTypes:
  @[
	[GLACollection objectJSONPasteboardType],
	(__bridge NSString *)kUTTypeFileURL
	]];
	
	// I think Apple (from a WWDC video) says this is better for scrolling performance.
	(tableView.enclosingScrollView.wantsLayer) = YES;
	
	[self wrapScrollView];
	//[self setUpEditingActionsView];
	
	(self.tableDraggingHelper) = [[GLAArrayTableDraggingHelper alloc] initWithDelegate:self];
	
	//(tableView.draggingDestinationFeedbackStyle) = NSTableViewDraggingDestinationFeedbackStyleGap;
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
		[projectManager loadCollectionsForProjectIfNeeded:project];
		
		[self reloadCollections];
	}
}

- (void)wrapScrollView
{
	// Wrap the plan scroll view with a holder view
	// to allow constraints to be more easily worked with
	// and enable an actions view to be added underneath.
	
	NSScrollView *scrollView = (self.tableView.enclosingScrollView);
	(scrollView.identifier) = @"tableScrollView";
	
	[self fillViewWithChildView:scrollView];
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

- (void)showInstructions
{
	NSView *instructionsView = (self.instructionsViewController.view);
	if (!(instructionsView.superview)) {
		[self fillViewWithChildView:instructionsView];
#if 0
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 3.0 / 120.0;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
			
			(instructionsView.alphaValue) = 0.0;
			(instructionsView.animator.alphaValue) = 1.0;
		} completionHandler:nil];
#endif
	}
	else {
		(instructionsView.hidden) = NO;
	}
}

- (void)hideInstructions
{
	NSView *instructionsView = (self.instructionsViewController.view);
	if ((instructionsView.superview)) {
		(instructionsView.hidden) = YES;
	}
}

- (void)showTable
{
	(self.tableView.enclosingScrollView.hidden) = NO;
}

- (void)hideTable
{
	(self.tableView.enclosingScrollView.hidden) = YES;
}

- (void)reloadCollections
{
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	NSArray *collections = [projectManager copyCollectionsForProject:(self.project)];
	
	if (!collections) {
		collections = @[];
	}
	(self.collections) = collections;
	
	if ((collections.count) > 0) {
		[self showTable];
		[self hideInstructions];
		
		[(self.tableView) reloadData];
	}
	else {
		[self showInstructions];
		[self hideTable];
	}
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
{
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
{
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
	(alert.informativeText) = NSLocalizedString(@"If you wish to restore the collection and its contents you must do so manually.", @"Informative text for deleting a collection.");
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

#pragma mark - Table Dragging Helper Delegate

- (BOOL)arrayEditorTableDraggingHelper:(GLAArrayTableDraggingHelper *)tableDraggingHelper canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard
{
	return [GLACollection canCopyObjectsFromPasteboard:draggingPasteboard];
}

- (void)arrayEditorTableDraggingHelper:(GLAArrayTableDraggingHelper *)tableDraggingHelper makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock
{
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	[projectManager editCollectionsOfProject:(self.project) usingBlock:editBlock];
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
	return [(self.tableDraggingHelper) tableView:tableView draggingSession:session willBeginAtPoint:screenPoint forRowIndexes:rowIndexes];
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	return [(self.tableDraggingHelper) tableView:tableView draggingSession:session endedAtPoint:screenPoint operation:operation];
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pboard = (info.draggingPasteboard);
	if ([pboard availableTypeFromArray:@[(__bridge NSString *)kUTTypeFileURL]] != nil) {
		//[tableView setDropRow:(tableView.numberOfRows) dropOperation:NSTableViewDropAbove];
		
		return NSDragOperationLink;
	}
	
	return [(self.tableDraggingHelper) tableView:tableView validateDrop:info proposedRow:row proposedDropOperation:dropOperation];
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pboard = (info.draggingPasteboard);
	if ([pboard availableTypeFromArray:@[(__bridge NSString *)kUTTypeFileURL]] != nil) {
		NSArray *fileURLs = [pboard readObjectsForClasses:@[ [NSURL class] ] options:@{ NSPasteboardURLReadingFileURLsOnlyKey: @(YES) }];
		if (fileURLs) {
			if (dropOperation == NSTableViewDropAbove) {
				[self showAddCollectedFilesChoiceForFileURLs:fileURLs];
			}
			else if (dropOperation == NSTableViewDropOn) {
				GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
				GLACollection *collection = (self.collections)[row];
				NSArray *collectedFiles = [GLACollectedFile collectedFilesWithFileURLs:fileURLs];
				[pm editFilesListOfCollection:collection addingCollectedFiles:collectedFiles queueIfNeedsLoading:YES];
			}
			
			return YES;
		}
		else {
			return NO;
		}
	}
	
	return [(self.tableDraggingHelper) tableView:tableView acceptDrop:info row:row dropOperation:dropOperation];
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


@implementation GLAProjectCollectionsViewController (GLAAddCollectedFilesChoice)

- (GLAAddCollectedFilesChoicePopover *)addCollectedFilesChoicePopup
{
	return [GLAAddCollectedFilesChoicePopover sharedAddCollectedFilesChoicePopover];
}

- (void)showAddCollectedFilesChoiceForFileURLs:(NSArray *)fileURLs
{
	GLAAddCollectedFilesChoicePopover *popover = (self.addCollectedFilesChoicePopup);
	
	if (popover.isShown) {
		[popover close];
	}
	
	GLAPendingAddedCollectedFilesInfo *info = [[GLAPendingAddedCollectedFilesInfo alloc] initWithFileURLs:fileURLs];
	(popover.info) = info;
	(popover.actionsDelegate) = (self.addCollectedFilesChoiceActionsDelegate);
	
	NSScrollView *scrollView = (self.tableView.enclosingScrollView);
	[popover showRelativeToRect:NSZeroRect ofView:scrollView preferredEdge:NSMaxXEdge];
}

@end
