//
//  GLAFileCollectionViewController.m
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAFileCollectionViewController.h"
#import "GLAUIStyle.h"
#import "GLAProjectManager.h"
#import "GLACollectedFile.h"
#import "GLAFileInfoRetriever.h"


@interface GLAFileCollectionViewController ()

@property(copy, nonatomic) NSArray *collectedFiles;

@property(nonatomic) BOOL doNotUpdateViews;

@property(nonatomic) NSMutableSet *accessedSecurityScopedURLs;
@property(nonatomic) NSMutableDictionary *usedURLsToCollectedFiles;

@property(nonatomic) NSMutableArray *selectedURLs;
@property(nonatomic) NSMutableDictionary *URLsToOpenerApplicationURLs;
@property(nonatomic) NSMutableDictionary *URLsToDefaultOpenerApplicationURLs;

@property(nonatomic) NSUInteger combinedOpenerApplicationURLsCountSoFar;
@property(nonatomic) NSMutableSet *combinedOpenerApplicationURLs;
@property(nonatomic) NSURL *combinedDefaultOpenerApplicationURL;
@property(nonatomic) BOOL openerApplicationsPopUpButtonNeedsUpdate;

@property(nonatomic) QLPreviewPanel *activeQuickLookPreviewPanel;

@property(nonatomic) NSIndexSet *draggedRowIndexes;

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
	[uiStyle prepareContentTableView:tableView];
	
	[tableView registerForDraggedTypes:@[[GLACollectedFile objectJSONPasteboardType]]];
	
	[uiStyle prepareTextLabel:(self.openerApplicationsTextLabel)];
	
	// Allow self to handle keyDown: events.
	(self.nextResponder) = (tableView.nextResponder);
	(tableView.nextResponder) = self;
	
	(self.openerApplicationsPopUpButton.menu.delegate) = self;
	
	[self setUpFileInfoRetriever];
	
	[self reloadSourceFiles];
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
}

- (void)setUpFileInfoRetriever
{
	GLAFileInfoRetriever *fileInfoRetriever = [GLAFileInfoRetriever new];
	(fileInfoRetriever.delegate) = self;
	
	(self.fileInfoRetriever) = fileInfoRetriever;
	
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
			[pm loadFilesListForCollection:filesListCollection];
			collectedFiles = @[];
		}
		
		(self.collectedFiles) = collectedFiles;
	}
	else {
		(self.collectedFiles) = @[];
	}
	
	[(self.sourceFilesListTableView) reloadData];
	
	[self updateOpenerApplicationsUIVisible];
}

- (void)updateOpenerApplicationsUIVisible
{
	GLAPopUpButton *popUpButton = (self.openerApplicationsPopUpButton);
	NSTextField *label = (self.openerApplicationsTextLabel);
	
	NSArray *selectedURLs = (self.selectedURLs);
	BOOL hasNoURLs = (selectedURLs.count) == 0;
	(popUpButton.hidden) = hasNoURLs;
	(label.hidden) = hasNoURLs;
}

- (void)filesListDidChangeNotification:(NSNotification *)note
{
	[self reloadSourceFiles];
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

- (void)addAccessedSecurityScopedFileURL:(NSURL *)URL
{
	if (!(self.accessedSecurityScopedURLs)) {
		(self.accessedSecurityScopedURLs) = [NSMutableSet new];
	}
	
	NSMutableSet *accessedSecurityScopedURLs = (self.accessedSecurityScopedURLs);
	if (![accessedSecurityScopedURLs containsObject:URL]) {
		[URL startAccessingSecurityScopedResource];
		[accessedSecurityScopedURLs addObject:URL];
	}
}

- (void)finishAccessingSecurityScopedFileURLs
{
	NSSet *accessedSecurityScopedURLs = (self.accessedSecurityScopedURLs);
	if (accessedSecurityScopedURLs) {
		[(self.fileInfoRetriever) clearCacheForURLs:[accessedSecurityScopedURLs allObjects]];
		
		for (NSURL *URL in accessedSecurityScopedURLs) {
			[URL stopAccessingSecurityScopedResource];
		}
	}
}

- (void)addUsedURLForCollectedFile:(GLACollectedFile *)collectedFile
{
	if (!(self.usedURLsToCollectedFiles)) {
		(self.usedURLsToCollectedFiles) = [NSMutableDictionary new];
	}
	
	NSURL *fileURL = (collectedFile.URL);
	
	NSMutableDictionary *usedURLsToCollectedFiles = (self.usedURLsToCollectedFiles);
	if (!usedURLsToCollectedFiles[fileURL]) {
		usedURLsToCollectedFiles[fileURL] = [NSMutableSet new];
	}
	
	NSMutableSet *collectedFiles = usedURLsToCollectedFiles[fileURL];
	[collectedFiles addObject:collectedFile];
	
	[self addAccessedSecurityScopedFileURL:fileURL];
}

- (NSSet *)collectedFilesUsingURL:(NSURL *)fileURL
{
	NSMutableDictionary *usedURLsToCollectedFiles = (self.usedURLsToCollectedFiles);
	if (!usedURLsToCollectedFiles) {
		return nil;
	}
	
	NSMutableSet *collectedFiles = usedURLsToCollectedFiles[fileURL];
	return [collectedFiles copy];
}

- (void)makeSourceFilesListFirstResponder
{
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	[(sourceFilesListTableView.window) makeFirstResponder:sourceFilesListTableView];
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	(self.doNotUpdateViews) = NO;
	[self reloadSourceFiles];
	
	[self makeSourceFilesListFirstResponder];
}

- (void)viewWillDisappear
{
	[super viewWillDisappear];
	
	(self.doNotUpdateViews) = YES;
	[self stopObservingPreviewFrameChanges];
	[self finishAccessingSecurityScopedFileURLs];
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
		return;
	}
	
	NSArray *collectedFiles = [(self.collectedFiles) objectsAtIndexes:selectedIndexes];
	
	[selectedURLs removeAllObjects];
	for (GLACollectedFile *collectedFile in collectedFiles) {
		NSURL *fileURL = (collectedFile.URL);
		[selectedURLs addObject:fileURL];
	}
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

- (void)clearCombinedApplicationURLs
{
	(self.combinedOpenerApplicationURLsCountSoFar) = 0;
	
	NSMutableSet *combinedOpenerApplicationURLs = (self.combinedOpenerApplicationURLs);
	if (combinedOpenerApplicationURLs) {
		[combinedOpenerApplicationURLs removeAllObjects];
	}
}

- (void)combineOpenerApplicationURLsForFileURL:(NSURL *)URL loadIfNeeded:(BOOL)load
{
	NSMutableDictionary *URLsToOpenerApplicationURLs = (self.URLsToOpenerApplicationURLs);
	NSArray *applicationURLs = URLsToOpenerApplicationURLs ? URLsToOpenerApplicationURLs[URL] : nil;
	
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	
	if (load && (applicationURLs == nil)) {
		[fileInfoRetriever requestApplicationURLsToOpenURL:URL];
		return;
	}
	
	NSURL *defaultOpenerApplicationURL = [fileInfoRetriever defaultApplicationsURLToOpenURL:URL];
	
	NSMutableSet *combinedOpenerApplicationURLs = (self.combinedOpenerApplicationURLs);
	if (!combinedOpenerApplicationURLs) {
		combinedOpenerApplicationURLs = (self.combinedOpenerApplicationURLs) = [NSMutableSet new];
	}
	
	if ((self.combinedOpenerApplicationURLsCountSoFar) == 0) {
		[combinedOpenerApplicationURLs addObjectsFromArray:applicationURLs];
		(self.combinedDefaultOpenerApplicationURL) = defaultOpenerApplicationURL;
		
		[self setNeedsToUpdateOpenerApplicationsUI];
	}
	else {
		NSUInteger countBefore = (combinedOpenerApplicationURLs.count);
		[combinedOpenerApplicationURLs intersectSet:[NSSet setWithArray:applicationURLs]];
		NSUInteger countAfter = (combinedOpenerApplicationURLs.count);
		
		if (defaultOpenerApplicationURL != (self.combinedDefaultOpenerApplicationURL)) {
			(self.combinedDefaultOpenerApplicationURL) = nil;
		}
		
		if (countBefore != countAfter) {
			[self setNeedsToUpdateOpenerApplicationsUI];
		}
	}
	
	(self.combinedOpenerApplicationURLsCountSoFar)++;
}

- (void)retrieveApplicationsToOpenSelection
{
	NSMutableArray *selectedURLs = (self.selectedURLs);
	if (!selectedURLs) {
		return;
	}
	
	[self clearCombinedApplicationURLs];
	
	for (NSURL *fileURL in selectedURLs) {
		[self combineOpenerApplicationURLsForFileURL:fileURL loadIfNeeded:YES];
	}
}

- (NSMenuItem *)newMenuItemForApplicationURL:(NSURL *)applicationURL
{
	NSError *error = nil;
	NSDictionary *values = [applicationURL resourceValuesForKeys:@[NSURLLocalizedNameKey, NSURLEffectiveIconKey] error:&error];
	if (!values) {
		return nil;
	}
	
	NSImage *iconImage = values[NSURLEffectiveIconKey];
	iconImage = [iconImage copy];
	(iconImage.size) = NSMakeSize(16.0, 16.0);
	
	NSMenuItem *menuItem = [NSMenuItem new];
	(menuItem.title) = values[NSURLLocalizedNameKey];
	(menuItem.image) = iconImage;
	
	return menuItem;
}

- (void)refreshOpenerApplicationsUI
{
	NSMutableSet *combinedOpenerApplicationURLs = (self.combinedOpenerApplicationURLs);
	NSURL *combinedDefaultOpenerApplicationURL = (self.combinedDefaultOpenerApplicationURL);
	
	NSMenuItem *defaultApplicationMenuItem = nil;
	NSMutableArray *menuItems = [NSMutableArray new];
	
	if (combinedDefaultOpenerApplicationURL) {
		defaultApplicationMenuItem = [self newMenuItemForApplicationURL:combinedDefaultOpenerApplicationURL];
		(defaultApplicationMenuItem.title) = [NSString localizedStringWithFormat:NSLocalizedString(@"%@ (default)", @"Menu item title format for default application."), (defaultApplicationMenuItem.title)];
	}
	
	if ((combinedOpenerApplicationURLs.count) > 0) {
		for (NSURL *applicationURL in combinedOpenerApplicationURLs) {
			NSMenuItem *menuItem = [self newMenuItemForApplicationURL:applicationURL];
			if (!menuItem) {
				continue;
			}
			
			[menuItems addObject:menuItem];
		}
		
		NSSortDescriptor *titleSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
		
		[menuItems sortUsingDescriptors:@[titleSortDescriptor]];
	}
		
	NSMenu *menu = (self.openerApplicationsPopUpButton.menu);
	[menu removeAllItems];
	
	if (defaultApplicationMenuItem) {
		[menu addItem:defaultApplicationMenuItem];
		
		if ((menuItems.count) > 0) {
			[menu addItem:[NSMenuItem separatorItem]];
		}
	}
	else if ((menuItems.count) == 0) {
		NSMenuItem *menuItem = [NSMenuItem new];
		(menuItem.title) = NSLocalizedString(@"No Application", @"");
		(menuItem.enabled) = NO;
		[menu addItem:menuItem];
	}
	
	for (NSMenuItem *menuItem in menuItems) {
		[menu addItem:menuItem];
	}
	
	[self updateOpenerApplicationsUIVisible];
}

- (void)setNeedsToUpdateOpenerApplicationsUI
{
	if (self.openerApplicationsPopUpButtonNeedsUpdate) {
		return;
	}
	
	(self.openerApplicationsPopUpButtonNeedsUpdate) = YES;
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		[self refreshOpenerApplicationsUI];
		//[(self.openerApplicationsPopUpButton.menu) update];
		
		(self.openerApplicationsPopUpButtonNeedsUpdate) = NO;
	}];
}

#pragma mark Actions

- (IBAction)chooseFilesToAdd:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	(openPanel.canChooseFiles) = YES;
	(openPanel.canChooseDirectories) = YES;
	(openPanel.allowsMultipleSelection) = YES;
	
	[openPanel beginWithCompletionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			NSArray *fileURLs = (openPanel.URLs);
			[self addFileURLs:fileURLs];
		}
	}];
}

- (void)addFileURLs:(NSArray *)fileURLs
{
	GLACollection *filesListCollection = (self.filesListCollection);
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	
	NSMutableArray *collectedFiles = [NSMutableArray array];
	NSError *error = nil;
	for (NSURL *fileURL in fileURLs) {
		GLACollectedFile *collectedFile = [GLACollectedFile collectedFileWithFileURL:fileURL];
		[collectedFile updateInformationWithError:&error];
		[collectedFiles addObject:collectedFile];
	}
	
	[pm editFilesListOfCollection:filesListCollection usingBlock:^(id<GLAArrayEditing> filesListEditor) {
		NSArray *filteredItems = [filesListEditor filterArray:collectedFiles whoseValuesIsNotPresentForKeyPath:@"URL.path"];
		[filesListEditor addChildren:filteredItems];
	}];
	
	[self reloadSourceFiles];
}

- (IBAction)openSelectedFiles:(id)sender
{
	NSMutableArray *selectedURLs = (self.selectedURLs);
	if ((selectedURLs.count) == 1) {
		NSURL *fileURL = selectedURLs[0];
		NSNumber *isDirectoryValue;
		if ([fileURL getResourceValue:&isDirectoryValue forKey:NSURLIsDirectoryKey error:nil]) {
			if ([[NSNumber numberWithBool:YES] isEqualToNumber:isDirectoryValue]) {
				[[NSWorkspace sharedWorkspace] openFile:(fileURL.path) withApplication:@"Finder"];
			}
		}
	}
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
}

- (IBAction)addSelectedFilesToHighlights:(id)sender
{
	NSIndexSet *clickedIndexes = (self.rowIndexesForContextualAction);
	if (!clickedIndexes) {
		return;
	}
	
	NSArray *collectedFiles = [(self.collectedFiles) objectsAtIndexes:clickedIndexes];
	
	GLACollection *filesListCollection = (self.filesListCollection);
	NSUUID *projectUUID = (filesListCollection.projectUUID);
	NSAssert(projectUUID != nil, @"Collection must have a project associated with it.");
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	GLAProject *project = [pm projectWithUUID:projectUUID];
	NSAssert(projectUUID != nil, @"Must be able to find project with UUID.");
	
	NSMutableArray *highlightedItems = [NSMutableArray array];
	for (GLACollectedFile *collectedFile in collectedFiles) {
		GLAHighlightedCollectedFile *highlightedCollectedFile = [GLAHighlightedCollectedFile newCreatingFromEditing:^(id<GLAHighlightedCollectedFileEditing> editor) {
			(editor.collectedFile) = collectedFile;
			(editor.holdingCollection) = filesListCollection;
		}];
		[highlightedItems addObject:highlightedCollectedFile];
	}
	
	NSTableView *tableView = (self.sourceFilesListTableView);
	[tableView beginUpdates];
	
	[pm editHighlightsOfProject:project usingBlock:^(id<GLAArrayEditing> highlightsEditor) {
		NSArray *filteredItems = [highlightsEditor filterArray:highlightedItems whoseValuesIsNotPresentForKeyPath:@"collectedFile.UUID"];
		[highlightsEditor addChildren:filteredItems];
	}];
	
	[tableView endUpdates];
}

#pragma mark Events

- (void)keyDown:(NSEvent *)theEvent
{
	unichar u = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	NSEventModifierFlags modifierFlags = (theEvent.modifierFlags);
	
	if (u == NSEnterCharacter || u == NSCarriageReturnCharacter) {
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

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.collectedFiles.count);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLACollectedFile *collectedFile = (self.collectedFiles)[row];
	
	[self addUsedURLForCollectedFile:collectedFile];
	//[self addAccessedSecurityScopedFileURL:(collectedFile.URL)];
	
	return collectedFile;
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
	GLACollectedFile *collectedFile = (self.collectedFiles)[row];
	return collectedFile;
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
		
		[projectManager editFilesListOfCollection:(self.filesListCollection) usingBlock:^(id<GLAArrayEditing> filesListEditor) {
			NSIndexSet *sourceRowIndexes = (self.draggedRowIndexes);
			(self.draggedRowIndexes) = nil;
			
			[filesListEditor removeChildrenAtIndexes:sourceRowIndexes];
		}];
		
		[self reloadSourceFiles];
	}
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	//NSLog(@"proposed row %ld %ld", (long)row, (long)dropOperation);
	
	NSPasteboard *pboard = (info.draggingPasteboard);
	if (![GLACollectedFile canCopyObjectsFromPasteboard:pboard]) {
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
	if (![GLACollectedFile canCopyObjectsFromPasteboard:pboard]) {
		return NO;
	}
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	__block BOOL acceptDrop = YES;
	NSIndexSet *sourceRowIndexes = (self.draggedRowIndexes);
	(self.draggedRowIndexes) = nil;
	
	[projectManager editFilesListOfCollection:(self.filesListCollection) usingBlock:^(id<GLAArrayEditing> filesListEditor) {
		NSDragOperation sourceOperation = (info.draggingSourceOperationMask);
		if (sourceOperation & NSDragOperationMove) {
			// The row index is the final destination, so reduce it by the number of rows being moved before it.
			NSInteger adjustedRow = row - [sourceRowIndexes countOfIndexesInRange:NSMakeRange(0, row)];
			
			[filesListEditor moveChildrenAtIndexes:sourceRowIndexes toIndex:adjustedRow];
		}
		else if (sourceOperation & NSDragOperationCopy) {
			//TODO: actually make copies.
			NSArray *childrenToCopy = [filesListEditor childrenAtIndexes:sourceRowIndexes];
			childrenToCopy = [childrenToCopy valueForKey:@"duplicate"];
			[filesListEditor insertChildren:childrenToCopy atIndexes:[NSIndexSet indexSetWithIndex:row]];
		}
		else if (sourceOperation & NSDragOperationDelete) {
			[filesListEditor removeChildrenAtIndexes:sourceRowIndexes];
		}
		else {
			acceptDrop = NO;
		}
	}];
	
	[self reloadSourceFiles];
	
	return acceptDrop;
}

#pragma mark Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	
	GLACollectedFile *collectedFile = (self.collectedFiles)[row];
	(cellView.objectValue) = collectedFile;
	
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	NSURL *fileURL = (collectedFile.URL);
	
	NSArray *resourceValueKeys =
	@[
	  NSURLLocalizedNameKey,
	  NSURLEffectiveIconKey
	  ];
	
	NSDictionary *resourceValues = [fileInfoRetriever loadedResourceValuesForKeys:resourceValueKeys forURL:fileURL requestIfNeeded:YES];
	
	NSString *displayName = resourceValues[NSURLLocalizedNameKey];
	(cellView.textField.stringValue) = displayName ?: @"";
	
	NSImage *iconImage = resourceValues[NSURLEffectiveIconKey];
	(cellView.imageView.image) = iconImage;
	
	//(cellView.textField.stringValue) = (collectedFile.URL.path);
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
	[self retrieveApplicationsToOpenSelection];
	[self setNeedsToUpdateOpenerApplicationsUI];
	[self updateQuickLookPreview];
}

#pragma mark File Info Retriever Delegate

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)fileURL
{
	if (self.doNotUpdateViews) {
		return;
	}
	
	NSSet *collectedFilesToUpdate = [self collectedFilesUsingURL:fileURL];
	NSIndexSet *indexesToUpdate = [(self.collectedFiles) indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		return [collectedFilesToUpdate containsObject:obj];
	}];
	
	//[(self.sourceFilesListTableView) reloadData];
	[(self.sourceFilesListTableView) reloadDataForRowIndexes:indexesToUpdate columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL
{
	if (self.doNotUpdateViews) {
		return;
	}
}

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didRetrieveApplicationURLsToOpenURL:(NSURL *)URL
{
	NSMutableArray *selectedURLs = (self.selectedURLs);
	if (!selectedURLs) {
		return;
	}
	
	NSMutableDictionary *URLsToOpenerApplicationURLs = (self.URLsToOpenerApplicationURLs);
	if (!URLsToOpenerApplicationURLs) {
		URLsToOpenerApplicationURLs = (self.URLsToOpenerApplicationURLs) = [NSMutableDictionary new];
	}
	
	NSArray *applicationURLs = [fileInfoRetriever applicationsURLsToOpenURL:URL];
	URLsToOpenerApplicationURLs[URL] = applicationURLs;
	
	NSMutableDictionary *URLsToDefaultOpenerApplicationURLs = (self.URLsToDefaultOpenerApplicationURLs);
	if (!URLsToDefaultOpenerApplicationURLs) {
		URLsToDefaultOpenerApplicationURLs = (self.URLsToDefaultOpenerApplicationURLs) = [NSMutableDictionary new];
	}
	
	NSURL *defaultApplicationURL = [fileInfoRetriever defaultApplicationsURLToOpenURL:URL];
	URLsToDefaultOpenerApplicationURLs[URL] = defaultApplicationURL;
	
	if ([selectedURLs containsObject:URL]) {
		[self combineOpenerApplicationURLsForFileURL:URL loadIfNeeded:NO];
	}
	
	//NSLog(@"APPLICATION URLS %@", applicationURLs);
}

#pragma mark Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	//[self refreshOpenerApplicationsUI];
}

@end
