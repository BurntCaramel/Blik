//
//  GLAFilteredFolderCollectedViewController.m
//  Blik
//
//  Created by Patrick Smith on 19/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAFilteredFolderCollectionViewController.h"
#import "GLAUIStyle.h"
#import "GLAProjectManager.h"
#import "GLAFileInfoRetriever.h"
#import "GLAFileOpenerApplicationFinder.h"
#import "GLAQuickLookPreviewHelper.h"


@interface GLAFilteredFolderCollectionViewController () <GLAQuickLookPreviewHelperDelegate, GLAFileInfoRetrieverDelegate>

@property(nonatomic) BOOL doNotUpdateViews;

@property(nonatomic) GLAFolderQuery *folderQuery;
@property(nonatomic) GLAFolderQueryResults *folderQueryResults;
@property(nonatomic) GLAFolderQueryResultsSortingMethod resultsSortingMethod;
@property(copy, nonatomic) NSArray *fileURLsFromResults;
@property(nonatomic) NSArray *selectedURLs;

@property(nonatomic) GLAFileInfoRetriever *fileInfoRetriever;

@property(nonatomic) GLAFileOpenerApplicationFinder *openerApplicationCombiner;
@property(nonatomic) BOOL openerApplicationsPopUpButtonNeedsUpdate;

@property(nonatomic) GLAQuickLookPreviewHelper *quickLookPreviewHelper;

@property(nonatomic) NSSharingServicePicker *sharingServicePicker;

@end

@implementation GLAFilteredFolderCollectionViewController

- (void)dealloc
{
	[self stopCollectionObserving];
	[self stopObservingFolderQueryResults];
}

- (void)prepareView
{
	[super prepareView];

	GLAUIStyle *style = [GLAUIStyle activeStyle];
	NSView *view = (self.view);
	
	NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
	(sourceFilesListTableView.dataSource) = self;
	(sourceFilesListTableView.delegate) = self;
	(sourceFilesListTableView.identifier) = @"sourceFilesListTableView";
	(sourceFilesListTableView.menu) = (self.sourceFilesListContextualMenu);
	(sourceFilesListTableView.doubleAction) = @selector(openSelectedFiles:);
	[style prepareContentTableView:sourceFilesListTableView];
	
	// Add this view controller to the responder chain pre-Yosemite.
	// Allows self to handle keyDown: events
	if ((view.nextResponder) != self) {
		(self.nextResponder) = (view.nextResponder);
		(view.nextResponder) = self;
	}
	
	[(self.shareButton) sendActionOn:NSLeftMouseDownMask];
	
	[self reloadSourceFilesFromResults];
	[self changeSortPriority:nil];
}

- (void)setUpFileHelpersIfNeeded
{
	if (self.fileInfoRetriever) {
		return;
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	
	(self.fileInfoRetriever) = [[GLAFileInfoRetriever alloc] initWithDelegate:self defaultResourceKeysToRequest:@[NSURLLocalizedNameKey, NSURLEffectiveIconKey]];
	
	GLAFileOpenerApplicationFinder *openerApplicationCombiner = [GLAFileOpenerApplicationFinder new];
	(self.openerApplicationCombiner) = openerApplicationCombiner;
	
	[nc addObserver:self selector:@selector(openerApplicationCombinerDidChangeNotification:) name:GLAFileURLOpenerApplicationCombinerDidChangeNotification object:openerApplicationCombiner];
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
	[self reloadFolderQuery];
	
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
	
	//[self stopAccessingAllSecurityScopedFileURLs];
}

#pragma mark -

- (GLAProjectManager *)projectManager
{
	return [GLAProjectManager sharedProjectManager];
}

- (BOOL)hasProject
{
	GLACollection *filteredFolderCollection = (self.filteredFolderCollection);
	NSUUID *projectUUID = (filteredFolderCollection.projectUUID);
	return projectUUID != nil;
}

- (GLAProject *)project
{
	GLACollection *filteredFolderCollection = (self.filteredFolderCollection);
	NSUUID *projectUUID = (filteredFolderCollection.projectUUID);
	NSAssert(projectUUID != nil, @"Collection must have a project associated with it.");
	
	GLAProjectManager *pm = (self.projectManager);
	GLAProject *project = [pm projectWithUUID:projectUUID];
	
	return project;
}

- (void)startCollectionObserving
{
	GLACollection *collection = (self.filteredFolderCollection);
	if (!collection) {
		return;
	}
	
	GLAProjectManager *pm = (self.projectManager);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	id collectionNotifier = [pm notificationObjectForCollection:collection];
	[nc addObserver:self selector:@selector(folderQueryDidChangeNotification:) name:GLACollectionFolderQueryDidChangeNotification object:collectionNotifier];
	[nc addObserver:self selector:@selector(collectionWasDeleted:) name:GLACollectionWasDeletedNotification object:collectionNotifier];
}

- (void)stopCollectionObserving
{
	GLACollection *collection = (self.filteredFolderCollection);
	if (!collection) {
		return;
	}
	
	GLAProjectManager *pm = (self.projectManager);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Stop observing any notifications on the project manager.
	[nc removeObserver:self name:nil object:[pm notificationObjectForCollection:collection]];
}

- (void)startObservingFolderQueryResults
{
	GLAFolderQueryResults *results = (self.folderQueryResults);
	if (!results) {
		return;
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self selector:@selector(folderQueryResultsGatheringProgressNotification:) name:GLAFolderQueryResultsGatheringProgressNotification object:results];
	[nc addObserver:self selector:@selector(folderQueryResultsDidUpdateNotification:) name:GLAFolderQueryResultsDidUpdateNotification object:results];
}

- (void)stopObservingFolderQueryResults
{
	GLAFolderQueryResults *results = (self.folderQueryResults);
	if (!results) {
		return;
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:nil object:results];
}

@synthesize filteredFolderCollection = _filteredFolderCollection;

- (void)setFilteredFolderCollection:(GLACollection *)filteredFolderCollection
{
	if (_filteredFolderCollection == filteredFolderCollection) {
		return;
	}
	
	[self stopCollectionObserving];
	
	_filteredFolderCollection = filteredFolderCollection;
	
	[self setUpFileHelpersIfNeeded];
	
	[self startCollectionObserving];
	
	[self reloadFolderQuery];
}

- (void)reloadFolderQuery
{
	GLAFolderQuery *folderQuery = nil;
	
	GLACollection *filteredFolderCollection = (self.filteredFolderCollection);
	if (filteredFolderCollection) {
		GLAProjectManager *pm = (self.projectManager);
		
		folderQuery = [pm folderQueryLoadingIfNeededForFilteredFolderCollectionWithUUID:(filteredFolderCollection.UUID)];
#if DEBUG
		NSLog(@"FOLDER QUERY %@", folderQuery);
#endif
	}
	
	(self.folderQuery) = folderQuery;
	
	[self stopObservingFolderQueryResults];
	
	GLAFolderQueryResults *folderQueryResults = nil;
	if (folderQuery) {
		folderQueryResults = [[GLAFolderQueryResults alloc] initWithFolderQuery:folderQuery];
		(folderQueryResults.sortingMethod) = (self.resultsSortingMethod);
		[folderQueryResults startSearching];
	}
	(self.folderQueryResults) = folderQueryResults;
	
	[self reloadSourceFilesFromResults];
	[self startObservingFolderQueryResults];
}

- (void)reloadSourceFilesFromResults
{
	NSArray *fileURLsFromResults = nil;
	
	GLAFolderQueryResults *folderQueryResults = (self.folderQueryResults);
	if (folderQueryResults) {
		[folderQueryResults beginAccessingResults];
		fileURLsFromResults = [folderQueryResults copyFileURLs];
		[folderQueryResults finishAccessingResults];
	}
	
#if DEBUG
	//NSLog(@"reloadSourceFilesFromResults %@", fileURLsFromResults);
#endif
	
	if (!fileURLsFromResults) {
		fileURLsFromResults = @[];
	}
	
	(self.fileURLsFromResults) = fileURLsFromResults;
	
	
	if (self.hasPreparedViews) {
		NSArray *selectedURLs = (self.selectedURLs) ?: @[];
		
		NSTableView *sourceFilesListTableView = (self.sourceFilesListTableView);
		[sourceFilesListTableView reloadData];
		
		NSIndexSet *rowIndexesForSelectedURLs = [self rowIndexesForURLs:[NSSet setWithArray:selectedURLs]];
#if DEBUG
		NSLog(@"rowIndexesForSelectedURLs %@", rowIndexesForSelectedURLs);
#endif
		[sourceFilesListTableView selectRowIndexes:rowIndexesForSelectedURLs byExtendingSelection:NO];
		
		[self updateSelectedURLs];
	}
}

- (void)folderQueryDidChangeNotification:(NSNotification *)note
{
	[self reloadFolderQuery];
}

- (void)collectionWasDeleted:(NSNotification *)note
{
	(self.filteredFolderCollection) = nil;
	
	[self reloadFolderQuery];
}

#pragma mark -

- (NSArray *)URLsForRowIndexes:(NSIndexSet *)indexes
{
	NSArray *fileURLsFromResults = (self.fileURLsFromResults);
	if (fileURLsFromResults) {
		return [fileURLsFromResults objectsAtIndexes:indexes];
	}
	else {
		return nil;
	}
}

- (NSIndexSet *)rowIndexesForURLs:(NSSet *)fileURLsSet
{
	NSMutableIndexSet *indexes = [NSMutableIndexSet new];
	[(self.fileURLsFromResults) enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSURL *URLtoCheck, NSUInteger idx, BOOL *stop) {
		if ([fileURLsSet containsObject:URLtoCheck]) {
			[indexes addIndex:idx];
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

#pragma mark Actions

- (IBAction)openSelectedFiles:(id)sender
{
	GLAFileOpenerApplicationFinder *openerApplicationCombiner = (self.openerApplicationCombiner);
	
	[openerApplicationCombiner openFileURLsUsingDefaultApplications];
	//[openerApplicationCombiner openFileURLsUsingChosenOpenerApplicationPopUpButton:(self.openerApplicationsPopUpButton)];
}

- (IBAction)openWithChosenApplication:(NSMenuItem *)menuItem
{
	GLAFileOpenerApplicationFinder *openerApplicationCombiner = (self.openerApplicationCombiner);
	
	[openerApplicationCombiner openFileURLsUsingMenuItem:menuItem];
}

- (IBAction)revealSelectedFilesInFinder:(id)sender
{
	NSArray *URLs = (self.selectedURLs);
	
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:URLs];
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

- (IBAction)changeSortPriority:(id)sender
{
	GLAPopUpButton *sortPriorityPopUpButton = (self.sortPriorityPopUpButton);
	NSMenuItem *menuItem = (sortPriorityPopUpButton.selectedItem);
	NSString *sortIdentifier = (menuItem.representedObject);
	NSAssert(sortIdentifier != nil, @"Sorting identifier must be set");
	
	NSDictionary *identifiersToSortingMethods =
	@{
	  @"dateLastOpened": @(GLAFolderQueryResultsSortingMethodDateLastOpened),
	  @"dateAdded": @(GLAFolderQueryResultsSortingMethodDateAdded),
	  @"dateModified": @(GLAFolderQueryResultsSortingMethodDateModified),
	  @"dateCreated": @(GLAFolderQueryResultsSortingMethodDateCreated)
	  };
	NSNumber *sortingMethodAsNumber = identifiersToSortingMethods[sortIdentifier];
	NSAssert(sortingMethodAsNumber != nil, @"Sorting method must be valid");
	
	GLAFolderQueryResultsSortingMethod sortingMethod = [sortingMethodAsNumber unsignedIntegerValue];
	(self.resultsSortingMethod) = sortingMethod;
	
	GLAFolderQueryResults *results = (self.folderQueryResults);
	if (results) {
		(results.sortingMethod) = sortingMethod;
	}
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

#pragma mark - UI Updating

- (void)updateSelectedFilesUIVisibilityAnimating:(BOOL)animate
{
	GLAPopUpButton *popUpButton = (self.openerApplicationsPopUpButton);
	GLAButton *shareButton = (self.shareButton);
	
	NSArray *views =
	@[
	  popUpButton,
	  shareButton
	  ];
	
	NSArray *selectedURLs = (self.selectedURLs);
	BOOL hasNoURLs = (selectedURLs.count) == 0;
	CGFloat alphaValue = hasNoURLs ? 0.0 : 1.0;
	
	if (animate) {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 3.0 / 16.0;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
			
			[[views valueForKey:@"animator"] setValue:@(alphaValue) forKey:@"alphaValue"];
		} completionHandler:^{
		}];
	}
	else {
		[views setValue:@(alphaValue) forKey:@"alphaValue"];
	}
}

- (void)updateOpenerApplicationsUIMenu
{
	NSMenu *menu = (self.openerApplicationsPopUpButton.menu);
	
	GLAFileOpenerApplicationFinder *openerApplicationCombiner = (self.openerApplicationCombiner);
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
	GLAFileOpenerApplicationFinder *openerApplicationCombiner = (self.openerApplicationCombiner);
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

- (void)openerApplicationCombinerDidChangeNotification:(NSNotification *)note
{
	[self setNeedsToUpdateOpenerApplicationsUI];
}

- (void)folderQueryResultsGatheringProgressNotification:(NSNotification *)note
{
	[self reloadSourceFilesFromResults];
}

- (void)folderQueryResultsDidUpdateNotification:(NSNotification *)note
{
	[(self.fileInfoRetriever) clearCacheForAllURLs];
	[self reloadSourceFilesFromResults];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	GLAFolderQueryResults *results = (self.folderQueryResults);
	if (!results) {
		return 0;
	}
	
	return (results.resultCount);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAFolderQueryResults *results = (self.folderQueryResults);
	if (!results) {
		return 0;
	}
	
	return [results fileURLForResultAtIndex:row];
}

#pragma mark Table View Delegate

- (void)setUpTableCellView:(NSTableCellView *)cellView forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString *displayName = nil;
	NSImage *iconImage = nil;
	BOOL hasImageView = (cellView.imageView != nil);
	
	GLAFolderQueryResults *results = (self.folderQueryResults);
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	
	NSURL *fileURL = [results fileURLForResultAtIndex:row];
	displayName = [results localizedNameForResultAtIndex:row];
	
	if (fileURL) {
		if (hasImageView) {
			iconImage = [fileInfoRetriever effectiveIconImageForURL:fileURL withSizeDimension:16.0];
		}
	}
	
	(cellView.textField.stringValue) = displayName ?: @"";
	if (hasImageView) {
		(cellView.imageView.image) = iconImage;
	}
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = nil;
	
	cellView = [tableView makeViewWithIdentifier:@"collectedFile" owner:nil];
	
	[self setUpTableCellView:cellView forTableColumn:tableColumn row:row];
	
	return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self updateSelectedURLs];
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
	[quickLookPreviewHelper updatePreviewAnimating:animate];
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

#pragma mark File Info Retriever Delegate

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)fileURL
{
	if (self.doNotUpdateViews) {
		return;
	}
	
	NSInteger rowIndex = [self rowIndexForURL:fileURL];
	
	if (rowIndex != -1) {
		[(self.sourceFilesListTableView) reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
	}
}

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL
{
	if (self.doNotUpdateViews) {
		return;
	}
}

@end
