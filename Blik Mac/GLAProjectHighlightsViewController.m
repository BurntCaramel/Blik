//
//  GLAProjectHighlightsViewController.m
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAProjectHighlightsViewController.h"
#import "GLAProjectManager.h"
#import "GLAUIStyle.h"


@interface GLAProjectHighlightsViewController ()

@property(nonatomic) NSIndexSet *draggedRowIndexes;

@end

@implementation GLAProjectHighlightsViewController

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	NSTableView *tableView = (self.tableView);
	[uiStyle prepareContentTableView:tableView];
	
	NSScrollView *scrollView = (tableView.enclosingScrollView);
	// I think Apple says this is better for scrolling performance.
	(scrollView.wantsLayer) = YES;
}

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
	
	BOOL isSameProject = (_project != nil) && (project != nil) && [(_project.UUID) isEqual:(project.UUID)];
	
	[self stopProjectObserving];
	
	_project = project;
	
	[self startProjectObserving];
	
	if (!isSameProject) {
		GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
		[projectManager loadHighlightsForProject:project];
	}
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
	[nc addObserver:self selector:@selector(projectHighlightsDidChangeNotification:) name:GLAProjectHighlightsDidChangeNotification object:[pm notificationObjectForProject:project]];
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

- (void)reloadHighlightedItems
{
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	NSArray *highlightedItems = [projectManager copyHighlightsForProject:(self.project)];
	
	if (!highlightedItems) {
		highlightedItems = @[];
	}
	(self.highlightedItems) = highlightedItems;
	
	[(self.tableView) reloadData];
}

- (void)projectHighlightsDidChangeNotification:(NSNotification *)note
{
	[self reloadHighlightedItems];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.highlightedItems.count);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAHighlightedItem *highlightedItem = (self.highlightedItems)[row];
	return highlightedItem;
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
	GLAHighlightedItem *highlightedItem = (self.highlightedItems)[row];
	return highlightedItem;
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
		
		[self reloadHighlightedItems];
	}
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	//NSLog(@"proposed row %ld %ld", (long)row, (long)dropOperation);
	
	NSPasteboard *pboard = (info.draggingPasteboard);
	if (![GLAHighlightedItem canCopyObjectsFromPasteboard:pboard]) {
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
	if (![GLAHighlightedItem canCopyObjectsFromPasteboard:pboard]) {
		return NO;
	}
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	__block BOOL acceptDrop = YES;
	NSIndexSet *sourceRowIndexes = (self.draggedRowIndexes);
	(self.draggedRowIndexes) = nil;
	
	[projectManager editHighlightsOfProject:(self.project) usingBlock:^(id<GLAArrayEditing> collectionsEditor) {
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
	
	[self reloadHighlightedItems];
	
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
	
	GLAHighlightedItem *highlightedItem = (self.highlightedItems)[row];
	NSString *name;
	
	if ([highlightedItem isKindOfClass:[GLAHighlightedCollection class]]) {
		GLAHighlightedCollection *highlightedCollection = (GLAHighlightedCollection *)highlightedItem;
		GLACollection *collection = (highlightedCollection.collection);
		name = (collection.name);
	}
	else if ([highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
		GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
		GLACollectedFile *collectedFile = (highlightedCollectedFile.collectedFile);
		NSLog(@"%@ NAME %@", collectedFile, (collectedFile.name));
		name = (collectedFile.name);
	}
	else {
		NSAssert(NO, @"highlightedItem not a valid class.");
	}
	
	NSLog(@"HIGHLIGHTED ITEM %@", highlightedItem);
	
	(cellView.objectValue) = highlightedItem;
	
	if (name) {
		(cellView.textField.stringValue) = name;
	}
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	(cellView.textField.textColor) = (uiStyle.lightTextColor);
	//(cellView.textField.textColor) = [uiStyle colorForCollectionColor:(collection.color)];
	
	return cellView;
}

@end
