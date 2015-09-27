//
//  GLAChooseFoldersViewController.m
//  Blik
//
//  Created by Patrick Smith on 6/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAChooseFoldersViewController.h"
#import "GLACollectedFile.h"
#import "GLAProjectManager.h"
#import "GLAUIStyle.h"
#import "NSTableView+GLAActionHelpers.h"


@implementation GLAChooseFoldersViewController

- (void)prepareView
{
	(self.foldersListHelper) = [[GLACollectedFileListHelper alloc] initWithDelegate:self];
	
	(self.tableDraggingHelper) = [[GLAArrayTableDraggingHelper alloc] initWithDelegate:self];
	
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	[style prepareTextLabel:(self.mainLabel)];
	
	NSTableView *foldersTableView = (self.foldersTableView);
	(foldersTableView.dataSource) = self;
	(foldersTableView.delegate) = self;
	(foldersTableView.menu) = (self.foldersTableMenu);
	[style prepareContentTableView:foldersTableView];
	
	// Allow dragging inside as well as file URLs from the outside.
	[foldersTableView registerForDraggedTypes:@[[GLACollectedFile objectJSONPasteboardType], (__bridge NSString *)kUTTypeFileURL]];
	
	NSScrollView *foldersScrollView = (self.foldersTableView.enclosingScrollView);
	[(self.mainHolderViewController) fillViewWithChildView:foldersScrollView];
	
	[self reloadFolders];
}

- (void)showInstructions
{
	NSView *instructionsView = (self.instructionsViewController.view);
	if (!(instructionsView.superview)) {
		(instructionsView.wantsLayer) = YES;
		[self fillViewWithChildView:instructionsView];
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
	NSScrollView *foldersScrollView = (self.foldersTableView.enclosingScrollView);
	
	(foldersScrollView.wantsLayer) = YES;
	(foldersScrollView.alphaValue) = 1.0;
}

- (void)hideTable
{
	NSScrollView *foldersScrollView = (self.foldersTableView.enclosingScrollView);
	
	//(foldersScrollView.hidden) = YES;
	(foldersScrollView.alphaValue) = 0.0;
}

#pragma mark -

- (BOOL)canViewFolders
{
	return NO; // Needs subclassing
}

- (BOOL)hasLoadedFolders
{
	return NO; // Needs subclassing
}

- (NSArray *)copyFolders
{
	return @[]; // Needs subclassing
}

- (void)makeChangesToFoldersUsingEditingBlock:(GLAArrayEditingBlock)editingBlock
{
	// Needs subclassing
}

- (BOOL)tableHasDarkBackground
{
	return YES;
}

#pragma mark -

- (void)reloadFolders
{
	NSArray *collectedFolders = nil;
	
	if (self.canViewFolders) {
		BOOL hasLoaded = (self.hasLoadedFolders);
		(self.addFoldersButton.enabled) = hasLoaded;
		
		collectedFolders = [self copyFolders];
	}
	else {
		collectedFolders = @[];
		
		(self.addFoldersButton.enabled) = NO;
	}
	
	(self.collectedFolders) = collectedFolders;
	(self.foldersListHelper.collectedFiles) = collectedFolders;
	
	[(self.foldersTableView) reloadData];
	
	if ((collectedFolders.count) > 0) {
		[self showTable];
		[self hideInstructions];
	}
	else {
		[self showInstructions];
		[self hideTable];
	}
}

#pragma mark -

- (void)insertFolderURLs:(NSArray *)folderURLs atOptionalIndex:(NSUInteger)index
{
	NSArray *collectedFoldersToAdd = [GLACollectedFile collectedFilesWithFileURLs:folderURLs];
	
	[self makeChangesToFoldersUsingEditingBlock:^(id<GLAArrayEditing> foldersListEditor) {
		NSArray *filteredFolders = [GLACollectedFile filteredCollectedFiles:collectedFoldersToAdd notAlreadyPresentInArrayInspector:foldersListEditor];
		if ((filteredFolders.count) == 0) {
			return;
		}
		
		if (index == NSNotFound) {
			[foldersListEditor addChildren:filteredFolders];
		}
		else {
			NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, (filteredFolders.count))];
			[foldersListEditor insertChildren:filteredFolders atIndexes:indexes];
		}
	}];
}

- (void)addFolderURLs:(NSArray *)folderURLs
{
	[self insertFolderURLs:folderURLs atOptionalIndex:NSNotFound];
}

- (void)removeFoldersAtIndexes:(NSIndexSet *)indexes
{
	[self makeChangesToFoldersUsingEditingBlock:^(id<GLAArrayEditing> foldersListEditor) {
		[foldersListEditor removeChildrenAtIndexes:indexes];
	}];
}

#pragma mark Actions

- (IBAction)addFolder:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	(openPanel.canChooseFiles) = NO;
	(openPanel.canChooseDirectories) = YES;
	(openPanel.allowsMultipleSelection) = YES;
	
	NSString *chooseString = NSLocalizedString(@"Choose", @"NSOpenPanel button for choosing folder to add to master folders list.");
	(openPanel.title) = chooseString;
	(openPanel.prompt) = chooseString;
	
	[openPanel beginWithCompletionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			NSArray *fileURLs = (openPanel.URLs);
			[self addFolderURLs:fileURLs];
		}
	}];
}

- (IBAction)revealSelectedFoldersInFinder:(id)sender
{
	NSTableView *foldersTableView = (self.foldersTableView);
	NSIndexSet *indexes = [foldersTableView gla_rowIndexesForActionFrom:sender];
	NSArray *collectedFiles = [(self.collectedFolders) objectsAtIndexes:indexes];
	NSArray *fileURLs = [GLACollectedFile filePathsURLsForCollectedFiles:collectedFiles ignoreMissing:NO];
	
	if ((fileURLs.count) > 0) {
		[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
	}
	else {
		NSBeep();
	}
}

- (IBAction)removeSelectedFoldersFromList:(id)sender
{
	NSTableView *foldersTableView = (self.foldersTableView);
	NSIndexSet *indexes = [foldersTableView gla_rowIndexesForActionFrom:sender];
	if ((indexes.count) == 0) {
		return;
	}
	
	[self removeFoldersAtIndexes:indexes];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSArray *collectedFolders = (self.collectedFolders);
	if (collectedFolders) {
		return (collectedFolders.count);
	}
	else {
		return 0;
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSArray *collectedFolders = (self.collectedFolders);
	GLACollectedFile *collectedFile = collectedFolders[row];
	
	return collectedFile;
}

#pragma mark Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	
	GLACollectedFile *collectedFile = (self.collectedFolders)[row];
	(cellView.objectValue) = collectedFile;
	
	[(self.foldersListHelper) setUpTableCellView:cellView forTableColumn:tableColumn collectedFile:collectedFile];
	
	BOOL tableHasDarkBackground = (self.tableHasDarkBackground);
	if (tableHasDarkBackground) {
		GLAUIStyle *style = [GLAUIStyle activeStyle];
		[style prepareTableTextLabel:(cellView.textField)];
	}
	
	return cellView;
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
	GLACollectedFile *collectedFile = (self.collectedFolders)[row];
	return collectedFile;
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes
{
	[(self.tableDraggingHelper) tableView:tableView draggingSession:session willBeginAtPoint:screenPoint forRowIndexes:rowIndexes];
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	[(self.tableDraggingHelper) tableView:tableView draggingSession:session endedAtPoint:screenPoint operation:operation];
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	if (dropOperation == NSTableViewDropOn) {
		[tableView setDropRow:row dropOperation:NSTableViewDropAbove];
	}
	
	NSPasteboard *pboard = (info.draggingPasteboard);
	
	if ([pboard availableTypeFromArray:@[[GLACollectedFile objectJSONPasteboardType]]] != nil) {
		return [(self.tableDraggingHelper) tableView:tableView validateDrop:info proposedRow:row proposedDropOperation:dropOperation];
	}
	// canReadObjectForClasses
	else if ([pboard availableTypeFromArray:@[(__bridge NSString *)kUTTypeFileURL]] != nil) {
		return NSDragOperationLink;
	}
	
	return NO;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pboard = (info.draggingPasteboard);
	
	if ([pboard availableTypeFromArray:@[[GLACollectedFile objectJSONPasteboardType]]] != nil) {
		return [(self.tableDraggingHelper) tableView:tableView acceptDrop:info row:row dropOperation:dropOperation];
	}
	else if ([pboard availableTypeFromArray:@[(__bridge NSString *)kUTTypeFileURL]] != nil) {
		NSDictionary *pasteboardReadingOptions =
		@{
		  NSPasteboardURLReadingFileURLsOnlyKey: @(YES),
		  NSPasteboardURLReadingContentsConformToTypesKey: @[(id)kUTTypeFolder]
		  }
		;
		NSArray *folderURLs = [pboard readObjectsForClasses:@[ [NSURL class] ] options:pasteboardReadingOptions];
		if (folderURLs) {
			[self insertFolderURLs:folderURLs atOptionalIndex:row];
			return YES;
		}
		else {
			return NO;
		}
	}
	
	return NO;
}

#pragma mark -

- (void)collectedFileListHelperDidInvalidate:(GLACollectedFileListHelper *)helper
{
	[(self.foldersTableView) reloadData];
}

- (void)collectedFileListHelper:(GLACollectedFileListHelper *)helper didLoadInfoForCollectedFilesAtIndexes:(NSIndexSet *)indexes
{
	[(self.foldersTableView) reloadDataForRowIndexes:indexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

#pragma mark -

- (BOOL)arrayEditorTableDraggingHelper:(GLAArrayTableDraggingHelper *)tableDraggingHelper canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard
{
	return [GLACollectedFile canCopyObjectsFromPasteboard:draggingPasteboard];
}

- (void)arrayEditorTableDraggingHelper:(GLAArrayTableDraggingHelper *)tableDraggingHelper makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock
{
	[self makeChangesToFoldersUsingEditingBlock:editBlock];
}

@end
