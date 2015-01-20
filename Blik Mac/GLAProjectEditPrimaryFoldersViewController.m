//
//  GLAProjectEditPrimaryFoldersViewController.m
//  Blik
//
//  Created by Patrick Smith on 17/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAProjectEditPrimaryFoldersViewController.h"
#import "GLACollectedFile.h"
#import "GLAProjectManager.h"
#import "GLAUIStyle.h"
#import "NSTableView+GLAActionHelpers.h"


@interface GLAProjectEditPrimaryFoldersViewController () <NSTableViewDataSource, NSTableViewDelegate, GLACollectedFileListHelperDelegate, GLAArrayTableDraggingHelperDelegate>

@property(nonatomic) NSArray *collectedFolders;

@end

@implementation GLAProjectEditPrimaryFoldersViewController

- (void)prepareView
{
	(self.collectedFilesSetting) = [GLACollectedFilesSetting new];
	
	(self.primaryCollectedFoldersListHelper) = [[GLACollectedFileListHelper alloc] initWithDelegate:self];
	
	(self.tableDraggingHelper) = [[GLAArrayTableDraggingHelper alloc] initWithDelegate:self];
	
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	[style prepareTextLabel:(self.mainLabel)];
	
	NSTableView *primaryFoldersTableView = (self.primaryFoldersTableView);
	(primaryFoldersTableView.dataSource) = self;
	(primaryFoldersTableView.delegate) = self;
	(primaryFoldersTableView.menu) = (self.primaryFoldersTableMenu);
	[style prepareContentTableView:primaryFoldersTableView];
	
	[primaryFoldersTableView registerForDraggedTypes:@[[GLACollectedFile objectJSONPasteboardType], (__bridge NSString *)kUTTypeFileURL]];
	
	NSScrollView *primaryFoldersScrollView = (self.primaryFoldersTableView.enclosingScrollView);
	[(self.mainHolderViewController) fillViewWithChildView:primaryFoldersScrollView];
	
	(self.addFoldersButton.enabled) = NO;
}

#pragma mark -

- (GLAProjectManager *)projectManager
{
	return [GLAProjectManager sharedProjectManager];
}

- (void)startProjectObserving
{
	GLAProject *project = (self.project);
	if (!project) {
		return;
	}
	
	GLAProjectManager *pm = (self.projectManager);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	id projectNotifier = [pm notificationObjectForProject:project];
	[nc addObserver:self selector:@selector(primaryFoldersDidChangeNotification:) name:GLAProjectPrimaryFoldersDidChangeNotification object:projectNotifier];
}

- (void)stopProjectObserving
{
	GLAProject *project = (self.project);
	if (!project) {
		return;
	}
	
	GLAProjectManager *pm = (self.projectManager);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Stop observing any notifications on the project manager.
	[nc removeObserver:self name:nil object:[pm notificationObjectForProject:project]];
}

@synthesize project = _project;

- (void)setProject:(GLAProject *)project
{
	if (_project == project) {
		return;
	}
	
	[self stopProjectObserving];
	
	_project = project;
	
	[self startProjectObserving];
	
	[self reloadPrimaryFolders];
}

- (void)showInstructions
{
#if 0
	NSView *instructionsView = (self.instructionsViewController.view);
	if (!(instructionsView.superview)) {
		[self fillViewWithChildView:instructionsView];
	}
	else {
		(instructionsView.hidden) = NO;
	}
#endif
}

- (void)hideInstructions
{
#if 0
	NSView *instructionsView = (self.instructionsViewController.view);
	if ((instructionsView.superview)) {
		(instructionsView.hidden) = YES;
	}
#endif
}

- (void)showTable
{
	NSScrollView *primaryFoldersScrollView = (self.primaryFoldersTableView.enclosingScrollView);
	
	(primaryFoldersScrollView.alphaValue) = 1.0;
}

- (void)hideTable
{
	(self.primaryFoldersTableView.enclosingScrollView.alphaValue) = 0.0;
}

- (void)reloadPrimaryFolders
{
	NSArray *collectedFolders = nil;
	
	GLAProject *project = (self.project);
	if (project) {
		GLAProjectManager *pm = (self.projectManager);
		[pm loadPrimaryFoldersForProjectIfNeeded:project];
		collectedFolders = [pm copyPrimaryFoldersForProject:project];
		
		GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
		[collectedFilesSetting startUsingURLsForCollectedFilesRemovingRemainders:collectedFolders];
	}
	else {
		collectedFolders = @[];
	}
	
	(self.collectedFolders) = collectedFolders;
	(self.primaryCollectedFoldersListHelper.collectedFiles) = collectedFolders;
	
	[(self.primaryFoldersTableView) reloadData];
	
	if ((collectedFolders.count) > 0) {
		[self showTable];
		[self hideInstructions];
	}
	else {
		[self showInstructions];
		[self hideTable];
	}
}

#pragma mark - Model Notifications

- (void)primaryFoldersDidChangeNotification:(NSNotification *)note
{
	(self.addFoldersButton.enabled) = YES;
	
	[self reloadPrimaryFolders];
}

#pragma mark -

- (void)insertFolderURLs:(NSArray *)folderURLs atOptionalIndex:(NSUInteger)index
{
	NSArray *collectedFoldersToAdd = [GLACollectedFile collectedFilesWithFileURLs:folderURLs];
	
	GLAProject *project = (self.project);
	
	GLAProjectManager *pm = (self.projectManager);
	[pm editPrimaryFoldersOfProject:project usingBlock:^(id<GLAArrayEditing> collectedFoldersListEditor) {
		if (index == NSNotFound) {
			[collectedFoldersListEditor addChildren:collectedFoldersToAdd];
		}
		else {
			NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, (folderURLs.count))];
			[collectedFoldersListEditor insertChildren:collectedFoldersToAdd atIndexes:indexes];
		}
	}];
	
	[self reloadPrimaryFolders];
}

- (void)addFolderURLs:(NSArray *)folderURLs
{
	[self insertFolderURLs:folderURLs atOptionalIndex:NSNotFound];
}

- (IBAction)addFolder:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	(openPanel.canChooseFiles) = NO;
	(openPanel.canChooseDirectories) = YES;
	(openPanel.allowsMultipleSelection) = YES;
	
	NSString *chooseString = NSLocalizedString(@"Choose", @"NSOpenPanel button for choosing folder to add to primary folders list.");
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
	NSTableView *primaryFoldersTableView = (self.primaryFoldersTableView);
	NSIndexSet *indexes = [primaryFoldersTableView gla_rowIndexesForActionFrom:sender];
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
	NSTableView *primaryFoldersTableView = (self.primaryFoldersTableView);
	NSIndexSet *indexes = [primaryFoldersTableView gla_rowIndexesForActionFrom:sender];
	if ((indexes.count) == 0) {
		return;
	}
	
	GLAProject *project = (self.project);
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	
	[pm editPrimaryFoldersOfProject:project usingBlock:^(id<GLAArrayEditing> collectedFoldersListEditor) {
		[collectedFoldersListEditor removeChildrenAtIndexes:indexes];
	}];
	
	[self reloadPrimaryFolders];
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
	
	//GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	//[collectedFilesSetting startUsingURLForCollectedFile:collectedFile];
	
	return collectedFile;
}

#pragma mark Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	
	[(self.primaryCollectedFoldersListHelper) setUpTableCellView:cellView forTableColumn:tableColumn row:row];
	
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
	
	// canReadObjectForClasses
	if ([pboard availableTypeFromArray:@[(__bridge NSString *)kUTTypeFileURL]] != nil) {
		return NSDragOperationLink;
	}
	
	return [(self.tableDraggingHelper) tableView:tableView validateDrop:info proposedRow:row proposedDropOperation:dropOperation];
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pboard = (info.draggingPasteboard);
	
	if ([pboard availableTypeFromArray:@[(__bridge NSString *)kUTTypeFileURL]] != nil) {
		NSArray *folderURLs = [pboard readObjectsForClasses:@[ [NSURL class] ] options:
							 @{
							   NSPasteboardURLReadingFileURLsOnlyKey: @(YES),
							   NSPasteboardURLReadingContentsConformToTypesKey: @[(id)kUTTypeFolder]
							   }];
		if (folderURLs) {
			[self insertFolderURLs:folderURLs atOptionalIndex:row];
			return YES;
		}
		else {
			return NO;
		}
	}
	
	return [(self.tableDraggingHelper) tableView:tableView acceptDrop:info row:row dropOperation:dropOperation];
}

#pragma mark -

- (void)collectedFileListHelper:(GLACollectedFileListHelper *)helper didLoadInfoForCollectedFilesAtIndexes:(NSIndexSet *)indexes
{
	[(self.primaryFoldersTableView) reloadDataForRowIndexes:indexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

#pragma mark -

- (BOOL)arrayEditorTableDraggingHelper:(GLAArrayTableDraggingHelper *)tableDraggingHelper canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard
{
	return [GLACollectedFile canCopyObjectsFromPasteboard:draggingPasteboard];
}

- (void)arrayEditorTableDraggingHelper:(GLAArrayTableDraggingHelper *)tableDraggingHelper makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock
{
	GLAProject *project = (self.project);
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	
	[pm editPrimaryFoldersOfProject:project usingBlock:editBlock];
	
	[self reloadPrimaryFolders];
}

@end
