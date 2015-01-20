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
#import "GLAArrayTableDraggingHelper.h"


@interface GLAFileCollectionViewController () <GLAArrayTableDraggingHelperDelegate>

@property(copy, nonatomic) NSArray *collectedFiles;

@property(nonatomic) GLACollectedFilesSetting *collectedFilesSetting;

@property(nonatomic) BOOL doNotUpdateViews;

@property(nonatomic) NSMutableSet *accessedSecurityScopedURLs;
@property(nonatomic) NSMutableDictionary *usedURLsToCollectedFiles;

@property(nonatomic) NSArray *selectedURLs;
@property(nonatomic) NSMutableDictionary *URLsToOpenerApplicationURLs;
@property(nonatomic) NSMutableDictionary *URLsToDefaultOpenerApplicationURLs;

@property(nonatomic) BOOL openerApplicationsPopUpButtonNeedsUpdate;

@property(nonatomic) QLPreviewPanel *activeQuickLookPreviewPanel;

@property(nonatomic) GLAArrayTableDraggingHelper *tableDraggingHelper;
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
	
	// Allow self to handle keyDown: events.
	(self.nextResponder) = (tableView.nextResponder);
	(tableView.nextResponder) = self;
	
	(self.openerApplicationsPopUpButton.menu.delegate) = self;
	
	(self.tableDraggingHelper) = [[GLAArrayTableDraggingHelper alloc] initWithDelegate:self];
	
	[self setUpFileHelpers];
	
	[self updateSelectedFilesUIVisibilityAnimating:NO];
	[self updateQuickLookPreviewAnimating:NO];
	
	[self reloadSourceFiles];
}

- (GLAProject *)project
{
	GLACollection *filesListCollection = (self.filesListCollection);
	NSUUID *projectUUID = (filesListCollection.projectUUID);
	NSAssert(projectUUID != nil, @"Collection must have a project associated with it.");
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	GLAProject *project = [pm projectWithUUID:projectUUID];
	
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
	
	id collectionNotifier = [pm notificationObjectForCollection:collection];
	[nc addObserver:self selector:@selector(filesListDidChangeNotification:) name:GLACollectionFilesListDidChangeNotification object:collectionNotifier];
	[nc addObserver:self selector:@selector(collectionWasDeleted:) name:GLACollectionWasDeletedNotification object:collectionNotifier];
	
	GLAProject *project = (self.project);
	if (project) {
		id projectNotifier = [pm notificationObjectForProject:project];
		[nc addObserver:self selector:@selector(highlightedItemsDidChangeNotification:) name:GLAProjectHighlightsDidChangeNotification object:projectNotifier];
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
		
		[pm loadFilesListForCollectionIfNeeded:filesListCollection];
		NSArray *collectedFiles = [pm copyFilesListForCollection:filesListCollection];
		
		(self.collectedFiles) = collectedFiles;
	}
	else {
		(self.collectedFiles) = @[];
	}
	
	if (self.hasPreparedViews) {
		[(self.sourceFilesListTableView) reloadData];
		
		[self updateSelectedFilesUIVisibilityAnimating:YES];
	}
}

- (void)filesListDidChangeNotification:(NSNotification *)note
{
	[self reloadSourceFiles];
}

- (void)collectionWasDeleted:(NSNotification *)note
{
	(self.filesListCollection) = nil;
	
	[self reloadSourceFiles];
}

- (void)highlightedItemsDidChangeNotification:(NSNotification *)note
{
	[self addAnyPendingHighlightedItems];
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

- (NSIndexSet *)rowIndexesForActionFrom:(id)sender
{
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	NSIndexSet *selectedIndexes = (sourceFilesListTableView.selectedRowIndexes);
	
	BOOL isContextual = ((sender != nil) && [sender isKindOfClass:[NSMenuItem class]]);
	
	if (isContextual) {
		NSInteger clickedRow = (sourceFilesListTableView.clickedRow);
		if (clickedRow == -1) {
			return [NSIndexSet indexSet];
		}
		
		if ([selectedIndexes containsIndex:clickedRow]) {
			return selectedIndexes;
		}
		else {
			return [NSIndexSet indexSetWithIndex:clickedRow];
		}
	}
	else {
		return selectedIndexes;
	}
}

- (NSArray *)URLsForRowIndexes:(NSIndexSet *)indexes
{
	NSArray *collectedFiles = [(self.collectedFiles) objectsAtIndexes:indexes];
	
	NSMutableArray *URLs = [NSMutableArray new];
	for (GLACollectedFile *collectedFile in collectedFiles) {
		if (collectedFile.isMissing) {
			continue;
		}
		NSURL *fileURL = (collectedFile.filePathURL);
		if (fileURL) {
			[URLs addObject:fileURL];
		}
	}
	
	return URLs;
}

- (NSArray *)selectedURLs
{
	return [self URLsForRowIndexes:[self rowIndexesForActionFrom:nil]];
}

#pragma mark -

- (void)updateQuickLookPreviewAnimating:(BOOL)animate
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
		URL = (selectedFile.filePathURL);
		[self startObservingPreviewFrameChanges];
	}
	
	CGFloat alphaValue = (URL != nil) ? 1.0 : 0.0;
	@try {
		if (animate) {
			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
				(context.duration) = 2.0 / 16.0;
				(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
				
				if (URL) {
					(quickLookPreviewView.previewItem) = URL;
				}
				
				quickLookPreviewView.animator.alphaValue = alphaValue;
			} completionHandler:^{
				if (!URL) {
					(quickLookPreviewView.previewItem) = nil;
				}
			}];
		}
		else {
			(quickLookPreviewView.alphaValue) = alphaValue;
			(quickLookPreviewView.previewItem) = URL;
		}
	}
	@catch (NSException *exception) {
		NSLog(@"Quick Look exception %@", exception);
	}
	@finally {
		
	}
}

- (void)updateSelectedFilesUIVisibilityAnimating:(BOOL)animate
{
	GLAPopUpButton *popUpButton = (self.openerApplicationsPopUpButton);
	GLAButton *addToHighlightsButton = (self.addToHighlightsButton);
	
	NSArray *views =
	@[
	  popUpButton,
	  addToHighlightsButton
	  ];
	
	NSArray *selectedURLs = (self.selectedURLs);
	BOOL hasNoURLs = (selectedURLs.count) == 0;
	CGFloat alphaValue = hasNoURLs ? 0.0 : 1.0;
	
	if (animate) {
		if (!hasNoURLs) {
			[self updateAddToHighlightsUI];
		}
		
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 3.0 / 16.0;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
			
			[[views valueForKey:@"animator"] setValue:@(alphaValue) forKey:@"alphaValue"];
			/*
			 (popUpButton.animator.alphaValue) = alphaValue;
			 (label.animator.alphaValue) = alphaValue;
			 (addToHighlightsButton.animator.alphaValue) = alphaValue;
			 */
		} completionHandler:^{
			if (hasNoURLs) {
				[self updateAddToHighlightsUI];
			}
		}];
	}
	else {
		[self updateAddToHighlightsUI];
		
		[views setValue:@(alphaValue) forKey:@"alphaValue"];
	}
}

- (void)updateAddToHighlightsUI
{
	GLAButton *addToHighlightsButton = (self.addToHighlightsButton);
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	NSArray *selectedCollectedFiles = [(self.collectedFiles) objectsAtIndexes:[self rowIndexesForActionFrom:nil]];
	BOOL selectionIsAllHighlighted = NO;
	
	if ((selectedCollectedFiles.count) > 0) {
		NSArray *collectedFilesNotHighlighted = [pm filterCollectedFiles:selectedCollectedFiles notInHighlightsOfProject:(self.project)];
		selectionIsAllHighlighted = (collectedFilesNotHighlighted.count) == 0;
	}
	
	// If all are already highlighted.
	if (selectionIsAllHighlighted) {
		(addToHighlightsButton.title) = NSLocalizedString(@"Highlighted", @"Title for 'Add to Highlights' button when the all of selected collected files are already in the highlights list.");
		(addToHighlightsButton.hasSecondaryStyle) = NO;
		(addToHighlightsButton.enabled) = NO;
	}
	// If some or all are not highlighted.
	else {
		(addToHighlightsButton.title) = NSLocalizedString(@"Add to Highlights", @"Title for 'Add to Highlights' button when the some of selected collected files are not yet in the highlights list.");
		(addToHighlightsButton.hasSecondaryStyle) = YES;
		(addToHighlightsButton.enabled) = YES;
	}
}

- (void)updateOpenerApplicationsUIMenu
{
	GLAFileOpenerApplicationCombiner *openerApplicationCombiner = (self.openerApplicationCombiner);
	
	NSMenu *menu = (self.openerApplicationsPopUpButton.menu);
	[openerApplicationCombiner updateOpenerApplicationsMenu:menu target:self action:@selector(openWithChosenApplication:) preferredApplicationURL:nil];
	
	// Duplicate the first item, so it appears as the button's content.
	NSMenuItem *firstItem = (menu.itemArray)[0];
	if (firstItem) {
		NSMenuItem *titleMenuItem = [firstItem copy];
		(titleMenuItem.title) = NSLocalizedString(@"Open in", @"Title for 'Open in' application menu");
		[menu insertItem:titleMenuItem atIndex:0];
	}
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

#pragma mark -

- (void)updateSelectedURLs
{
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	NSIndexSet *selectedIndexes = (sourceFilesListTableView.selectedRowIndexes);
	
	(self.selectedURLs) = [self URLsForRowIndexes:selectedIndexes];
	
	NSArray *selectedCollectedFiles = [(self.collectedFiles) objectsAtIndexes:selectedIndexes];
	[(self.collectedFilesSetting) startUsingURLsForCollectedFilesRemovingRemainders:selectedCollectedFiles];
	
	[self retrieveApplicationsToOpenSelection];
	[self setNeedsToUpdateOpenerApplicationsUI];
	
	[self updateQuickLookPreviewAnimating:YES];
	[self updateSelectedFilesUIVisibilityAnimating:YES];
}

- (NSInteger)rowIndexForSelectedURL:(NSURL *)URL
{
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	NSIndexSet *selectedIndexes = (sourceFilesListTableView.selectedRowIndexes);
	
	__block NSInteger rowIndex = -1;
	[(self.collectedFiles) enumerateObjectsAtIndexes:selectedIndexes options:NSEnumerationConcurrent usingBlock:^(GLACollectedFile *collectedFile, NSUInteger idx, BOOL *stop) {
		if ([URL isEqual:(collectedFile.filePathURL)]) {
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

#pragma mark - Actions

#pragma mark Adding Files

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

- (void)insertFilesURLs:(NSArray *)fileURLs atIndex:(NSUInteger)index
{
	NSArray *collectedFiles = [GLACollectedFile collectedFilesWithFileURLs:fileURLs];
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	GLACollection *filesListCollection = (self.filesListCollection);
	
	[pm editFilesListOfCollection:filesListCollection insertingCollectedFiles:collectedFiles atOptionalIndex:index];
}

- (void)addFileURLs:(NSArray *)fileURLs
{
	[self insertFilesURLs:fileURLs atIndex:NSNotFound];
}

#pragma mark Opening

- (IBAction)openSelectedFiles:(id)sender
{
	NSArray *selectedURLs = (self.selectedURLs);
	if ((selectedURLs.count) == 0) {
		return;
	}
	
	NSLog(@"FCV OPEN %@", selectedURLs);
	NSLog(@"REF %@", [[selectedURLs valueForKey:@"fileReferenceURL"] valueForKey:@"filePathURL"]);
	//selectedURLs = [[selectedURLs valueForKey:@"fileReferenceURL"] valueForKey:@"filePathURL"];
	
	NSURL *applicationURL = (self.chosenOpenerApplicationForSelection);
	
	[GLAFileOpenerApplicationCombiner openFileURLs:selectedURLs withApplicationURL:applicationURL useSecurityScope:YES];
}

- (IBAction)openWithChosenApplication:(NSMenuItem *)menuItem
{
	id representedObject = (menuItem.representedObject);
	if ((!representedObject) || ![representedObject isKindOfClass:[NSURL class]]) {
		return;
	}
	
	NSURL *applicationURL = representedObject;
	
	NSArray *selectedURLs = (self.selectedURLs);
	
	[GLAFileOpenerApplicationCombiner openFileURLs:selectedURLs withApplicationURL:applicationURL useSecurityScope:YES];
}

- (IBAction)revealSelectedFilesInFinder:(id)sender
{
	NSArray *URLs = [self URLsForRowIndexes:[self rowIndexesForActionFrom:sender]];
	
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:URLs];
}

- (IBAction)removeSelectedFilesFromList:(id)sender
{
	NSIndexSet *indexes = [self rowIndexesForActionFrom:sender];
	if ((indexes.count) == 0) {
		return;
	}
	
	GLACollection *filesListCollection = (self.filesListCollection);
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	
	[pm editFilesListOfCollection:filesListCollection usingBlock:^(id<GLAArrayEditing> filesListEditor) {
		[filesListEditor removeChildrenAtIndexes:indexes];
	}];
	
	[self reloadSourceFiles];
	[self updateSelectedURLs];
}

- (IBAction)addSelectedFilesToHighlights:(id)sender
{
	NSIndexSet *indexes = [self rowIndexesForActionFrom:sender];
	if ((indexes.count) == 0) {
		return;
	}
	
	NSArray *collectedFiles = [(self.collectedFiles) objectsAtIndexes:indexes];
	
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
	void (^editingBlock)(id<GLAArrayEditing> highlightsEditor) = ^(id<GLAArrayEditing> highlightsEditor)
	{
		NSArray *filteredItems = [highlightsEditor filterArray:highlightedItems whoseResultFromVisitorIsNotAlreadyPresent:^id(GLAHighlightedItem *child) {
			if ([child isKindOfClass:[GLAHighlightedCollectedFile class]]) {
				GLAHighlightedCollectedFile *highlightedCollectedFile = (id)child;
				return (highlightedCollectedFile.collectedFileUUID);
			}
			else {
				return nil;
			}
		}];
		[highlightsEditor addChildren:filteredItems];
	};
	
	GLAProject *project = (self.project);
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	
	if ([pm hasLoadedHighlightsForProject:project]) {
		[pm editHighlightsOfProject:project usingBlock:editingBlock];
		
		[self updateAddToHighlightsUI];
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
	NSArray *selectedURLs = (self.selectedURLs);
	return (selectedURLs.count);
}

- (id<QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
	NSArray *selectedURLs = (self.selectedURLs);
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

- (BOOL)arrayEditorTableDraggingHelper:(GLAArrayTableDraggingHelper *)tableDraggingHelper canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard
{
	return [GLACollectedFile canCopyObjectsFromPasteboard:draggingPasteboard];
}

- (void)arrayEditorTableDraggingHelper:(GLAArrayTableDraggingHelper *)tableDraggingHelper makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock
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
		displayName = NSLocalizedString(@"Missing %@", @"Displayed name when a collected file is missing");
		//displayName = [NSString localizedStringWithFormat:NSLocalizedString(@"Missing %@", @"Displayed name when a collected file is missing"), (collectedFile.name)];
	}
	else {
		GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
		NSURL *fileURL = (collectedFile.filePathURL);
		
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
		return [fileURL isEqual:(collectedFile.filePathURL)];
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
