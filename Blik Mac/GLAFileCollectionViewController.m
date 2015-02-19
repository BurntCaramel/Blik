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
#import "GLAPluckedCollectedFilesMenuController.h"
#import <objc/runtime.h>


#define EXTRA_ROW_COUNT 0


@interface GLAFileCollectionViewController () <GLAArrayTableDraggingHelperDelegate, GLAQuickLookPreviewHelperDelegate>

@property(copy, nonatomic) NSArray *collectedFiles;

@property(nonatomic) BOOL doNotUpdateViews;

@property(nonatomic) GLACollectedFilesSetting *collectedFilesSetting;
@property(nonatomic) GLAFileInfoRetriever *fileInfoRetriever;
@property(nonatomic) GLAFileOpenerApplicationCombiner *openerApplicationCombiner;
@property(nonatomic) BOOL openerApplicationsPopUpButtonNeedsUpdate;

@property(nonatomic) NSArray *selectedURLs;

@property(nonatomic) GLAQuickLookPreviewHelper *quickLookPreviewHelper;

@property(nonatomic) GLAArrayTableDraggingHelper *tableDraggingHelper;

@property(nonatomic) NSSharingServicePicker *sharingServicePicker;

@end

@implementation GLAFileCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setUpFileHelpersIfNeeded];
    }
    return self;
}

- (void)dealloc
{
	[self stopCollectionObserving];
	[self stopAccessingAllSecurityScopedFileURLs];
	[self stopWatchingProjectPrimaryFolders];
}

- (void)awakeFromNib
{
	[self setUpFileHelpersIfNeeded];
}

- (void)prepareView
{
	[super prepareView];
	
	NSView *view = (self.view);
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	NSTableView *tableView = (self.sourceFilesListTableView);
	(tableView.dataSource) = self;
	(tableView.delegate) = self;
	(tableView.identifier) = @"filesCollectionViewController.sourceFilesListTableView";
	(tableView.menu) = (self.sourceFilesListContextualMenu);
	(tableView.doubleAction) = @selector(openSelectedFiles:);
	[uiStyle prepareContentTableView:tableView];
	
	[tableView registerForDraggedTypes:@[[GLACollectedFile objectJSONPasteboardType], (__bridge NSString *)kUTTypeFileURL]];
	
	// Add this view controller to the responder chain pre-Yosemite.
	// Allows self to handle keyDown: events
	if ((view.nextResponder) != self) {
		(self.nextResponder) = (view.nextResponder);
		(view.nextResponder) = self;
	}
	
	(self.tableDraggingHelper) = [[GLAArrayTableDraggingHelper alloc] initWithDelegate:self];
	
	
	(self.openerApplicationsPopUpButton.menu.delegate) = self;
	
	[(self.shareButton) sendActionOn:NSLeftMouseDownMask];
	
	
	[self updateSelectedFilesUIVisibilityAnimating:NO];
	[self updateQuickLookPreviewAnimating:NO];
	
	[self reloadSourceFiles];
}

- (GLAProjectManager *)projectManager
{
	return [GLAProjectManager sharedProjectManager];
}

- (BOOL)hasProject
{
	GLACollection *filesListCollection = (self.filesListCollection);
	NSUUID *projectUUID = (filesListCollection.projectUUID);
	return projectUUID != nil;
}

- (GLAProject *)project
{
	GLACollection *filesListCollection = (self.filesListCollection);
	NSUUID *projectUUID = (filesListCollection.projectUUID);
	NSAssert(projectUUID != nil, @"Collection must have a project associated with it.");
	
	GLAProjectManager *pm = (self.projectManager);
	GLAProject *project = [pm projectWithUUID:projectUUID];
	
	return project;
}

- (void)startCollectionObserving
{
	GLACollection *collection = (self.filesListCollection);
	if (!collection) {
		return;
	}
	
	GLAProjectManager *pm = (self.projectManager);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	id collectionNotifier = [pm notificationObjectForCollection:collection];
	[nc addObserver:self selector:@selector(filesListDidChangeNotification:) name:GLACollectionFilesListDidChangeNotification object:collectionNotifier];
	[nc addObserver:self selector:@selector(collectionWasDeleted:) name:GLACollectionWasDeletedNotification object:collectionNotifier];
	
	GLAProject *project = (self.project);
	if (project) {
		id projectNotifier = [pm notificationObjectForProject:project];
		[nc addObserver:self selector:@selector(projectHighlightedItemsDidChangeNotification:) name:GLAProjectHighlightsDidChangeNotification object:projectNotifier];
		[nc addObserver:self selector:@selector(projectPrimaryFoldersDidChangeNotification:) name:GLAProjectPrimaryFoldersDidChangeNotification object:projectNotifier];
	}
}

- (void)stopCollectionObserving
{
	GLACollection *collection = (self.filesListCollection);
	if (!collection) {
		return;
	}
	
	GLAProjectManager *pm = (self.projectManager);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Stop observing any notifications on the project manager.
	[nc removeObserver:self name:nil object:[pm notificationObjectForCollection:collection]];
	
	GLAProject *project = (self.project);
	if (project) {
		[nc removeObserver:self name:nil object:[pm notificationObjectForProject:project]];
	}
}

- (void)setUpFileHelpersIfNeeded
{
	if (self.collectedFilesSetting) {
		return;
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	GLACollectedFilesSetting *collectedFilesSetting = [GLACollectedFilesSetting new];
	[nc addObserver:self selector:@selector(watchedDirectoriesDidChangeNotification:) name:GLACollectedFilesSettingDirectoriesDidChangeNotification object:collectedFilesSetting];
	[nc addObserver:self selector:@selector(collectedFilesSettingLoadedFileInfoDidChangeNotification:) name:GLACollectedFilesSettingLoadedFileInfoDidChangeNotification object:collectedFilesSetting];
	[collectedFilesSetting addToDefaultURLResourceKeysToRequest:@[NSURLLocalizedNameKey, NSURLEffectiveIconKey]];
	(self.collectedFilesSetting) = collectedFilesSetting;
	
	
	(self.fileInfoRetriever) = [[GLAFileInfoRetriever alloc] initWithDelegate:self defaultResourceKeysToRequest:@[NSURLLocalizedNameKey, NSURLEffectiveIconKey]];
	
	GLAFileOpenerApplicationCombiner *openerApplicationCombiner = [GLAFileOpenerApplicationCombiner new];
	(self.openerApplicationCombiner) = openerApplicationCombiner;
	
	[nc addObserver:self selector:@selector(openerApplicationCombinerDidChangeNotification:) name:GLAFileURLOpenerApplicationCombinerDidChangeNotification object:openerApplicationCombiner];
}

@synthesize filesListCollection = _filesListCollection;

- (void)setFilesListCollection:(GLACollection *)filesListCollection
{
	if (_filesListCollection == filesListCollection) {
		return;
	}
	
	[self stopCollectionObserving];
	[self stopWatchingProjectPrimaryFolders];
	
	_filesListCollection = filesListCollection;
	
	[self setUpFileHelpersIfNeeded];
	
	[self startCollectionObserving];
	[self watchProjectPrimaryFolders];
	
	[self reloadSourceFiles];
}

- (void)reloadSourceFiles
{
	NSArray *collectedFiles = nil;
	
	GLACollection *filesListCollection = (self.filesListCollection);
	if (filesListCollection) {
		GLAProjectManager *pm = (self.projectManager);
		
		GLAProject *project = [pm projectWithUUID:(filesListCollection.projectUUID)];
		[pm loadFilesListForCollectionIfNeeded:filesListCollection];
		
		BOOL hasLoadedPrimaryFolders = [pm hasLoadedPrimaryFoldersForProject:project];
		
		if (hasLoadedPrimaryFolders) {
			collectedFiles = [pm copyFilesListForCollection:filesListCollection];
		}
		else {
			[pm loadPrimaryFoldersForProjectIfNeeded:project];
		}
	}
	
	if (!collectedFiles) {
		collectedFiles = @[];
	}
	
	(self.collectedFiles) = collectedFiles;
	// Maybe rely on lazy-loading ability of table view?
	//[(self.collectedFilesSetting) startAccessingCollectedFilesRemovingRemainders:collectedFiles];
	
	if (self.hasPreparedViews) {
		NSArray *selectedURLs = (self.selectedURLs) ?: @[];
		
		NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
		[sourceFilesListTableView reloadData];
		
		NSIndexSet *rowIndexesForSelectedURLs = [self rowIndexesForURLs:[NSSet setWithArray:selectedURLs]];
#if DEBUG
		NSLog(@"rowIndexesForSelectedURLs %@", rowIndexesForSelectedURLs);
#endif
		[sourceFilesListTableView selectRowIndexes:rowIndexesForSelectedURLs byExtendingSelection:NO];
		
		//[self updateSelectedFilesUIVisibilityAnimating:YES];
		[self updateSelectedURLs];
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

- (void)projectHighlightedItemsDidChangeNotification:(NSNotification *)note
{
	[self updateAddToHighlightsUI];
}

- (void)projectPrimaryFoldersDidChangeNotification:(NSNotification *)note
{
	[self watchProjectPrimaryFolders];
}

#pragma mark - Watching

- (void)watchProjectPrimaryFolders
{
	GLAProject *project = (self.project);
	if (!project) {
		return;
	}
	
	GLAProjectManager *pm = (self.projectManager);
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
#if DEBUG
	NSLog(@"watchProjectPrimaryFolders %@", collectedFilesSetting);
#endif
	NSArray *projectFolders = [pm copyPrimaryFoldersForProject:project];
	NSMutableSet *directoryURLs = [NSMutableSet new];
	for (GLACollectedFile *collectedFile in projectFolders) {
		GLAAccessedFileInfo *accessedFileInfo = [collectedFile accessFile];
		NSURL *directoryURL = (accessedFileInfo.filePathURL);
		[directoryURLs addObject:directoryURL];
	}
	(collectedFilesSetting.directoryURLsToWatch) = directoryURLs;
}

- (void)watchedDirectoriesDidChangeNotification:(NSNotification *)note
{
	[(self.fileInfoRetriever) clearCacheForAllURLs];
	[self reloadSourceFiles];
}

- (void)stopWatchingProjectPrimaryFolders
{
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	(collectedFilesSetting.directoryURLsToWatch) = nil;
}

#pragma mark -

- (void)addUsedURLForCollectedFile:(GLACollectedFile *)collectedFile
{
	[(self.collectedFilesSetting) startAccessingCollectedFile:collectedFile];
}

- (void)stopAccessingAllSecurityScopedFileURLs
{
	[(self.collectedFilesSetting) stopAccessingAllCollectedFilesWaitingUntilDone];
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
	
	GLAQuickLookPreviewHelper *quickLookPreviewHelper = (self.quickLookPreviewHelper);
	if (quickLookPreviewHelper) {
		[quickLookPreviewHelper deactivate];
	}
	
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

- (NSIndexSet *)collectedFilesIndexesForRowIndexes:(NSIndexSet *)indexes
{
#if EXTRA_ROW_COUNT == 1
	NSMutableIndexSet *mutableIndexes = [indexes mutableCopy];
	[mutableIndexes shiftIndexesStartingAtIndex:0 by:-EXTRA_ROW_COUNT];
	return mutableIndexes;
#else
	return indexes;
#endif
}

- (NSIndexSet *)rowIndexesForCollectedFilesIndexes:(NSIndexSet *)indexes
{
#if EXTRA_ROW_COUNT == 1
	NSMutableIndexSet *mutableIndexes = [indexes mutableCopy];
	[mutableIndexes shiftIndexesStartingAtIndex:0 by:EXTRA_ROW_COUNT];
	return mutableIndexes;
#else
	return indexes;
#endif
}

- (NSArray *)collectedFilesForRowIndexes:(NSIndexSet *)indexes
{
	indexes = [self collectedFilesIndexesForRowIndexes:indexes];
	
	return [(self.collectedFiles) objectsAtIndexes:indexes];
}

- (NSArray *)URLsForRowIndexes:(NSIndexSet *)indexes
{
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	NSArray *collectedFiles = [self collectedFilesForRowIndexes:indexes];
	
	NSMutableArray *URLs = [NSMutableArray new];
	for (GLACollectedFile *collectedFile in collectedFiles) {
		GLAAccessedFileInfo *accessedFile = [collectedFilesSetting accessedFileInfoForCollectedFile:collectedFile];
		NSURL *fileURL = (accessedFile.filePathURL);
		if (fileURL) {
			[URLs addObject:fileURL];
		}
	}
	
	return URLs;
}

- (NSIndexSet *)rowIndexesForURLs:(NSSet *)fileURLsSet
{
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	
	NSMutableIndexSet *indexes = [NSMutableIndexSet new];
	[(self.collectedFiles) enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(GLACollectedFile *collectedFile, NSUInteger idx, BOOL *stop) {
		GLAAccessedFileInfo *accessedFile = [collectedFilesSetting accessedFileInfoForCollectedFile:collectedFile];
		if (accessedFile) {
			if ([fileURLsSet containsObject:(accessedFile.filePathURL)]) {
				[indexes addIndex:idx];
			}
		}
	}];
	
	return indexes;
}

- (NSInteger)rowIndexForURL:(NSURL *)URL
{
	NSIndexSet *indexes = [self rowIndexesForURLs:[NSSet setWithObject:URL]];
	if (indexes.count == 1) {
		return [indexes firstIndex];
	}
	else {
		return -1;
	}
}

- (void)updateSelectedURLs
{
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	NSIndexSet *selectedIndexes = (sourceFilesListTableView.selectedRowIndexes);
	
	(self.selectedURLs) = [self URLsForRowIndexes:selectedIndexes];
	
	//NSArray *selectedCollectedFiles = [self collectedFilesForRowIndexes:selectedIndexes];
	//[(self.collectedFilesSetting) startAccessingCollectedFilesRemovingRemainders:selectedCollectedFiles];
	
	[self retrieveApplicationsToOpenSelection];
	[self setNeedsToUpdateOpenerApplicationsUI];
	
	[self updateQuickLookPreviewAnimating:YES];
	[self updateSelectedFilesUIVisibilityAnimating:YES];
}

#if 0
- (NSArray *)selectedURLs
{
	return [self URLsForRowIndexes:[self rowIndexesForActionFrom:nil]];
}
#endif

#pragma mark - UI Updating

- (void)updateSelectedFilesUIVisibilityAnimating:(BOOL)animate
{
	GLAPopUpButton *popUpButton = (self.openerApplicationsPopUpButton);
	GLAButton *addToHighlightsButton = (self.addToHighlightsButton);
	GLAButton *shareButton = (self.shareButton);
	
	NSArray *views =
	@[
	  popUpButton,
	  addToHighlightsButton,
	  shareButton
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

- (BOOL)collectedFilesAreAllHighlightedForActionFrom:(id)sender
{
	GLAProjectManager *pm = (self.projectManager);
	NSArray *selectedCollectedFiles = [self collectedFilesForRowIndexes:[self rowIndexesForActionFrom:nil]];
	BOOL isAllHighlighted = NO;
	
	if ((selectedCollectedFiles.count) > 0) {
		NSArray *collectedFilesNotHighlighted = [pm filterCollectedFiles:selectedCollectedFiles notInHighlightsOfProject:(self.project)];
		isAllHighlighted = (collectedFilesNotHighlighted.count) == 0;
	}
	
	return isAllHighlighted;
}

- (BOOL)canDoHighlightActionsLoadingIfNeeded:(BOOL)load
{
	GLAProjectManager *pm = (self.projectManager);
	GLAProject *project = (self.project);
	if (load) {
		[pm loadHighlightsForProjectIfNeeded:project];
	}
	return [pm hasLoadedHighlightsForProject:project];
}

- (void)updateAddToHighlightsUI
{
	if (! self.hasProject) {
		return;
	}
	
	GLAButton *button = (self.addToHighlightsButton);
	
	BOOL canDoHighlightActions = [self canDoHighlightActionsLoadingIfNeeded:YES];
	if (!canDoHighlightActions) {
		(button.enabled) = NO;
		(button.title) = NSLocalizedString(@"(Loading Highlights)", @"Title for 'Add to Highlights' button when the highlights is still loading.");
		return;
	}
	
	(button.enabled) = YES;
	
	BOOL selectionIsAllHighlighted = [self collectedFilesAreAllHighlightedForActionFrom:nil];
	
	// If all are already highlighted.
	if (selectionIsAllHighlighted) {
		(button.title) = NSLocalizedString(@"Remove from Highlights", @"Title for 'Remove from Highlights' button when the all of selected collected files are already in the highlights list.");
		(button.action) = @selector(removeSelectedFilesFromHighlights:);
	}
	// If some or all are not highlighted.
	else {
		(button.title) = NSLocalizedString(@"Add to Highlights", @"Title for 'Add to Highlights' button when the some of selected collected files are not yet in the highlights list.");
		(button.action) = @selector(addSelectedFilesToHighlights:);
	}
}

- (void)updateAddToHighlightsMenuItem
{
	if (! self.hasProject) {
		return;
	}
	
	NSMenuItem *menuItem = (self.addToHighlightsMenuItem);
	
	BOOL canDoHighlightActions = [self canDoHighlightActionsLoadingIfNeeded:YES];
	if (!canDoHighlightActions) {
		(menuItem.enabled) = NO;
		(menuItem.title) = NSLocalizedString(@"(Loading Highlights)", @"Title for 'Add to Highlights' menu item when the highlights is still loading.");
		(menuItem.action) = nil;
		return;
	}
	
	(menuItem.enabled) = YES;
	
	BOOL selectionIsAllHighlighted = [self collectedFilesAreAllHighlightedForActionFrom:menuItem];
	
	// If all are already highlighted.
	if (selectionIsAllHighlighted) {
		(menuItem.title) = NSLocalizedString(@"Remove from Highlights", @"Title for 'Remove from Highlights' menu item when the all of selected collected files are already in the highlights list.");
		(menuItem.action) = @selector(removeSelectedFilesFromHighlights:);
	}
	// If some or all are not highlighted.
	else {
		(menuItem.title) = NSLocalizedString(@"Add to Highlights", @"Title for 'Add to Highlights' menu item when the some of selected collected files are not yet in the highlights list.");
		(menuItem.action) = @selector(addSelectedFilesToHighlights:);
	}
}

- (void)updateOpenerApplicationsUIMenu
{
	NSMenu *menu = (self.openerApplicationsPopUpButton.menu);
	
	GLAFileOpenerApplicationCombiner *openerApplicationCombiner = (self.openerApplicationCombiner);
	[openerApplicationCombiner updateOpenerApplicationsMenu:menu target:self action:@selector(openWithChosenApplication:) preferredApplicationURL:nil forPopUpMenu:YES];
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

- (void)retrieveApplicationsToOpenSelection
{
	GLAFileOpenerApplicationCombiner *openerApplicationCombiner = (self.openerApplicationCombiner);
	(openerApplicationCombiner.fileURLs) = [NSSet setWithArray:(self.selectedURLs)];
}

- (void)openerApplicationCombinerDidChangeNotification:(NSNotification *)note
{
	[self updateOpenerApplicationsUIMenu];
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
	
	GLAProjectManager *pm = (self.projectManager);
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
	GLAFileOpenerApplicationCombiner *openerApplicationCombiner = (self.openerApplicationCombiner);
	
	[openerApplicationCombiner openFileURLsUsingDefaultApplications];
	//[openerApplicationCombiner openFileURLsUsingChosenOpenerApplicationPopUpButton:(self.openerApplicationsPopUpButton)];
}

- (IBAction)openWithChosenApplication:(NSMenuItem *)menuItem
{
	GLAFileOpenerApplicationCombiner *openerApplicationCombiner = (self.openerApplicationCombiner);
	
	[openerApplicationCombiner openFileURLsUsingMenuItem:menuItem];
}

- (IBAction)revealSelectedFilesInFinder:(id)sender
{
	NSArray *URLs = (self.selectedURLs);
	
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:URLs];
}

- (IBAction)removeSelectedFilesFromList:(id)sender
{
	NSIndexSet *indexes = [self rowIndexesForActionFrom:sender];
	if ((indexes.count) == 0) {
		return;
	}
	
	GLACollection *filesListCollection = (self.filesListCollection);
	GLAProjectManager *pm = (self.projectManager);
	
	[pm editFilesListOfCollection:filesListCollection usingBlock:^(id<GLAArrayEditing> filesListEditor) {
		[filesListEditor removeChildrenAtIndexes:indexes];
	}];
	
	[self reloadSourceFiles];
}

- (IBAction)addSelectedFilesToHighlights:(id)sender
{
	NSIndexSet *indexes = [self rowIndexesForActionFrom:sender];
	if ((indexes.count) == 0) {
		return;
	}
	
	NSArray *collectedFiles = [self collectedFilesForRowIndexes:indexes];
	
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
	
	[self addHighlightedItemsToHighlights:highlightedItems];
}

- (IBAction)removeSelectedFilesFromHighlights:(id)sender
{
	NSIndexSet *collectedFilesIndexes = [self rowIndexesForActionFrom:sender];
	if ((collectedFilesIndexes.count) == 0) {
		return;
	}
	
	NSArray *collectedFiles = [self collectedFilesForRowIndexes:collectedFilesIndexes];
	NSSet *collectedFileUUIDs = [NSSet setWithArray:[collectedFiles valueForKey:@"UUID"]];
	
	void (^editingBlock)(id<GLAArrayEditing> highlightsEditor) = ^(id<GLAArrayEditing> highlightsEditor)
	{
		NSIndexSet *highlightedItemsIndexes = [highlightsEditor indexesOfChildrenWhoseResultFromVisitor:^id(GLAHighlightedItem *child) {
			if ([child isKindOfClass:[GLAHighlightedCollectedFile class]]) {
				GLAHighlightedCollectedFile *highlightedCollectedFile = (id)child;
				return (highlightedCollectedFile.collectedFileUUID);
			}
			else {
				return nil;
			}
		} hasValueContainedInSet:collectedFileUUIDs];
		
		[highlightsEditor removeChildrenAtIndexes:highlightedItemsIndexes];
	};
	
	GLAProject *project = (self.project);
	GLAProjectManager *pm = (self.projectManager);
	[pm editHighlightsOfProject:project usingBlock:editingBlock];
}

- (void)addHighlightedItemsToHighlights:(NSArray *)highlightedItems
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
	GLAProjectManager *pm = (self.projectManager);
	[pm editHighlightsOfProject:project usingBlock:editingBlock];
	
	// This is called by the change notification observer:
	//[self updateAddToHighlightsUI];
}

- (IBAction)showShareMenuForSelectedFiles:(GLAButton *)sender
{
	NSArray *selectedURLs = (self.selectedURLs);
	//NSArray *sharingServices = [NSSharingService sharingServicesForItems:(self.selectedURLs)];
	
	NSSharingServicePicker *picker = [[NSSharingServicePicker alloc] initWithItems:selectedURLs];
	(self.sharingServicePicker) = picker;
	
	//(picker.delegate) = self;
	[picker showRelativeToRect:(sender.insetBounds) ofView:sender preferredEdge:NSMinYEdge];
}

#pragma mark Events

- (void)keyDown:(NSEvent *)theEvent
{
	unichar u = [(theEvent.charactersIgnoringModifiers) characterAtIndex:0];
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
}

#pragma mark Menus

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if (menu == (self.sourceFilesListContextualMenu)) {
		[self updateAddToHighlightsMenuItem];
	}
}

#pragma mark QuickLook Preview Helper

- (NSArray *)selectedURLsForQuickLookPreviewHelper:(GLAQuickLookPreviewHelper *)helper
{
	return (self.selectedURLs);
}

- (NSInteger)quickLookPreviewHelper:(GLAQuickLookPreviewHelper *)helper tableRowForSelectedURL:(NSURL *)fileURL
{
	return [self rowIndexForURL:fileURL];
}

- (void)updateQuickLookPreviewAnimating:(BOOL)animate
{
	GLAQuickLookPreviewHelper *quickLookPreviewHelper = [self setUpQuickLookPreviewHelperIfNeeded];
	[quickLookPreviewHelper updateQuickLookPreviewAnimating:animate];
}

- (GLAQuickLookPreviewHelper *)setUpQuickLookPreviewHelperIfNeeded
{
	GLAQuickLookPreviewHelper *quickLookPreviewHelper = (self.quickLookPreviewHelper);
	if (!quickLookPreviewHelper) {
		(self.quickLookPreviewHelper) = quickLookPreviewHelper = [GLAQuickLookPreviewHelper new];
		(quickLookPreviewHelper.delegate) = self;
		(quickLookPreviewHelper.tableView) = (self.sourceFilesListTableView);
		(quickLookPreviewHelper.previewHolderView) = (self.previewHolderView);
		
	}
	
	return quickLookPreviewHelper;
}

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel
{
	return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
	GLAQuickLookPreviewHelper *quickLookPreviewHelper = [self setUpQuickLookPreviewHelperIfNeeded];
	
	[quickLookPreviewHelper beginPreviewPanelControl:panel];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
	GLAQuickLookPreviewHelper *quickLookPreviewHelper = [self setUpQuickLookPreviewHelperIfNeeded];
	
	[quickLookPreviewHelper endPreviewPanelControl:panel];
}

- (void)quickLookPreviewItems:(id)sender
{
	GLAQuickLookPreviewHelper *quickLookPreviewHelper = [self setUpQuickLookPreviewHelperIfNeeded];
	
	[quickLookPreviewHelper quickLookPreviewItems:sender];
}

#pragma mark - Table Dragging Helper Delegate

- (BOOL)arrayEditorTableDraggingHelper:(GLAArrayTableDraggingHelper *)tableDraggingHelper canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard
{
	return [GLACollectedFile canCopyObjectsFromPasteboard:draggingPasteboard];
}

- (void)arrayEditorTableDraggingHelper:(GLAArrayTableDraggingHelper *)tableDraggingHelper makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock
{
	GLAProjectManager *projectManager = (self.projectManager);
	[projectManager editFilesListOfCollection:(self.filesListCollection) usingBlock:editBlock];
}

#pragma mark Table View Data Source

- (GLACollectedFile *)collectedFileForRow:(NSInteger)row
{
#if EXTRA_ROW_COUNT == 1
	if (row == 0) {
		return nil;
	}
#endif
	return (self.collectedFiles)[row - EXTRA_ROW_COUNT];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.collectedFiles.count) + EXTRA_ROW_COUNT;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
#if EXTRA_ROW_COUNT == 1
	if (row == 0) {
		return @"Collected";
	}
#endif
	GLACollectedFile *collectedFile = [self collectedFileForRow:row];
	
	[self addUsedURLForCollectedFile:collectedFile];
	
	return collectedFile;
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
	return [self collectedFileForRow:row];
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
	
	// GLACollectedFile supports kUTTypeFileURL so check for its own type first.
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
	
	return NO;
}

#pragma mark Table View Delegate

#if EXTRA_ROW_COUNT == 1
- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
	return (row == 0);
}
#endif

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
#if EXTRA_ROW_COUNT == 1
	if (row == 0) {
		NSTableRowView *groupRowView = [tableView makeViewWithIdentifier:@"blik.groupRowViewKey" owner:nil];
		NSLog(@"MADE %@", groupRowView);
		(groupRowView.backgroundColor) = [NSColor clearColor];
		return groupRowView;
		//(rowView.backgroundColor) = [NSColor clearColor];
	}
#endif
	
	return nil;
}

- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
#if EXTRA_ROW_COUNT == 1
	if (row == 0) {
		NSLog(@"DID ADD GROUP ROW VIEW");
		(rowView.backgroundColor) = [NSColor clearColor];
	}
#endif
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = nil;
	
#if EXTRA_ROW_COUNT == 1
	if (row == 0) {
#if DEBUG
		NSLog(@"MAKE CELL VIEW for GROUP ROW");
#endif
		cellView = [tableView makeViewWithIdentifier:@"group" owner:nil];
		(cellView.backgroundStyle) = NSBackgroundStyleDark;
		//(cellView.backgroundStyle) = NSBackgroundStyleLight;
		(cellView.textField.stringValue) = @"Collected";
		(cellView.imageView.image) = nil;
		return cellView;
	}
#endif
	
	cellView = [tableView makeViewWithIdentifier:@"collectedFile" owner:nil];
	
	GLACollectedFile *collectedFile = [self collectedFileForRow:row];
	(cellView.objectValue) = collectedFile;
	
	NSString *displayName = nil;
	NSImage *iconImage = nil;
	
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	[collectedFilesSetting startAccessingCollectedFile:collectedFile];
	displayName = [collectedFilesSetting copyValueForURLResourceKey:NSURLLocalizedNameKey forCollectedFile:collectedFile];
	iconImage = [collectedFilesSetting copyValueForURLResourceKey:NSURLEffectiveIconKey forCollectedFile:collectedFile];
	
	(cellView.textField.stringValue) = displayName ?: @"Loading…";
	(cellView.imageView.image) = iconImage;
	
	return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self updateSelectedURLs];
}

#pragma mark Collected Files Setting

- (void)collectedFilesSettingLoadedFileInfoDidChangeNotification:(NSNotification *)note
{
#if DEBUG
	NSLog(@"collectedFilesSettingLoadedFileInfoDidChangeNotification");
#endif
	
	[(self.sourceFilesListTableView) reloadData];
}

#pragma mark File Info Retriever Delegate

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)fileURL
{
	if (self.doNotUpdateViews) {
		return;
	}
	
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	
	NSIndexSet *indexesToUpdate = [(self.collectedFiles) indexesOfObjectsPassingTest:^BOOL(GLACollectedFile *collectedFile, NSUInteger idx, BOOL *stop) {
		GLAAccessedFileInfo *accessedFile = [collectedFilesSetting accessedFileInfoForCollectedFile:collectedFile];
		return [fileURL isEqual:(accessedFile.filePathURL)];
	}];
	
	NSIndexSet *rowIndexesToUpdate = [self rowIndexesForCollectedFilesIndexes:indexesToUpdate];
	
	[(self.sourceFilesListTableView) reloadDataForRowIndexes:rowIndexesToUpdate columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL
{
	if (self.doNotUpdateViews) {
		return;
	}
}

#pragma mark Plucked Collected Files

- (BOOL)canPluckSelection
{
	NSIndexSet *collectedFilesIndexes = [self rowIndexesForActionFrom:nil];
	return ((collectedFilesIndexes.count) > 0);
}

- (IBAction)pluckSelection:(id)sender
{
	NSIndexSet *collectedFilesIndexes = [self rowIndexesForActionFrom:nil];
	if ((collectedFilesIndexes.count) == 0) {
		return;
	}
	NSArray *collectedFiles = [self collectedFilesForRowIndexes:collectedFilesIndexes];
	
	GLAPluckedCollectedFilesMenuController *pluckedItemsMenuController = [GLAPluckedCollectedFilesMenuController sharedMenuController];
	GLAPluckedCollectedFilesList *pluckedCollectedFilesList = (pluckedItemsMenuController.pluckedCollectedFilesList);
	
	[pluckedCollectedFilesList addCollectedFilesToPluckList:collectedFiles fromCollection:(self.filesListCollection)];
}

- (BOOL)canClearPluckedFilesList
{
	GLAPluckedCollectedFilesMenuController *pluckedItemsMenuController = [GLAPluckedCollectedFilesMenuController sharedMenuController];
	GLAPluckedCollectedFilesList *pluckedCollectedFilesList = (pluckedItemsMenuController.pluckedCollectedFilesList);
	
	return (pluckedCollectedFilesList.hasPluckedCollectedFiles);
}

- (IBAction)clearPluckedFilesList:(id)sender
{
	GLAPluckedCollectedFilesMenuController *pluckedItemsMenuController = [GLAPluckedCollectedFilesMenuController sharedMenuController];
	GLAPluckedCollectedFilesList *pluckedCollectedFilesList = (pluckedItemsMenuController.pluckedCollectedFilesList);
	[pluckedCollectedFilesList clearPluckList];
}

- (BOOL)canPlacePluckedCollectedFiles
{
	GLAPluckedCollectedFilesMenuController *pluckedItemsMenuController = [GLAPluckedCollectedFilesMenuController sharedMenuController];
	GLAPluckedCollectedFilesList *pluckedCollectedFilesList = (pluckedItemsMenuController.pluckedCollectedFilesList);
	
	return (pluckedCollectedFilesList.hasPluckedCollectedFiles);
}

- (IBAction)placePluckedCollectedFiles:(id)sender
{
	GLAPluckedCollectedFilesMenuController *pluckedItemsMenuController = [GLAPluckedCollectedFilesMenuController sharedMenuController];
	
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		NSMenuItem *menuItem = (id)sender;
		[pluckedItemsMenuController placePluckedItemsWithMenuItem:menuItem intoCollection:(self.filesListCollection) project:(self.project)];
	}
}

#pragma mark - NSValidatedUserInterfaceItem

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
	SEL action = (anItem.action);
	if (sel_isEqual(@selector(pluckSelection:), action)) {
		return [self canPluckSelection];
	}
	else if (sel_isEqual(@selector(clearPluckedFilesList:), action)) {
		return [self canClearPluckedFilesList];
	}
	else if (sel_isEqual(@selector(placePluckedCollectedFiles:), action)) {
		return [self canPlacePluckedCollectedFiles];
	}
	
	return YES;
}

@end
