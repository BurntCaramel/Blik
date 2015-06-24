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
#import "GLAFileOpenerApplicationFinder.h"
#import "GLAArrayTableDraggingHelper.h"
#import "GLAPluckedCollectedFilesMenuController.h"
#import "GLACollectedFolderStackItemViewController.h"
#import <objc/runtime.h>


#define EXTRA_ROW_COUNT 0


@interface GLAFileCollectionViewController () <GLAArrayTableDraggingHelperDelegate, GLAQuickLookPreviewHelperDelegate, GLACollectedFolderStackItemViewControllerDelegate>

@property(copy, nonatomic) NSArray *collectedFiles;

@property(nonatomic) BOOL doNotUpdateViews;

@property(nonatomic) WindowFirstResponderAssistant *firstResponderAssistant;

@property(nonatomic) GLACollectedFilesSetting *collectedFilesSetting;
@property(nonatomic) GLAFileInfoRetriever *fileInfoRetriever;
@property(nonatomic) GLAFileOpenerApplicationFinder *openerApplicationCombiner;
@property(nonatomic) BOOL openerApplicationsPopUpButtonNeedsUpdate;

@property(nonatomic) NSArray *sourceListSelectedURLs;

@property(nonatomic) FileCollectionSelectionAssistant *selectionAssistant;

@property(nonatomic) GLAQuickLookPreviewHelper *quickLookPreviewHelper;

@property(nonatomic) GLAArrayTableDraggingHelper *tableDraggingHelper;

@property(nonatomic) NSMutableDictionary *collectedFileUUIDsToStackItemViewControllers;

@property(nonatomic) NSSharingServicePicker *sharingServicePicker;

@end

@interface GLAFileCollectionViewController (FileCollectionSelectionSourcing) <FileCollectionSelectionSourcing, CollectedFileSelectionSourcing, GLAFolderContentsAssisting>

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
	[self stopObservingFileHelpers];
	[self stopAccessingAllSecurityScopedFileURLs];
	[self stopWatchingProjectPrimaryFolders];
}

- (void)awakeFromNib
{
	[self setUpFileHelpersIfNeeded];
}

- (void)prepareView
{
#if DEBUG
	NSLog(@"FCVC prepareView");
#endif
	[super prepareView];
	
#if 1
	[self insertIntoResponderChain];
#endif
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	NSTableView *tableView = (self.sourceFilesListTableView);
	if (tableView) {
		(tableView.dataSource) = self;
		(tableView.delegate) = self;
		(tableView.identifier) = @"filesCollectionViewController.sourceFilesListTableView";
		(tableView.menu) = (self.sourceFilesListContextualMenu);
		(tableView.doubleAction) = @selector(openSelectedFiles:);
		[uiStyle prepareContentTableView:tableView];
		
		[tableView registerForDraggedTypes:@[[GLACollectedFile objectJSONPasteboardType], (__bridge NSString *)kUTTypeFileURL]];
		
		(self.tableDraggingHelper) = [[GLAArrayTableDraggingHelper alloc] initWithDelegate:self];
	}
	
	NSStackView *sourceFilesStackView = (self.sourceFilesStackView);
	if (sourceFilesStackView) {
		[sourceFilesStackView setHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationHorizontal];
		
		(sourceFilesStackView.alignment) = NSLayoutAttributeCenterX;
		
		NSScrollView *stackScrollView = (sourceFilesStackView.enclosingScrollView);
		//(stackScrollView.flipped) = YES;
		
		// Make stack view fit width of scroll view.
		NSView *sourceFilesClipView = (sourceFilesStackView.superview);
		NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:sourceFilesStackView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:sourceFilesClipView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];
		(leadingConstraint.priority) = NSLayoutPriorityDefaultLow;
		
		NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:sourceFilesStackView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:sourceFilesClipView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
		(trailingConstraint.priority) = NSLayoutPriorityDefaultLow;
		
		[stackScrollView addConstraints:
		 @[
		   leadingConstraint,
		   trailingConstraint
		   ]
		 ];
		
		[uiStyle prepareContentStackView:sourceFilesStackView];
	}
	
	
	FileCollectionSelectionAssistant *selectionAssistant = [[FileCollectionSelectionAssistant alloc] initWithSource:self filesListCollectionUUID:(self.filesListCollection.UUID) projectUUID:(self.project.UUID) projectManager:(self.projectManager)];
	(self.selectionAssistant) = selectionAssistant;
	
	
	NSTextView *commentsTextView = (self.commentsTextView);
	[uiStyle prepareContentTextView:commentsTextView];
	
	
	FileCollectionBarViewController *barViewController = [[FileCollectionBarViewController alloc] initWithNibName:@"FileCollectionBarViewController" bundle:nil];
	(barViewController.selectionAssistant) = selectionAssistant;
	(self.barViewController) = barViewController;
	[self fillView:(self.barHolderView) withView:(barViewController.view)];
	
	
	//(self.openerApplicationsPopUpButton.menu.delegate) = self;
	
	//[(self.shareButton) sendActionOn:NSLeftMouseDownMask];
}

- (void)didPrepareView
{
	[self updateQuickLookPreviewAnimating:NO];
	
	[self reloadSourceFiles];
}

- (void)viewWillTransitionIn
{
	[super viewWillTransitionIn];
	
	(self.doNotUpdateViews) = NO;
	[self reloadSourceFiles];
}

- (void)viewDidTransitionIn
{
	[self makeSourceFilesListFirstResponder];
	
	NSWindow *window = (self.view.window);
	if (window) {
		WindowFirstResponderAssistant *firstResponderAssistant = [[WindowFirstResponderAssistant alloc] initWithWindow:window];
		__weak GLAFileCollectionViewController* weakSelf = self;
		(firstResponderAssistant.firstResponderDidChange) = ^ {
			__strong GLAFileCollectionViewController* self = weakSelf;
			if (self) {
				[(self.quickLookPreviewHelper) firstResponderDidChange];
				[self updateSelectedURLs];
			}
		};
		(self.firstResponderAssistant) = firstResponderAssistant;
	}
}

- (void)viewWillTransitionOut
{
	[super viewWillTransitionOut];
	
	(self.doNotUpdateViews) = YES;
	
	GLAQuickLookPreviewHelper *quickLookPreviewHelper = (self.quickLookPreviewHelper);
	if (quickLookPreviewHelper) {
		[quickLookPreviewHelper deactivate];
	}
	
	(self.firstResponderAssistant) = nil;
	
	[self stopAccessingAllSecurityScopedFileURLs];
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
	[collectedFilesSetting addToDefaultURLResourceKeysToRequest:
  @[
	NSURLIsRegularFileKey,
	NSURLIsPackageKey,
	NSURLLocalizedNameKey,
	NSURLEffectiveIconKey
	]];
	(self.collectedFilesSetting) = collectedFilesSetting;
	
	
	(self.fileInfoRetriever) = [[GLAFileInfoRetriever alloc] initWithDelegate:self defaultResourceKeysToRequest:@[NSURLLocalizedNameKey, NSURLEffectiveIconKey]];
}

- (void)stopObservingFileHelpers
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc removeObserver:self name:nil object:(self.collectedFilesSetting)];
	[nc removeObserver:self name:nil object:(self.openerApplicationCombiner)];
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
	
	if (filesListCollection) {
		[self setUpFileHelpersIfNeeded];
		
		[self startCollectionObserving];
		[self watchProjectPrimaryFolders];
	}
	
	[self reloadSourceFiles];
}

- (NSView *)createOrUpdateStackItemViewForIndex:(NSUInteger)fileIndex
{
	NSMutableDictionary *collectedFileUUIDsToStackItemViewControllers = (self.collectedFileUUIDsToStackItemViewControllers);
	if (!collectedFileUUIDsToStackItemViewControllers) {
		(self.collectedFileUUIDsToStackItemViewControllers) = collectedFileUUIDsToStackItemViewControllers = [NSMutableDictionary new];
	}
	
	GLACollectedFile *collectedFile = [self collectedFileForRow:fileIndex];
	
	GLACollectedFolderStackItemViewController *folderItemVC = collectedFileUUIDsToStackItemViewControllers[(collectedFile.UUID)];
	
	if (!folderItemVC) {
		folderItemVC = [[GLACollectedFolderStackItemViewController alloc] initWithNibName:NSStringFromClass([GLACollectedFolderStackItemViewController class]) bundle:nil];
		
		(folderItemVC.delegate) = self;
		
		NSView *folderItemView = (folderItemVC.view);
		(folderItemView.translatesAutoresizingMaskIntoConstraints) = NO;
		
		collectedFileUUIDsToStackItemViewControllers[(collectedFile.UUID)] = folderItemVC;
	}
	
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	[collectedFilesSetting startAccessingCollectedFile:collectedFile];
	
	NSString *displayName = [collectedFilesSetting copyValueForURLResourceKey:NSURLLocalizedNameKey forCollectedFile:collectedFile];
	NSImage *iconImage = [collectedFilesSetting copyValueForURLResourceKey:NSURLEffectiveIconKey forCollectedFile:collectedFile];
	
	(folderItemVC.nameLabel.stringValue) = displayName ?: @"Loading…";
	(folderItemVC.iconImageView.image) = iconImage;
	
	NSURL *filePathURL = [collectedFilesSetting filePathURLForCollectedFile:collectedFile];
	NSNumber *isRegularFileValue = [collectedFilesSetting copyValueForURLResourceKey:NSURLIsRegularFileKey forCollectedFile:collectedFile];
	NSNumber *isPackageValue = [collectedFilesSetting copyValueForURLResourceKey:NSURLIsPackageKey forCollectedFile:collectedFile];
	
	if (filePathURL != nil && isRegularFileValue != nil && isPackageValue != nil) {
		BOOL isRegularFile = [isRegularFileValue isEqual:@YES];
		BOOL isPackage = [isPackageValue isEqual:@YES];
		BOOL treatAsFile = (isRegularFile || isPackage);
		if (treatAsFile) {
			[folderItemVC updateContentWithFileURL:filePathURL];
		}
		else {
			[folderItemVC updateContentWithDirectoryURL:filePathURL];
		}
	}
	
	return (folderItemVC.view);
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
		NSArray *selectedURLs = (self.sourceListSelectedURLs) ?: @[];
		
		NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
		if (sourceFilesListTableView) {
			NSLog(@"SETTING UP TABLE VIEW");
			[sourceFilesListTableView reloadData];
			
			NSIndexSet *rowIndexesForSelectedURLs = [self rowIndexesForURLs:[NSSet setWithArray:selectedURLs]];
#if DEBUG
			NSLog(@"rowIndexesForSelectedURLs %@", rowIndexesForSelectedURLs);
#endif
			[sourceFilesListTableView selectRowIndexes:rowIndexesForSelectedURLs byExtendingSelection:NO];
		}
		
		NSStackView *sourceFilesStackView = (self.sourceFilesStackView);
		if (sourceFilesStackView) {
			NSLog(@"SETTING UP STACK VIEW");
			NSMutableArray *stackItemViews = [NSMutableArray new];
			
			NSUInteger fileCount = (collectedFiles.count);
			for (NSUInteger fileIndex = 0; fileIndex < fileCount; fileIndex++) {
				[stackItemViews addObject:[self createOrUpdateStackItemViewForIndex:fileIndex]];
			}
			
			[sourceFilesStackView setViews:stackItemViews inGravity:NSStackViewGravityTop];
		}
		
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
	//NSLog(@"watchProjectPrimaryFolders %@", collectedFilesSetting);
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
	[(self.collectedFilesSetting) invalidateAllAccessedFiles];
	[(self.fileInfoRetriever) clearCacheForAllURLs];
	[self reloadSourceFiles];
}

- (void)stopWatchingProjectPrimaryFolders
{
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	(collectedFilesSetting.directoryURLsToWatch) = nil;
}

#pragma mark -

- (void)stopAccessingAllSecurityScopedFileURLs
{
	[(self.collectedFilesSetting) stopAccessingAllCollectedFilesWaitingUntilDone];
}

- (void)makeSourceFilesListFirstResponder
{
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	if (sourceFilesListTableView) {
		[(sourceFilesListTableView.window) makeFirstResponder:sourceFilesListTableView];
	}
}

#pragma mark -

- (NSIndexSet *)rowIndexesForActionFrom:(id)sender
{
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	if (!sourceFilesListTableView) {
		return [NSIndexSet indexSet];
	}
	
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
	if (!indexes) {
		return @[];
	}
	
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
#if DEBUG
	NSLog(@"updateSelectedURLs");
#endif
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	
	if (sourceFilesListTableView) {
		NSIndexSet *selectedIndexes = (sourceFilesListTableView.selectedRowIndexes);
		(self.sourceListSelectedURLs) = [self URLsForRowIndexes:selectedIndexes];
	}
	
	[self updateQuickLookPreviewAnimating:YES];
	
	[(self.selectionAssistant) update];
	//[(self.barViewController) update];
}

- (NSArray *)firstResponderSelectedURLs
{
	NSArray *previewSelectedURLs = [(self.quickLookPreviewHelper) folderContentsSelectedURLsOnlyIfFirstResponder:YES];
	
	if (previewSelectedURLs) {
		return previewSelectedURLs;
	}
	else {
		return (self.sourceListSelectedURLs);
	}
}

#if 0
- (FileCollectionSelectionManualSource *)newSelectionSourceForCollectedFile:(GLACollectedFile *)collectedFile
{
	FileCollectionSelectionManualSource *source = [FileCollectionSelectionManualSource new];
	
	(source.selectedCollectedFiles) = @[collectedFile];
	
	GLAAccessedFileInfo *accessedFile = [(self.collectedFilesSetting) accessedFileInfoForCollectedFile:collectedFile];
	(source.selectedFileURLs) = @[(accessedFile.filePathURL)];
	
	return source;
}
#endif

#if 0
- (NSArray *)sourceListSelectedURLs
{
	return [self URLsForRowIndexes:[self rowIndexesForActionFrom:nil]];
}
#endif

#pragma mark - UI Updating

- (BOOL)collectedFilesAreAllHighlighted
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
	
	BOOL selectionIsAllHighlighted = [self collectedFilesAreAllHighlighted];
	
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
	[(self.selectionAssistant.openerApplicationCombiner) openFileURLsUsingDefaultApplications];
}

- (IBAction)revealSelectedFilesInFinder:(id)sender
{
	NSArray *URLs = (self.sourceListSelectedURLs);
	if (URLs && URLs.count > 0) {
		[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:URLs];
	}
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
}

- (IBAction)showShareMenuForSelectedFiles:(GLAButton *)sender
{
	NSArray *selectedURLs = (self.sourceListSelectedURLs);
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
	return (self.sourceListSelectedURLs);
}

- (NSInteger)quickLookPreviewHelper:(GLAQuickLookPreviewHelper *)helper tableRowForSelectedURL:(NSURL *)fileURL
{
	return [self rowIndexForURL:fileURL];
}

- (BOOL)hasQuickLookPreview
{
	return (self.previewHolderView) != nil;
}

- (void)updateQuickLookPreviewAnimating:(BOOL)animate
{
	if (!(self.hasQuickLookPreview)) {
		return;
	}
	
	GLAQuickLookPreviewHelper *quickLookPreviewHelper = [self setUpQuickLookPreviewHelperIfNeeded];
	[quickLookPreviewHelper updatePreviewAnimating:animate];
}

- (GLAQuickLookPreviewHelper *)setUpQuickLookPreviewHelperIfNeeded
{
	GLAQuickLookPreviewHelper *quickLookPreviewHelper = (self.quickLookPreviewHelper);
	if (!quickLookPreviewHelper) {
		(self.quickLookPreviewHelper) = quickLookPreviewHelper = [GLAQuickLookPreviewHelper new];
		(quickLookPreviewHelper.delegate) = self;
		(quickLookPreviewHelper.sourceTableView) = (self.sourceFilesListTableView);
		(quickLookPreviewHelper.previewHolderView) = (self.previewHolderView);
		(quickLookPreviewHelper.folderContentsAssistant) = self;
		
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
	
	GLACollectedFile *collectedFile = (self.collectedFiles)[row - EXTRA_ROW_COUNT];
	
	[(self.collectedFilesSetting) startAccessingCollectedFile:collectedFile];
	
	return collectedFile;
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
	return [self collectedFileForRow:row];
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
	
	GLACollectedFile *collectedFile = [self collectedFileForRow:row];
	
	cellView = [tableView makeViewWithIdentifier:@"collectedFile" owner:nil];
	(cellView.objectValue) = collectedFile;
	
	NSString *displayName = nil;
	NSImage *iconImage = nil;
	
	if (collectedFile.empty) {
		displayName = NSLocalizedString(@"(Gone)", @"Display name for empty collected file");
	}
	else {
		GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
		[collectedFilesSetting startAccessingCollectedFile:collectedFile];
		displayName = [collectedFilesSetting copyValueForURLResourceKey:NSURLLocalizedNameKey forCollectedFile:collectedFile];
		iconImage = [collectedFilesSetting copyValueForURLResourceKey:NSURLEffectiveIconKey forCollectedFile:collectedFile];
	}
	
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
	GLACollectedFile *collectedFile = (note.userInfo)[GLACollectedFilesSettingLoadedFileInfoDidChangeNotification_CollectedFile];
	
	NSUInteger index = [(self.collectedFiles) indexOfObject:collectedFile];
	if (index == NSNotFound) {
		return;
	}
	
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	if (sourceFilesListTableView) {
		NSIndexSet *rowIndexes = [self rowIndexesForCollectedFilesIndexes:[NSIndexSet indexSetWithIndex:index]];
		[sourceFilesListTableView reloadDataForRowIndexes:rowIndexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
	}
	
	NSStackView *sourceFilesStackView = (self.sourceFilesStackView);
	if (sourceFilesStackView) {
		[self createOrUpdateStackItemViewForIndex:index];
	}
}

#pragma mark File Info Retriever Delegate

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)fileURL
{
	NSLog(@"didLoadResourceValuesForURL");
	if (self.doNotUpdateViews) {
		return;
	}
	
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	
	NSIndexSet *indexesToUpdate = [(self.collectedFiles) indexesOfObjectsPassingTest:^BOOL(GLACollectedFile *collectedFile, NSUInteger idx, BOOL *stop) {
		GLAAccessedFileInfo *accessedFile = [collectedFilesSetting accessedFileInfoForCollectedFile:collectedFile];
		return [fileURL isEqual:(accessedFile.filePathURL)];
	}];
	
	NSIndexSet *rowIndexesToUpdate = [self rowIndexesForCollectedFilesIndexes:indexesToUpdate];
	
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	if (sourceFilesListTableView) {
		[sourceFilesListTableView reloadDataForRowIndexes:rowIndexesToUpdate columnIndexes:[NSIndexSet indexSetWithIndex:0]];
	}
	
	NSStackView *sourceFilesStackView = (self.sourceFilesStackView);
	if (sourceFilesStackView) {
		[indexesToUpdate enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			[self createOrUpdateStackItemViewForIndex:idx];
		}];
	}
}

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL
{
	if (self.doNotUpdateViews) {
		return;
	}
}

#pragma mark GLACollectedFolderStackItemViewControllerDelegate

- (void)didClickViewForItemViewController:(GLACollectedFolderStackItemViewController *)viewController
{
	NSURL *fileURL = (viewController.fileURL);
	if (!fileURL) {
		return;
	}
	
	(self.sourceListSelectedURLs) = @[fileURL];
	
	//[self updateQuickLookPreviewAnimating:YES];
	
	GLAQuickLookPreviewHelper *quickLookPreviewHelper = [self setUpQuickLookPreviewHelperIfNeeded];
	[quickLookPreviewHelper showQuickLookPanel:YES];
	[quickLookPreviewHelper updatePreviewAnimating:YES];
	
#if DEBUG
	NSLog(@"didClickViewForItemViewController %@", quickLookPreviewHelper);
#endif
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


@implementation GLAFileCollectionViewController (FileCollectionSelectionSourcing)

- (NSArray * __nonnull)selectedFileURLs
{
	return (self.firstResponderSelectedURLs);
}

- (id<CollectedFileSelectionSourcing> __nullable)collectedFileSource
{
	if (self.quickLookPreviewHelper.folderContentsIsFirstResponder) {
		return nil;
	}
	else {
		return self;
	}
}

- (NSArray *)selectedCollectedFiles
{
	if (self.quickLookPreviewHelper.folderContentsIsFirstResponder) {
		return nil;
	}
	else {
		return [self collectedFilesForRowIndexes:[self rowIndexesForActionFrom:nil]];
	}
}

- (BOOL)isReadyToHighlight
{
	return (self.selectionAssistant.isReadyToHighlight);
}

#pragma mark -

- (void)folderContentsSelectionDidChange
{
#if DEBUG && 0
	NSLog(@"folderContentsSelectionDidChange");
#endif
	[(self.selectionAssistant) update];
	//[(self.barViewController) update];
}

- (void)openFolderContentsSelectedFiles
{
	[(self.selectionAssistant.openerApplicationCombiner) openFileURLsUsingDefaultApplications];
}

- (BOOL)fileURLsAreAllCollected:(NSArray *)fileURLs
{
	return [(self.projectManager) filesAreAllCollected:fileURLs inFilesListCollectionWithUUID:(self.filesListCollection.UUID)];
}

- (void)addFileURLsToCollection:(NSArray *)fileURLs
{
	[(self.projectManager) addFiles:fileURLs toFilesListCollectionWithUUID:(self.filesListCollection.UUID) projectUUID:(self.project.UUID)];
}

- (void)removeFileURLsFromCollection:(NSArray *)fileURLs
{
	[(self.projectManager) removeFiles:fileURLs fromFilesListCollectionWithUUID:(self.filesListCollection.UUID) projectUUID:(self.project.UUID)];
}

@end
