//
//  GLAFileCollectionViewController.m
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;
#import "GLAFileCollectionViewController.h"
#import "GLAUIStyle.h"
#import "GLAProjectManager.h"
#import "GLACollectedFile.h"
#import "GLAFileInfoRetriever.h"
#import "GLACollectedFilesSetting.h"
#import "GLAFileOpenerApplicationCombiner.h"
#import "GLAArrayEditorTableDraggingHelper.h"


@interface GLAFileCollectionViewController () <GLAArrayEditorTableDraggingHelperDelegate>

@property(copy, nonatomic) NSArray *collectedFiles;

@property(nonatomic) GLACollectedFilesSetting *collectedFilesSetting;

@property(nonatomic) BOOL doNotUpdateViews;

@property(nonatomic) NSMutableSet *accessedSecurityScopedURLs;
@property(nonatomic) NSMutableDictionary *usedURLsToCollectedFiles;

@property(nonatomic) NSMutableArray *selectedURLs;
@property(nonatomic) NSMutableDictionary *URLsToOpenerApplicationURLs;
@property(nonatomic) NSMutableDictionary *URLsToDefaultOpenerApplicationURLs;

@property(nonatomic) BOOL openerApplicationsPopUpButtonNeedsUpdate;

@property(nonatomic) QLPreviewPanel *activeQuickLookPreviewPanel;

@property(nonatomic) GLAArrayEditorTableDraggingHelper *tableDraggingHelper;
@property(nonatomic) NSIndexSet *draggedRowIndexes;

@property(nonatomic) NSMutableArray *highlightedItemsToAddOnceLoaded;

@end

@implementation GLAFileCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc
{
	[self stopCollectionObserving];
	[self stopObservingPreviewFrameChanges];
	[self stopAccessingAllSecurityScopedFileURLs];
}

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	NSTableView *tableView = (self.sourceFilesListTableView);
	(tableView.dataSource) = self;
	(tableView.delegate) = self;
	(tableView.identifier) = @"filesCollectionViewController.sourceFilesListTableView";
	(tableView.menu) = (self.sourceFilesListContextualMenu);
	(tableView.doubleAction) = @selector(openSelectedFiles:);
	[uiStyle prepareContentTableView:tableView];
	
	[tableView registerForDraggedTypes:@[[GLACollectedFile objectJSONPasteboardType], (__bridge NSString *)kUTTypeFileURL]];
	
	[uiStyle prepareTextLabel:(self.openerApplicationsTextLabel)];
	
	// Allow self to handle keyDown: events.
	(self.nextResponder) = (tableView.nextResponder);
	(tableView.nextResponder) = self;
	
	(self.openerApplicationsPopUpButton.menu.delegate) = self;
	
	(self.tableDraggingHelper) = [[GLAArrayEditorTableDraggingHelper alloc] initWithDelegate:self];
	
	[self setUpFileHelpers];
	
	[self reloadSourceFiles];
}

- (GLAProject *)project
{
	GLACollection *filesListCollection = (self.filesListCollection);
	NSUUID *projectUUID = (filesListCollection.projectUUID);
	NSAssert(projectUUID != nil, @"Collection must have a project associated with it.");
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	GLAProject *project = [pm projectWithUUID:projectUUID];
	NSAssert(project != nil, @"Must be able to find project with UUID.");
	
	return project;
}

- (void)startCollectionObserving
{
	GLACollection *collection = (self.filesListCollection);
	if (!collection) {
		return;
	}
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Project Collection List
	[nc addObserver:self selector:@selector(filesListDidChangeNotification:) name:GLACollectionFilesListDidChangeNotification object:[pm notificationObjectForCollection:collection]];
	
	GLAProject *project = (self.project);
	if (project) {
		[nc addObserver:self selector:@selector(highlightedItemsDidChangeNotification:) name:GLAProjectHighlightsDidChangeNotification object:[pm notificationObjectForProject:project]];
	}
}

- (void)stopCollectionObserving
{
	GLACollection *collection = (self.filesListCollection);
	if (!collection) {
		return;
	}
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Stop observing any notifications on the project manager.
	[nc removeObserver:self name:nil object:[pm notificationObjectForCollection:collection]];
	
	GLAProject *project = (self.project);
	if (project) {
		[nc removeObserver:self name:nil object:[pm notificationObjectForProject:project]];
	}
}

- (void)setUpFileHelpers
{
	(self.collectedFilesSetting) = [GLACollectedFilesSetting new];
	
	(self.fileInfoRetriever) = [[GLAFileInfoRetriever alloc] initWithDelegate:self];
	
	GLAFileOpenerApplicationCombiner *openerApplicationCombiner = [GLAFileOpenerApplicationCombiner new];
	(self.openerApplicationCombiner) = openerApplicationCombiner;
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(openerApplicationCombinerDidChangeNotification:) name:GLAFileURLOpenerApplicationCombinerDidChangeNotification object:openerApplicationCombiner];
	
}

@synthesize filesListCollection = _filesListCollection;

- (void)setFilesListCollection:(GLACollection *)filesListCollection
{
	if (_filesListCollection == filesListCollection) {
		return;
	}
	
	[self stopCollectionObserving];
	
	_filesListCollection = filesListCollection;
	
	[self startCollectionObserving];
	
	[self reloadSourceFiles];
}

- (void)reloadSourceFiles
{
	GLACollection *filesListCollection = (self.filesListCollection);
	if (filesListCollection) {
		GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
		
		NSArray *collectedFiles = [pm copyFilesListForCollection:filesListCollection];
		if (!collectedFiles) {
			[pm loadFilesListForCollectionIfNeeded:filesListCollection];
			collectedFiles = @[];
		}
		
		(self.collectedFiles) = collectedFiles;
	}
	else {
		(self.collectedFiles) = @[];
	}
	
	[(self.sourceFilesListTableView) reloadData];
	
	[self updateOpenerApplicationsUIVisibility];
}

- (void)filesListDidChangeNotification:(NSNotification *)note
{
	[self reloadSourceFiles];
}

- (void)highlightedItemsDidChangeNotification:(NSNotification *)note
{
	[self addAnyPendingHighlightedItems];
}

- (void)updateQuickLookPreview
{
	if (self.activeQuickLookPreviewPanel) {
		[(self.activeQuickLookPreviewPanel) reloadData];
	}
	
	if (!(self.quickLookPreviewView)) {
		GLAViewController *previewHolderViewController = [[GLAViewController alloc] init];
		(previewHolderViewController.view) = (self.previewHolderView);
		
		(self.previewHolderViewController) = previewHolderViewController;
		
		QLPreviewView *quickLookPreviewView = [[QLPreviewView alloc] initWithFrame:NSZeroRect style:QLPreviewViewStyleNormal];
		[previewHolderViewController fillViewWithChildView:quickLookPreviewView];
		(self.quickLookPreviewView) = quickLookPreviewView;
	}
	
	QLPreviewView *quickLookPreviewView = (self.quickLookPreviewView);
	NSIndexSet *selectedRowIndexes = [(self.sourceFilesListTableView) selectedRowIndexes];
	GLACollectedFile *selectedFile = nil;
	NSURL *URL = nil;
	
	if ((selectedRowIndexes.count) == 1) {
		selectedFile = (self.collectedFiles)[selectedRowIndexes.firstIndex];
		URL = (selectedFile.URL);
		[self startObservingPreviewFrameChanges];
	}
	
	@try {
		(quickLookPreviewView.previewItem) = URL;
	}
	@catch (NSException *exception) {
		NSLog(@"Quick Look exception %@", exception);
	}
	@finally {
		 
	}
}

- (void)stopObservingPreviewFrameChanges
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	NSView *previewHolderView = (self.previewHolderView);
	NSWindow *window = (previewHolderView.window);
	[nc removeObserver:self name:NSWindowWillStartLiveResizeNotification object:window];
	[nc removeObserver:self name:NSWindowDidEndLiveResizeNotification object:window];
	[nc removeObserver:self name:NSViewFrameDidChangeNotification object:previewHolderView];
}

- (void)startObservingPreviewFrameChanges
{
	[self stopObservingPreviewFrameChanges];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	NSView *previewHolderView = (self.previewHolderView);
	NSWindow *window = (previewHolderView.window);
	[nc addObserver:self selector:@selector(windowDidStartLiveResize:) name:NSWindowWillStartLiveResizeNotification object:window];
	[nc addObserver:self selector:@selector(windowDidEndLiveResize:) name:NSWindowDidEndLiveResizeNotification object:window];
	[nc addObserver:self selector:@selector(previewFrameDidChange:) name:
	 NSViewFrameDidChangeNotification object:previewHolderView];
}

- (void)windowDidStartLiveResize:(NSNotification *)note
{
	(self.previewHolderView.animator.alphaValue) = 0.0;
}

- (void)windowDidEndLiveResize:(NSNotification *)note
{
	QLPreviewView *quickLookPreviewView = (self.quickLookPreviewView);
	if (quickLookPreviewView && ![quickLookPreviewView isHiddenOrHasHiddenAncestor]) {
		[quickLookPreviewView refreshPreviewItem];
	}
	
	(self.previewHolderView.animator.alphaValue) = 1.0;
}

- (void)previewFrameDidChange:(NSNotification *)note
{
	QLPreviewView *quickLookPreviewView = (self.quickLookPreviewView);
	if (quickLookPreviewView && ![quickLookPreviewView isHiddenOrHasHiddenAncestor]) {
		//[quickLookPreviewView refreshPreviewItem];
	}
}

- (void)addUsedURLForCollectedFile:(GLACollectedFile *)collectedFile
{
	[(self.collectedFilesSetting) startUsingURLForCollectedFile:collectedFile];
}

- (void)stopAccessingAllSecurityScopedFileURLs
{
	[(self.collectedFilesSetting) stopUsingURLsForAllCollectedFiles];
}

- (void)makeSourceFilesListFirstResponder
{
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	[(sourceFilesListTableView.window) makeFirstResponder:sourceFilesListTableView];
}

- (void)viewWillTransitionIn
{
	[super viewWillTransitionIn];
	
	(self.doNotUpdateViews) = NO;
	[self reloadSourceFiles];
	
	[self makeSourceFilesListFirstResponder];
}

- (void)viewWillTransitionOut
{
	[super viewWillTransitionOut];
	
	(self.doNotUpdateViews) = YES;
	[self stopObservingPreviewFrameChanges];
	[self stopAccessingAllSecurityScopedFileURLs];
}

#pragma mark -

- (NSArray *)URLsForActionIsContextual:(BOOL)isContextual
{
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	
	NSInteger clickedRow = (sourceFilesListTableView.clickedRow);
	if (isContextual && (clickedRow == -1)) {
		return nil;
	}
	
	NSIndexSet *selectedRows = (sourceFilesListTableView.selectedRowIndexes);
	if (isContextual ? [selectedRows containsIndex:clickedRow] : YES) {
		return (self.selectedURLs);
	}
	else {
		GLACollectedFile *collectedFile = (self.collectedFiles)[clickedRow];
		NSURL *clickedURL = (collectedFile.URL);
		return @[clickedURL];
	}
}

- (NSIndexSet *)rowIndexesForContextualAction
{
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	
	NSInteger clickedRow = (sourceFilesListTableView.clickedRow);
	if (clickedRow == -1) {
		return nil;
	}
	
	NSIndexSet *selectedIndexes = (sourceFilesListTableView.selectedRowIndexes);
	if ([selectedIndexes containsIndex:clickedRow]) {
		return selectedIndexes;
	}
	else {
		return [NSIndexSet indexSetWithIndex:clickedRow];
	}
}

- (void)updateSelectedURLs
{
	NSMutableArray *selectedURLs = (self.selectedURLs);
	if (!selectedURLs) {
		selectedURLs = (self.selectedURLs) = [NSMutableArray new];
	}
	
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	NSIndexSet *selectedIndexes = (sourceFilesListTableView.selectedRowIndexes);
	if ((selectedIndexes.count) == 0) {
		[selectedURLs removeAllObjects];
	}
	else {
		NSArray *collectedFiles = [(self.collectedFiles) objectsAtIndexes:selectedIndexes];
		
		[selectedURLs removeAllObjects];
		for (GLACollectedFile *collectedFile in collectedFiles) {
			NSURL *fileURL = (collectedFile.URL);
			if (fileURL) {
				[selectedURLs addObject:fileURL];
			}
		}
	}
	
	[self retrieveApplicationsToOpenSelection];
	[self setNeedsToUpdateOpenerApplicationsUI];
	[self updateQuickLookPreview];
}

- (NSInteger)rowIndexForSelectedURL:(NSURL *)URL
{
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	NSIndexSet *selectedIndexes = (sourceFilesListTableView.selectedRowIndexes);
	
	__block NSInteger rowIndex = -1;
	[(self.collectedFiles) enumerateObjectsAtIndexes:selectedIndexes options:NSEnumerationConcurrent usingBlock:^(GLACollectedFile *collectedFile, NSUInteger idx, BOOL *stop) {
		if ([URL isEqual:(collectedFile.URL)]) {
			rowIndex = idx;
			*stop = YES;
		}
	}];
	
	return rowIndex;
}

- (void)retrieveApplicationsToOpenSelection
{
	GLAFileOpenerApplicationCombiner *openerApplicationCombiner = (self.openerApplicationCombiner);
	(openerApplicationCombiner.fileURLs) = [NSSet setWithArray:(self.selectedURLs)];
}

- (void)updateOpenerApplicationsUIVisibility
{
	GLAPopUpButton *popUpButton = (self.openerApplicationsPopUpButton);
	NSTextField *label = (self.openerApplicationsTextLabel);
	
	NSArray *selectedURLs = (self.selectedURLs);
	BOOL hasNoURLs = (selectedURLs.count) == 0;
	
	(popUpButton.hidden) = hasNoURLs;
	(label.hidden) = hasNoURLs;
}

- (void)updateOpenerApplicationsUIMenu
{
	GLAFileOpenerApplicationCombiner *openerApplicationCombiner = (self.openerApplicationCombiner);
	
	NSMenu *menu = (self.openerApplicationsPopUpButton.menu);
	[openerApplicationCombiner updateOpenerApplicationsMenu:menu target:self action:@selector(openWithChosenApplication:) preferredApplicationURL:nil];
	
	NSMenuItem *firstItem = (menu.itemArray)[0];
	if (firstItem) {
		[menu insertItem:[firstItem copy] atIndex:0];
	}
	
	[self updateOpenerApplicationsUIVisibility];
}

- (void)setNeedsToUpdateOpenerApplicationsUI
{
	if (self.openerApplicationsPopUpButtonNeedsUpdate) {
		return;
	}
	
	(self.openerApplicationsPopUpButtonNeedsUpdate) = YES;
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		[self updateOpenerApplicationsUIMenu];
		//[(self.openerApplicationsPopUpButton.menu) update];
		
		(self.openerApplicationsPopUpButtonNeedsUpdate) = NO;
	}];
}

- (NSURL *)chosenOpenerApplicationForSelection
{
	NSPopUpButton *openerApplicationsPopUpButton = (self.openerApplicationsPopUpButton);
	
	NSMenuItem *selectedItem = (openerApplicationsPopUpButton.selectedItem);
	if (!selectedItem) {
		return nil;
	}
	
	NSURL *applicationURL = (selectedItem.representedObject);
	if ((applicationURL != nil) && [applicationURL isKindOfClass:[NSURL class]]) {
		return applicationURL;
	}
	else {
		return nil;
	}
}

#pragma mark Actions

- (IBAction)chooseFilesToAdd:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	(openPanel.canChooseFiles) = YES;
	(openPanel.canChooseDirectories) = YES;
	(openPanel.allowsMultipleSelection) = YES;
	
	NSString *chooseString = NSLocalizedString(@"Choose", @"NSOpenPanel button for choosing file/folder to add to collected files list.");
	(openPanel.title) = chooseString;
	(openPanel.prompt) = chooseString;
	
	[openPanel beginWithCompletionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			NSArray *fileURLs = (openPanel.URLs);
			[self addFileURLs:fileURLs];
		}
	}];
}

- (NSArray *)createCollectedFileForFileURLs:(NSArray *)fileURLs
{
	NSMutableArray *collectedFiles = [NSMutableArray array];
	NSError *error = nil;
	for (NSURL *fileURL in fileURLs) {
		GLACollectedFile *collectedFile = [[GLACollectedFile alloc] initWithFileURL:fileURL];
		[collectedFile updateInformationWithError:&error];
		[collectedFiles addObject:collectedFile];
	}
	
	return collectedFiles;
}

- (void)insertFilesURLs:(NSArray *)fileURLs atIndex:(NSUInteger)index
{
	NSArray *collectedFiles = [self createCollectedFileForFileURLs:fileURLs];
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	GLACollection *filesListCollection = (self.filesListCollection);
	
	[pm editFilesListOfCollection:filesListCollection usingBlock:^(id<GLAArrayEditing> filesListEditor) {
		NSArray *filteredItems = [filesListEditor filterArray:collectedFiles whoseValuesIsNotPresentForKeyPath:@"URL.path"];
		
		if (index == NSNotFound) {
			[filesListEditor addChildren:filteredItems];
		}
		else {
			[filesListEditor insertChildren:filteredItems atIndexes:[NSIndexSet indexSetWithIndex:index]];
		}
	}];
}

- (void)addFileURLs:(NSArray *)fileURLs
{
	[self insertFilesURLs:fileURLs atIndex:NSNotFound];
}

- (IBAction)openSelectedFiles:(id)sender
{
	NSMutableArray *selectedURLs = (self.selectedURLs);
	if ((selectedURLs.count) == 0) {
		return;
	}
	
	/*if ((selectedURLs.count) == 1) {
		NSURL *fileURL = selectedURLs[0];
		NSNumber *isDirectoryValue;
		if ([fileURL getResourceValue:&isDirectoryValue forKey:NSURLIsDirectoryKey error:nil]) {
			if ([@(YES) isEqualToNumber:isDirectoryValue]) {
				[[NSWorkspace sharedWorkspace] openFile:(fileURL.path) withApplication:@"Finder"];
				return;
			}
		}
	}*/
	
	NSURL *applicationURL = (self.chosenOpenerApplicationForSelection);
	
	[GLAFileOpenerApplicationCombiner openFileURLs:selectedURLs withApplicationURL:applicationURL];
}

- (IBAction)openWithChosenApplication:(NSMenuItem *)menuItem
{
	id representedObject = (menuItem.representedObject);
	if ((!representedObject) || ![representedObject isKindOfClass:[NSURL class]]) {
		return;
	}
	
	NSURL *applicationURL = representedObject;
	
	NSMutableArray *selectedURLs = (self.selectedURLs);
	
	[selectedURLs makeObjectsPerformSelector:@selector(startAccessingSecurityScopedResource)];
	
	[GLAFileOpenerApplicationCombiner openFileURLs:selectedURLs withApplicationURL:applicationURL];
	
	[selectedURLs makeObjectsPerformSelector:@selector(stopAccessingSecurityScopedResource)];
}

- (IBAction)revealSelectedFilesInFinder:(id)sender
{
	NSArray *selectedURLs = [self URLsForActionIsContextual:(sender != self)];
	
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:selectedURLs];
}

- (IBAction)removeSelectedFilesFromList:(id)sender
{
	NSIndexSet *clickedIndexes = (self.rowIndexesForContextualAction);
	if (!clickedIndexes) {
		return;
	}
	
	GLACollection *filesListCollection = (self.filesListCollection);
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	
	[pm editFilesListOfCollection:filesListCollection usingBlock:^(id<GLAArrayEditing> filesListEditor) {
		[filesListEditor removeChildrenAtIndexes:clickedIndexes];
	}];
	
	[self reloadSourceFiles];
	[self updateSelectedURLs];
}

- (IBAction)addSelectedFilesToHighlights:(id)sender
{
	NSIndexSet *clickedIndexes = (self.rowIndexesForContextualAction);
	if (!clickedIndexes) {
		return;
	}
	
	NSArray *collectedFiles = [(self.collectedFiles) objectsAtIndexes:clickedIndexes];
	
	GLACollection *filesListCollection = (self.filesListCollection);
	NSUUID *projectUUID = (self.project.UUID);
	
	NSMutableArray *highlightedItems = [NSMutableArray array];
	for (GLACollectedFile *collectedFile in collectedFiles) {
		GLAHighlightedCollectedFile *highlightedCollectedFile = [[GLAHighlightedCollectedFile alloc] initByEditing:^(id<GLAHighlightedCollectedFileEditing> editor) {
			(editor.holdingCollectionUUID) = (filesListCollection.UUID);
			(editor.collectedFileUUID) = (collectedFile.UUID);
			(editor.projectUUID) = projectUUID;
		}];
		[highlightedItems addObject:highlightedCollectedFile];
	}
	
	[self addHighlightedItemsToHighlights:highlightedItems loadIfNeeded:YES];
}

- (void)addHighlightedItemsToHighlights:(NSArray *)highlightedItems loadIfNeeded:(BOOL)load
{
	void (^editingBlock)(id<GLAArrayEditing> highlightsEditor) = ^(id<GLAArrayEditing> highlightsEditor) {
		NSArray *filteredItems = [highlightsEditor filterArray:highlightedItems whoseValuesIsNotPresentForKeyPath:@"collectedFileUUID"];
		[highlightsEditor addChildren:filteredItems];
	};
	
	GLAProject *project = (self.project);
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	
	if ([pm hasLoadedHighlightsForProject:project]) {
		NSTableView *tableView = (self.sourceFilesListTableView);
		[tableView beginUpdates];
		
		[pm editHighlightsOfProject:project usingBlock:editingBlock];
		
		[tableView endUpdates];
	}
	else if (load) {
		[pm loadHighlightsForProjectIfNeeded:project];
		
		NSMutableArray *highlightedItemsToAddOnceLoaded = (self.highlightedItemsToAddOnceLoaded);
		if (!highlightedItemsToAddOnceLoaded) {
			(self.highlightedItemsToAddOnceLoaded) = highlightedItemsToAddOnceLoaded = [NSMutableArray new];
		}
		
		[highlightedItemsToAddOnceLoaded addObjectsFromArray:highlightedItems];
	}
}

- (void)addAnyPendingHighlightedItems
{
	NSMutableArray *highlightedItemsToAddOnceLoaded = (self.highlightedItemsToAddOnceLoaded);
	
	if (highlightedItemsToAddOnceLoaded) {
		[self addHighlightedItemsToHighlights:highlightedItemsToAddOnceLoaded loadIfNeeded:NO];
		(self.highlightedItemsToAddOnceLoaded) = nil;
	}
}

#pragma mark Events

- (void)keyDown:(NSEvent *)theEvent
{
	unichar u = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	//NSEventModifierFlags modifierFlags = (theEvent.modifierFlags);
	NSUInteger modifierFlags = (theEvent.modifierFlags);
	
	if (u == NSCarriageReturnCharacter || u == NSEnterCharacter) {
		if (modifierFlags & NSCommandKeyMask) {
			[self revealSelectedFilesInFinder:self];
		}
		else {
			[self openSelectedFiles:self];
		}
	}
	else if (u == ' ') {
		[self quickLookPreviewItems:self];
	}
	
#if 0
	CFArrayRef applicationURLs_cf = LSCopyApplicationURLsForURL((__bridge CFURLRef)fileURL, kLSRolesViewer | kLSRolesEditor);
	NSArray *applicationURLs = CFBridgingRelease(applicationURLs_cf);
	NSLog(@"APPS: %@", applicationURLs);
#endif
}

#pragma mark QuickLook

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel
{
	return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
	(panel.delegate) = self;
	(panel.dataSource) = self;
	
	(self.activeQuickLookPreviewPanel) = panel;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
	(panel.delegate) = nil;
	(panel.dataSource) = nil;
	
	(self.activeQuickLookPreviewPanel) = nil;
}

- (void)quickLookPreviewItems:(id)sender
{
	QLPreviewPanel *qlPanel = [QLPreviewPanel sharedPreviewPanel];
	[qlPanel makeKeyAndOrderFront:nil];
}

#pragma QLPreviewPanel Data Source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
	NSMutableArray *selectedURLs = (self.selectedURLs);
	return (selectedURLs.count);
}

- (id<QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
	NSMutableArray *selectedURLs = (self.selectedURLs);
	NSURL *URL = selectedURLs[index];
	return URL;
}

#pragma mark QLPreviewPanel Delegate

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
	if ((event.type) == NSKeyDown) {
		[(self.sourceFilesListTableView) keyDown:event];
		return YES;
	}
	
	return NO;
}

- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id<QLPreviewItem>)item
{
	NSInteger rowIndex = [self rowIndexForSelectedURL:(NSURL *)item];
	if (rowIndex == -1) {
		return NSZeroRect;
	}
	
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
#if 1
	NSTableCellView *cellView = [sourceFilesListTableView viewAtColumn:0 row:rowIndex makeIfNecessary:YES];
	NSImageView *imageView = (cellView.imageView);
	NSRect windowSourceRect = [imageView convertRect:(imageView.bounds) toView:nil];
#else
	NSRect itemRect = [sourceFilesListTableView rectOfRow:rowIndex];
	
	NSRect windowSourceRect = [sourceFilesListTableView convertRect:itemRect toView:nil];
#endif
	
	return [(sourceFilesListTableView.window) convertRectToScreen:windowSourceRect];
}

- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id<QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
	NSInteger rowIndex = [self rowIndexForSelectedURL:(NSURL *)item];
	if (rowIndex == -1) {
		return nil;
	}
	
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	NSTableCellView *cellView = [sourceFilesListTableView viewAtColumn:0 row:rowIndex makeIfNecessary:YES];
	NSImageView *imageView = (cellView.imageView);
	
	return (imageView.image);
}

#pragma mark - Table Dragging Helper Delegate

- (BOOL)arrayEditorTableDraggingHelper:(GLAArrayEditorTableDraggingHelper *)tableDraggingHelper canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard
{
	return [GLACollectedFile canCopyObjectsFromPasteboard:draggingPasteboard];
}

- (void)arrayEditorTableDraggingHelper:(GLAArrayEditorTableDraggingHelper *)tableDraggingHelper makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock
{
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	[projectManager editFilesListOfCollection:(self.filesListCollection) usingBlock:editBlock];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.collectedFiles.count);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLACollectedFile *collectedFile = (self.collectedFiles)[row];
	
	if (!(collectedFile.isMissing)) {
		[self addUsedURLForCollectedFile:collectedFile];
	}
	
	return collectedFile;
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
	GLACollectedFile *collectedFile = (self.collectedFiles)[row];
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
		NSArray *fileURLs = [pboard readObjectsForClasses:@[ [NSURL class] ] options:@{ NSPasteboardURLReadingFileURLsOnlyKey: @(YES) }];
		if (fileURLs) {
			[self insertFilesURLs:fileURLs atIndex:row];
			//[self addFileURLs:fileURLs];
			return YES;
		}
		else {
			return NO;
		}
	}
	
	return [(self.tableDraggingHelper) tableView:tableView acceptDrop:info row:row dropOperation:dropOperation];
}

#pragma mark Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	
	GLACollectedFile *collectedFile = (self.collectedFiles)[row];
	(cellView.objectValue) = collectedFile;
	
	NSString *displayName = nil;
	NSImage *iconImage = nil;
	
	if (collectedFile.isMissing) {
		displayName = NSLocalizedString(@"Missing", @"Displayed name when a collected file is missing");
	}
	else {
		GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
		NSURL *fileURL = (collectedFile.URL);
		
		NSArray *resourceValueKeys =
		@[
		  NSURLLocalizedNameKey,
		  NSURLEffectiveIconKey
		  ];
		
		NSDictionary *resourceValues = [fileInfoRetriever loadedResourceValuesForKeys:resourceValueKeys forURL:fileURL requestIfNeeded:YES];
		
		displayName = resourceValues[NSURLLocalizedNameKey];
		iconImage = resourceValues[NSURLEffectiveIconKey];
	}
	
	(cellView.textField.stringValue) = displayName ?: @"";
	(cellView.imageView.image) = iconImage;
	
	return cellView;
}
/*
- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
	return proposedSelectionIndexes;
}
*/
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self updateSelectedURLs];
}

#pragma mark File Info Retriever Delegate

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)fileURL
{
	if (self.doNotUpdateViews) {
		return;
	}
	
	NSIndexSet *indexesToUpdate = [(self.collectedFiles) indexesOfObjectsPassingTest:^BOOL(GLACollectedFile *collectedFile, NSUInteger idx, BOOL *stop) {
		return [fileURL isEqual:(collectedFile.URL)];
	}];
	
	[(self.sourceFilesListTableView) reloadDataForRowIndexes:indexesToUpdate columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL
{
	if (self.doNotUpdateViews) {
		return;
	}
}

#pragma mark Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	//[self updateOpenerApplicationsUIMenu];
}

#pragma mark Opener Application Combiner Notifications

- (void)openerApplicationCombinerDidChangeNotification:(NSNotification *)note
{
	[self updateOpenerApplicationsUIMenu];
}

@end
