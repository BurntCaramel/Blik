//
//  GLAProjectHighlightsViewController.m
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAProjectHighlightsViewController.h"
#import "Blik-Swift.h"
@import BurntFoundation;
// VIEW
#import "GLAProjectViewController.h"
#import "GLAUIStyle.h"
#import "GLAView.h"
#import "GLAHighlightsTableCellView.h"
#import "GLAArrayTableDraggingHelper.h"
// MODEL
#import "GLAProjectManager.h"
#import "GLAProjectManager+GLAOpeningFiles.h"
#import "GLACollectedFileListHelper.h"
#import "GLAFileOpenerApplicationFinder.h"
#import "GLACollectedFileMenuCreator.h"


@interface GLAProjectHighlightsViewController () <GLACollectedFileListHelperDelegate, GLAArrayTableDraggingHelperDelegate>

@property(nonatomic) NSMenu *contextualMenu;

@property(nonatomic) BOOL doNotUpdateViews;

@property(nonatomic) GLACollectedFileListHelper *fileListHelper;

@property(nonatomic) id<GLALoadableArrayUsing> highlightedItemsUser;
@property(nonatomic) NSArray *highlightedItems;

@property(nonatomic) id<GLALoadableArrayUsing> collectionsUser;
@property(nonatomic) NSArray *collections;
@property(nonatomic) NSArray *collectionsToGroupInHighlights;

@property(nonatomic) id<GLALoadableArrayUsing> primaryFoldersUser;
@property(nonatomic) NSArray *primaryFolders;

@property(nonatomic) GLAHighlightsTableCellView *measuringTableCellView;

@property(nonatomic) GLAArrayTableDraggingHelper *tableDraggingHelper;

@property(nonatomic) GLACollectedFileMenuCreator *collectedFileMenuCreator;

@property(nonatomic) GLAHighlightedItem *itemWithDetailsBeingEdited;

@end

@implementation GLAProjectHighlightsViewController

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	NSTableView *tableView = (self.tableView);
	[uiStyle prepareContentTableView:tableView];
	
	NSMenu *contextualMenu = [NSMenu new];
	(contextualMenu.delegate) = self;
	(self.contextualMenu) = contextualMenu;
	(tableView.menu) = contextualMenu;
	
	[tableView registerForDraggedTypes:@[[GLAHighlightedCollectedFile objectJSONPasteboardType]]];
	
	NSScrollView *scrollView = (tableView.enclosingScrollView);
	// I think Apple says this is better for scrolling performance.
	(scrollView.wantsLayer) = YES;
	
	NSTableColumn *mainColumn = (tableView.tableColumns)[0];
	(self.measuringTableCellView) = [tableView makeViewWithIdentifier:(mainColumn.identifier) owner:nil];
	
	[self prepareScrollView];
	
	(self.tableDraggingHelper) = [[GLAArrayTableDraggingHelper alloc] initWithDelegate:self];
	
	[self setUpFileHelpersIfNeeded];
}

- (void)prepareScrollView
{
	// Wrap the plan scroll view with a holder view
	// to allow constraints to be more easily worked with
	// and enable an actions view to be added underneath.
	
	NSScrollView *scrollView = (self.tableView.enclosingScrollView);
	(scrollView.identifier) = @"tableScrollView";
	
	[self fillViewWithChildView:scrollView];
}

- (void)setUpFileHelpersIfNeeded
{
	if (self.fileListHelper) {
		return;
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	(self.fileListHelper) = [[GLACollectedFileListHelper alloc] initWithDelegate:self];
	
	GLACollectedFileMenuCreator *collectedFileMenuCreator = [GLACollectedFileMenuCreator new];
	[nc addObserver:self selector:@selector(collectedFileMenuCreatorNeedsUpdateNotification:) name:GLACollectedFileMenuCreatorNeedsUpdateNotification object:collectedFileMenuCreator];
	_collectedFileMenuCreator = collectedFileMenuCreator;
}

- (void)dealloc
{
}

- (GLAProjectManager *)projectManager
{
	return [GLAProjectManager sharedProjectManager];
}

@synthesize project = _project;

- (void)setProject:(GLAProject *)project
{
	if (_project == project) {
		return;
	}
	
	BOOL isSameProject = (_project != nil) && (project != nil) && [(_project.UUID) isEqual:(project.UUID)];
	
	_project = project;
	
	[self setUpFileHelpersIfNeeded];
	(self.fileListHelper.project) = project;
	
	if (!isSameProject) {
		(self.highlightedItemsUser) = nil;
		(self.primaryFoldersUser) = nil;
		
		[self reloadItems];
	}
}

- (void)startCollectionObserving
{
	GLAProjectManager *pm = (self.projectManager);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	NSMutableSet *collectionUUIDs = [NSMutableSet new];
	
	for (GLAHighlightedItem *highlightedItem in (self.highlightedItems)) {
		NSUUID *collectionUUID = nil;
		
		if ([highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
			GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
			collectionUUID = (highlightedCollectedFile.holdingCollectionUUID);
		}
		
		if (!collectionUUID) {
			continue;
		}
		
		[collectionUUIDs addObject:collectionUUID];
	}
	
	for (NSUUID *collectionUUID in collectionUUIDs) {
		[nc addObserver:self selector:@selector(collectionOrCollectionsListDidChangeNotification:) name:GLACollectionDidChangeNotification object:[pm notificationObjectForCollectionUUID:collectionUUID]];
		[nc addObserver:self selector:@selector(collectionOrCollectionsListDidChangeNotification:) name:GLACollectionFilesListDidChangeNotification object:[pm notificationObjectForCollectionUUID:collectionUUID]];
	}
	
	[nc addObserver:self selector:@selector(collectionOrCollectionsListDidChangeNotification:) name:GLAProjectCollectionsDidChangeNotification object:[pm notificationObjectForProjectUUID:(self.project.UUID)]];
}

- (void)stopCollectionObserving
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:GLACollectionDidChangeNotification object:nil];
	[nc removeObserver:self name:GLACollectionFilesListDidChangeNotification object:nil];
	[nc removeObserver:self name:GLAProjectCollectionsDidChangeNotification object:nil];
}

#pragma mark -

- (void)showInstructions
{
	NSView *instructionsView = (self.instructionsViewController.view);
	if (!(instructionsView.superview)) {
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
	(self.tableView.enclosingScrollView.hidden) = NO;
}

- (void)hideTable
{
	(self.tableView.enclosingScrollView.hidden) = YES;
}

- (void)createLoadersIfNeeded
{
	GLAProject *project = (self.project);
	if (!project) {
		return;
	}
	
	GLAProjectManager *projectManager = (self.projectManager);
	
	id<GLALoadableArrayUsing> highlightedItemsUser = (self.highlightedItemsUser);
	if (!highlightedItemsUser) {
		highlightedItemsUser = [projectManager useHighlightsForProject:project];
		
		__weak GLAProjectHighlightsViewController *weakSelf = self;
		(highlightedItemsUser.changeCompletionBlock) = ^(id<GLAArrayInspecting> itemsInspector) {
			__strong GLAProjectHighlightsViewController *self = weakSelf;
			if (self) {
				[self reloadItems];
			}
		};
		
		(self.highlightedItemsUser) = highlightedItemsUser;
	}
	
	id<GLALoadableArrayUsing> collectionsUser = (self.collectionsUser);
	if (!collectionsUser) {
		collectionsUser = [projectManager useCollectionsForProject:project];
		
		__weak GLAProjectHighlightsViewController *weakSelf = self;
		(collectionsUser.changeCompletionBlock) = ^(id<GLAArrayInspecting> collectionsInspector) {
			__strong GLAProjectHighlightsViewController *self = weakSelf;
			if (self) {
				[self reloadItems];
			}
		};
		
		(self.collectionsUser) = collectionsUser;
	}
	
	id<GLALoadableArrayUsing> primaryFoldersUser = (self.primaryFoldersUser);
	if (!primaryFoldersUser) {
		primaryFoldersUser = [projectManager usePrimaryFoldersForProject:project];
		
		__weak GLAProjectHighlightsViewController *weakSelf = self;
		(primaryFoldersUser.changeCompletionBlock) = ^(id<GLAArrayInspecting> primaryFoldersInspector) {
			__strong GLAProjectHighlightsViewController *self = weakSelf;
			if (self) {
				[self reloadItems];
			}
		};
		
		(self.primaryFoldersUser) = primaryFoldersUser;
	}
}

- (void)reloadItems
{
	if (self.doNotUpdateViews) {
		return;
	}
	
	GLAProject *project = (self.project);
	if (!project) {
		return;
	}
	
	[self createLoadersIfNeeded];
	
	NSArray *highlightedItems = [(self.highlightedItemsUser) copyChildrenLoadingIfNeeded];
	NSArray *primaryFolders = [(self.primaryFoldersUser) copyChildrenLoadingIfNeeded];
	
	
	if (!highlightedItems) {
		highlightedItems = @[];
	}
	(self.highlightedItems) = highlightedItems;
	
	if (!primaryFolders) {
		primaryFolders = @[];
	}
	(self.primaryFolders) = primaryFolders;
	
	
	[self stopCollectionObserving];
	[self startCollectionObserving];
	
	if ((highlightedItems.count + primaryFolders.count) > 0) {
		[self showTable];
		[self hideInstructions];
		
		NSMutableArray *collectedFiles = [NSMutableArray new];
		for (GLAHighlightedItem *highlightedItem in highlightedItems) {
			GLACollectedFile *collectedFile = [self collectedFileForHighlightedItem:highlightedItem];
			if (collectedFile) {
				[collectedFiles addObject:collectedFile];
			}
		}
		
		[collectedFiles addObjectsFromArray:primaryFolders];
		
		(self.fileListHelper.collectedFiles) = collectedFiles;
		
		[(self.tableView) reloadData];
		
		(self.openAllHighlightsButton.enabled) = YES;
	}
	else {
		[self showInstructions];
		[self hideTable];
		
		(self.openAllHighlightsButton.enabled) = NO;
	}
}

#pragma mark -

- (void)collectionOrCollectionsListDidChangeNotification:(NSNotification *)note
{
	[self reloadItems];
}

- (void)viewWillTransitionIn
{
	[super viewWillTransitionIn];
	
	(self.doNotUpdateViews) = NO;
	
	[self reloadItems];
}

- (void)viewWillTransitionOut
{
	[super viewWillTransitionOut];
	
	(self.doNotUpdateViews) = YES;
	
	[self stopCollectionObserving];
}

#pragma mark -

- (id<NSObject>)objectAtRow:(NSInteger)row
{
	if (row == -1) {
		return nil;
	}
	
	NSArray *highlightedItems = (self.highlightedItems);
	if (row < (highlightedItems.count)) {
		return highlightedItems[row];
	}
	else {
		NSArray *primaryFolders = (self.primaryFolders);
		return primaryFolders[row - (highlightedItems.count)];
	}
}

- (id<NSObject>)clickedObject
{
	return [self objectAtRow:(self.tableView.clickedRow)];
}

- (GLAHighlightedItem *)clickedHighlightedItem
{
	NSTableView *tableView = (self.tableView);
	NSInteger clickedRow = (tableView.clickedRow);
	if (clickedRow == -1) {
		return nil;
	}
	
	NSArray *highlightedItems = (self.highlightedItems);
	if (clickedRow < (highlightedItems.count)) {
		return highlightedItems[clickedRow];
	}
	else {
		return nil;
	}
}

- (GLACollectedFile *)clickedCollectedPrimaryFolder
{
	NSTableView *tableView = (self.tableView);
	NSInteger clickedRow = (tableView.clickedRow);
	if (clickedRow == -1) {
		return nil;
	}
	
	NSArray *highlightedItems = (self.highlightedItems);
	if (clickedRow < (highlightedItems.count)) {
		return highlightedItems[clickedRow];
	}
	else {
		return nil;
	}
}

- (GLACollectedFile *)collectedFileForHighlightedItem:(GLAHighlightedItem *)highlightedItem
{
	if (![highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
		return nil;
	}
	
	GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
	
	GLAProjectManager *pm = (self.projectManager);
	GLACollectedFile *collectedFile = [pm collectedFileForHighlightedCollectedFile:highlightedCollectedFile loadIfNeeded:YES];
	
	return collectedFile;
}

- (NSURL *)fileURLForObject:(id<NSObject>)object
{
	GLACollectedFile *collectedFile = nil;
	
	if ([object isKindOfClass:[GLAHighlightedItem class]]) {
		collectedFile = [self collectedFileForHighlightedItem:(GLAHighlightedItem *)object];
	}
	else if ([object isKindOfClass:[GLACollectedFile class]]) {
		collectedFile = (GLACollectedFile *)object;
	}
	
	if (!collectedFile) {
		return nil;
	}
	
	GLACollectedFileListHelper *fileListHelper = (self.fileListHelper);
	id<GLAFileAccessing> accessedFile = [fileListHelper accessFileForCollectedFile:collectedFile];
	if (!accessedFile) {
		return nil;
	}
	
	return (accessedFile.filePathURL);
}

#pragma mark Actions

- (IBAction)removedClickedItem:(id)sender
{
	NSTableView *tableView = (self.tableView);
	GLAHighlightedItem *clickedItem = (self.clickedHighlightedItem);
	if (clickedItem) {
		NSInteger clickedRow = (tableView.clickedRow);
		GLAProjectManager *projectManager = (self.projectManager);
		
		[projectManager editHighlightsOfProject:(self.project) usingBlock:^(id<GLAArrayEditing> highlightsEditor) {
			[highlightsEditor removeChildrenAtIndexes:[NSIndexSet indexSetWithIndex:clickedRow]];
		}];
	}
}

- (void)fileAppearsToBeMissing
{
	NSBeep();
}

- (void)openObject:(id<NSObject>)object behaviour:(GLAOpenBehaviour)behaviour
{
	GLAProjectManager *pm = (self.projectManager);
	
	if ([object isKindOfClass:[GLAHighlightedCollectedFile class]]) {
		GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)object;
		[pm openHighlightedCollectedFile:highlightedCollectedFile behaviour:behaviour];
	}
	else if ([object isKindOfClass:[GLACollectedFile class]]) {
		GLACollectedFile *collectedFile = (GLACollectedFile *)object;
		[pm openCollectedFile:collectedFile behaviour:behaviour];
	}
}

- (void)openObject:(id<NSObject>)object
{
	GLAProjectManager *pm = (self.projectManager);
	
	[self openObject:object behaviour:[pm openBehaviourForModifierFlags:[NSEvent modifierFlags]]];
}

- (IBAction)openClickedItem:(id)sender
{
	id<NSObject> object = (self.clickedObject);
	
	[self openObject:object];
}

- (IBAction)openAllItems:(id)sender
{
	for (GLAHighlightedItem *highlightedItem in (self.highlightedItems)) {
		[self openObject:highlightedItem];
	}
}

- (IBAction)openWithChosenApplication:(NSMenuItem *)menuItem
{
	id representedObject = (menuItem.representedObject);
	if ((!representedObject) || ![representedObject isKindOfClass:[NSURL class]]) {
		return;
	}
	
	NSURL *applicationURL = representedObject;
	
	id<NSObject> object = (self.clickedObject);
	NSURL *fileURL = [self fileURLForObject:object];
	if (!fileURL) {
		return;
	}
	
	[GLAFileOpenerApplicationFinder openFileURLs:@[fileURL] withApplicationURL:applicationURL useSecurityScope:YES];
}

- (IBAction)changePreferredOpenerApplication:(NSMenuItem *)menuItem
{
	id representedObject = (menuItem.representedObject);
	if ((representedObject != nil) && ![representedObject isKindOfClass:[NSURL class]]) {
		return;
	}
	NSURL *applicationURL = representedObject;
	
	GLAHighlightedItem *highlightedItem = (self.clickedHighlightedItem);
	if (highlightedItem == nil || ![highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
		return;
	}
	GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
	
	GLAProjectManager *pm = (self.projectManager);
	[pm editHighlightedCollectedFile:highlightedCollectedFile usingBlock:^(id<GLAHighlightedCollectedFileEditing> editor) {
		if (applicationURL) {
			(editor.applicationToOpenFile) = [[GLACollectedFile alloc] initWithFileURL:applicationURL];
		}
		else {
			(editor.applicationToOpenFile) = nil;
		}
	}];
}

- (IBAction)showItemInFinder:(id)sender
{
	id<NSObject> object = (self.clickedObject);
	
	[self openObject:object behaviour:GLAOpenBehaviourShowInFinder];
}

- (IBAction)changeCustomNameOfClickedItem:(id)sender
{
	GLAHighlightedItem *highlightedItem = (self.clickedHighlightedItem);
	if (!highlightedItem) {
		return;
	}
	
	NSInteger clickedRow = (self.tableView.clickedRow);
	[self chooseCustomNameForHighlightedItem:highlightedItem atRow:clickedRow];
}

#pragma mark Notifications

- (void)collectedFileMenuCreatorNeedsUpdateNotification:(NSNotification *)note
{
	[self menuNeedsUpdate:(self.contextualMenu)];
}

#pragma mark Custom Name

- (void)changeCustomName:(NSString *)name forHighlightedItem:(GLAHighlightedItem *)highlightedItem
{
	name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	[projectManager editHighlightsOfProjectWithUUID:(self.project.UUID) usingBlock:^(id<GLAArrayEditing>  _Nonnull highlightsEditor) {
		[highlightsEditor replaceFirstChildWhoseKey:@"UUID" hasValue:(highlightedItem.UUID) usingChangeBlock:^GLAHighlightedItem * _Nonnull(GLAHighlightedItem *  _Nonnull originalItem) {
			return [originalItem copyWithChangesFromEditing:^(id<GLAHighlightedItemEditing> _Nonnull editor) {
				if ([name isEqualToString:@""]) {
					editor.customName = nil;
				}
				else {
					editor.customName = name;
				}
			}];
		}];
	}];
	
	//[self reloadCollections];
}

- (void)customNamePopoverChosenNameDidChangeNotification:(NSNotification *)note
{	
	HighlightCustomNamePopover *popover = (note.object);
	NSString *name = (popover.chosenCustomName);
	[self changeCustomName:name forHighlightedItem:(self.itemWithDetailsBeingEdited)];
}

- (void)customNamePopoverDidCloseNotification:(NSNotification *)note
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:nil object:[HighlightCustomNamePopover sharedPopover]];
	
	(self.itemWithDetailsBeingEdited) = nil;
}

- (void)chooseCustomNameForHighlightedItem:(GLAHighlightedItem *)highlightedItem atRow:(NSInteger)itemRow
{
	(self.itemWithDetailsBeingEdited) = highlightedItem;
	
	HighlightCustomNamePopover *popover = [HighlightCustomNamePopover sharedPopover];
	
	if (popover.isShown) {
		[popover close];
	}
	else {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(customNamePopoverChosenNameDidChangeNotification:) name:[HighlightCustomNamePopover CustomNameDidChangeNotification] object:popover];
		[nc addObserver:self selector:@selector(customNamePopoverDidCloseNotification:) name:NSPopoverDidCloseNotification object:popover];
		
		[popover setUpWithHighlightedItem:highlightedItem];
		
		NSTableView *tableView = (self.tableView);
		NSRect rowRect = [tableView rectOfRow:itemRow];
		// Show underneath.
		[popover showRelativeToRect:rowRect ofView:tableView preferredEdge:NSMaxYEdge];
	}
}

#pragma mark -

#pragma mark Collected File List Helper Delegate

- (void)collectedFileListHelperDidInvalidate:(GLACollectedFileListHelper *)helper
{
	[self reloadItems];
}

- (void)collectedFileListHelper:(GLACollectedFileListHelper *)helper didLoadInfoForCollectedFiles:(NSArray *)collectedFiles
{
	NSSet *collectedFileUUIDs = [NSSet setWithArray:[collectedFiles valueForKey:@"UUID"]];
	
	NSArray *highlightedItems = (self.highlightedItems);
	NSIndexSet *indexesToUpdate = [highlightedItems indexesOfObjectsPassingTest:^BOOL(GLAHighlightedItem *highlightedItem, NSUInteger idx, BOOL *stop) {
		if (![highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
			return NO;
		}
		
		GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
		NSUUID *collectedFileUUID = (highlightedCollectedFile.collectedFileUUID);
		return [collectedFileUUIDs containsObject:collectedFileUUID];
	}];
	
	NSArray *primaryFolders = (self.primaryFolders);
	if (indexesToUpdate.count == 0) {
		indexesToUpdate = [primaryFolders indexesOfObjectsPassingTest:^BOOL(GLACollectedFile *collectedFolder, NSUInteger idx, BOOL *stop) {
			return [collectedFileUUIDs containsObject:(collectedFolder.UUID)];
		}];
	}
	
	[(self.tableView) reloadDataForRowIndexes:indexesToUpdate columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

#pragma mark Table Dragging Helper Delegate

- (BOOL)arrayEditorTableDraggingHelper:(GLAArrayTableDraggingHelper *)tableDraggingHelper canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard
{
	return [GLAHighlightedCollectedFile canCopyObjectsFromPasteboard:draggingPasteboard];
}

- (void)arrayEditorTableDraggingHelper:(GLAArrayTableDraggingHelper *)tableDraggingHelper makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock
{
	[(self.highlightedItemsUser) editChildrenUsingBlock:editBlock];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSUInteger count = 0;
	
	count += (self.highlightedItems.count);
	count += (self.primaryFolders.count);
	
	return count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSArray *highlightedItems = (self.highlightedItems);
	NSArray *primaryFolders = (self.primaryFolders);
	
	if (row < (highlightedItems.count)) {
		GLAHighlightedItem *highlightedItem = highlightedItems[row];
		return highlightedItem;
	}
	else {
		GLACollectedFile *collectedFolder = primaryFolders[row - (highlightedItems.count)];
		return collectedFolder;
	}
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
	NSArray *highlightedItems = (self.highlightedItems);
	
	if (row < (highlightedItems.count)) {
		GLAHighlightedItem *highlightedItem = highlightedItems[row];
		return highlightedItem;
	}
	else {
		return nil;
	}
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
	NSUInteger highlightedItemsCount = (self.highlightedItems.count);
	
	// <= Less than or equal to allow dragging to bottom of highlighted items.
	if (row <= highlightedItemsCount) {
		return [(self.tableDraggingHelper) tableView:tableView validateDrop:info proposedRow:row proposedDropOperation:dropOperation];
	}
	else {
		return NSDragOperationNone;
	}
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	return [(self.tableDraggingHelper) tableView:tableView acceptDrop:info row:row dropOperation:dropOperation];
}

#pragma mark Table View Delegate

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView
{
	return NO;
}

- (void)setUpTableCellView:(GLAHighlightsTableCellView *)cellView forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAProjectManager *pm = (self.projectManager);
	NSArray *highlightedItems = (self.highlightedItems);
	NSArray *primaryFolders = (self.primaryFolders);
	GLACollectedFileListHelper *fileListHelper = (self.fileListHelper);
	GLACollectedFilesSetting *collectedFilesSetting = (fileListHelper.collectedFilesSetting);
	
	NSString *name = @"Loading…";
	
	(cellView.backgroundStyle) = NSBackgroundStyleDark;
	//(cellView.canDrawSubviewsIntoLayer) = YES;
	(cellView.alphaValue) = 1.0;
	
	if (row < (highlightedItems.count)) {
		GLAHighlightedItem *highlightedItem = highlightedItems[row];
		(cellView.objectValue) = highlightedItem;
		
		if ([highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
			GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
			
			GLACollectedFile *collectedFile = [self collectedFileForHighlightedItem:highlightedItem];
			BOOL isFolder = NO;
			
			if (collectedFile) {
				if (collectedFile.empty) {
					name = NSLocalizedString(@"(Gone)", @"Display name for empty collected file");
				}
				else {
					NSString *displayName = (highlightedItem.customName);
					if (!displayName) {
						displayName = [collectedFilesSetting copyValueForURLResourceKey:NSURLLocalizedNameKey forCollectedFile:collectedFile];
					}
					if (displayName) {
						name = displayName;
					}
					
					NSNumber *isDirectoryValue = [collectedFilesSetting copyValueForURLResourceKey:NSURLIsDirectoryKey forCollectedFile:collectedFile];
					NSNumber *isPackageValue = [collectedFilesSetting copyValueForURLResourceKey:NSURLIsPackageKey forCollectedFile:collectedFile];
					
					if (isDirectoryValue && isPackageValue) {
						isFolder = [@YES isEqual:isDirectoryValue] && [@NO isEqual:isPackageValue];
					}
				}
			}
			
			GLACollection *holdingCollection = [pm collectionForHighlightedCollectedFile:highlightedCollectedFile loadIfNeeded:YES];
			
			GLACollectionIndicationButton *collectionIndicationButton = (cellView.collectionIndicationButton);
			(collectionIndicationButton.collection) = holdingCollection;
			(collectionIndicationButton.isFolder) = isFolder;
			//(collectionIndicationButton.isFolder) = YES;
		}
		else {
			NSAssert(NO, @"highlightedItem not a valid class.");
		}
	}
	else {
		GLACollectedFile *collectedFolder = primaryFolders[row - (highlightedItems.count)];
		(cellView.objectValue) = collectedFolder;
		
		NSString *displayName = [collectedFilesSetting copyValueForURLResourceKey:NSURLLocalizedNameKey forCollectedFile:collectedFolder];
		if (displayName) {
			name = displayName;
		}
		
		GLACollectionIndicationButton *collectionIndicationButton = (cellView.collectionIndicationButton);
		(collectionIndicationButton.collection) = nil;
		(collectionIndicationButton.isFolder) = YES;
	}
	
	
	//name = [NSString stringWithFormat:@"%@ %@ %@", name, name, name];
	
	GLAUIStyle *activeStyle = [GLAUIStyle activeStyle];
	
	NSFont *titleFont = (activeStyle.smallReminderFont);
	
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	(paragraphStyle.alignment) = NSRightTextAlignment;
	(paragraphStyle.maximumLineHeight) = 18.0;
	
	NSColor *textColor = (activeStyle.lightTextColor);
	
	NSDictionary *titleAttributes =
	@{
	  NSFontAttributeName: titleFont,
	  NSParagraphStyleAttributeName: paragraphStyle,
	  NSForegroundColorAttributeName: textColor
	  };
	
	NSAttributedString *wholeAttrString = [[NSAttributedString alloc] initWithString:name attributes:titleAttributes];
	
	(cellView.textField.attributedStringValue) = wholeAttrString;
	
	(cellView.needsLayout) = YES;
	//(textField.preferredMaxLayoutWidth) = (tableColumn.width);
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	CGFloat height;
	@autoreleasepool {
		GLAHighlightsTableCellView *cellView = (self.measuringTableCellView);
		[cellView removeFromSuperview];
		
		[self setUpTableCellView:cellView forTableColumn:nil row:row];
		
		NSTableColumn *tableColumn = (tableView.tableColumns)[0];
		CGFloat cellWidth = (tableColumn.width);
		(cellView.frameSize) = NSMakeSize(cellWidth, 100.0);
		[cellView layoutSubtreeIfNeeded];
		
		NSTextField *textField = (cellView.textField);
		//(textField.preferredMaxLayoutWidth) = (tableColumn.width);
		(textField.preferredMaxLayoutWidth) = NSWidth(textField.bounds);
		
		CGFloat extraPadding = 13.0;
		
		height = (textField.intrinsicContentSize.height) + extraPadding;
	}
	return height;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAHighlightsTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	[self setUpTableCellView:cellView forTableColumn:tableColumn row:row];
	
	//(cellView.menu) = (self.contextualMenu);
	
	return cellView;
}

#pragma mark Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if (menu == (self.contextualMenu)) {
		GLACollectedFileMenuCreator *collectedFileMenuCreator = (self.collectedFileMenuCreator);
		(collectedFileMenuCreator.context) = GLACollectedFileMenuContextInHighlights;
		(collectedFileMenuCreator.target) = self;
		(collectedFileMenuCreator.openInApplicationAction) = @selector(openWithChosenApplication:);
		(collectedFileMenuCreator.changePreferredOpenerApplicationAction) = @selector(changePreferredOpenerApplication:);
		(collectedFileMenuCreator.showInFinderAction) = @selector(showItemInFinder:);
		(collectedFileMenuCreator.changeCustomNameHighlightsAction) = @selector(changeCustomNameOfClickedItem:);
		(collectedFileMenuCreator.removeFromHighlightsAction) = @selector(removedClickedItem:);
		
		id<NSObject> object = (self.clickedObject);
		
		GLAHighlightedCollectedFile *highlightedCollectedFile = nil;
		if ([object isKindOfClass:[GLAHighlightedCollectedFile class]]) {
			highlightedCollectedFile = (GLAHighlightedCollectedFile *)object;
		}
		(collectedFileMenuCreator.highlightedCollectedFile) = highlightedCollectedFile;
		
		
		NSURL *fileURL = [self fileURLForObject:object];
		(collectedFileMenuCreator.fileURL) = fileURL;
		
		[collectedFileMenuCreator updateMenu:menu];
	}
}

@end
