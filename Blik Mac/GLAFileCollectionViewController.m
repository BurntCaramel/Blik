//
//  GLAFileCollectionViewController.m
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAFileCollectionViewController.h"
#import "GLAUIStyle.h"
#import "GLAProjectManager.h"
#import "GLACollectedFile.h"
#import "GLAFileInfoRetriever.h"


@interface GLAFileCollectionViewController ()

@property(copy, nonatomic) NSArray *collectedFiles;

@property(nonatomic) NSMutableSet *accessedSecurityScopedURLs;
@property(nonatomic) NSMutableDictionary *usedURLsToCollectedFiles;

@property(nonatomic) BOOL doNotUpdateViews;

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

- (void)loadView
{
	[super loadView];
	
	NSTableView *tableView = (self.sourceFilesListTableView);
	(tableView.dataSource) = self;
	(tableView.delegate) = self;
	(tableView.identifier) = @"filesCollectionViewController.sourceFilesListTableView";
	[[GLAUIStyle activeStyle] prepareContentTableView:tableView];
	
	[self setUpFileInfoRetriever];
	
	[self reloadSourceFiles];
}

- (void)startCollectionObserving
{
	GLACollection *collection = (self.filesListCollection);
	if (!collection) {
		return;
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Project Collection List
	[nc addObserver:self selector:@selector(filesListDidChangeNotification:) name:GLACollectionFilesListDidChangeNotification object:collection];
}

- (void)stopCollectionObserving
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Stop observing any notifications on the project manager.
	[nc removeObserver:self name:nil object:(self.filesListCollection)];
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
			[pm requestFilesListForCollection:filesListCollection];
			collectedFiles = @[];
		}
		
		(self.collectedFiles) = collectedFiles;
	}
	else {
		(self.collectedFiles) = @[];
	}
	
	[(self.sourceFilesListTableView) reloadData];
}

- (void)filesListDidChangeNotification:(NSNotification *)note
{
	[self reloadSourceFiles];
}

- (void)updateQuickLookPreview
{
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
	
	(quickLookPreviewView.previewItem) = URL;
}

- (void)stopObservingPreviewFrameChanges
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:(self.previewHolderView)];
}

- (void)startObservingPreviewFrameChanges
{
	[self stopObservingPreviewFrameChanges];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previewFrameDidChange:) name:
	 NSViewFrameDidChangeNotification object:(self.previewHolderView)];
}

- (void)previewFrameDidChange:(NSNotification *)note
{
	QLPreviewView *quickLookPreviewView = (self.quickLookPreviewView);
	if (quickLookPreviewView && ![quickLookPreviewView isHiddenOrHasHiddenAncestor]) {
		[quickLookPreviewView refreshPreviewItem];
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

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	(self.doNotUpdateViews) = NO;
	[self reloadSourceFiles];
}

- (void)viewWillDisappear
{
	[super viewWillDisappear];
	
	(self.doNotUpdateViews) = YES;
	[self stopObservingPreviewFrameChanges];
	[self finishAccessingSecurityScopedFileURLs];
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
	for (NSURL *fileURL in fileURLs) {
		[collectedFiles addObject:[GLACollectedFile collectedFileWithFileURL:fileURL]];
	}
	
	[pm editFilesListOfCollection:filesListCollection usingBlock:^(id<GLAArrayEditing> filesListEditor) {
		[filesListEditor addChildren:collectedFiles];
	}];
	
	[self reloadSourceFiles];
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
	//[fileInfoRetriever requestResourceValuesForKeys:resourceValueKeys forURL:fileURL];
	NSDictionary *resourceValues = [fileInfoRetriever loadedResourceValuesForKeys:resourceValueKeys forURL:fileURL requestIfNeed:YES];
	
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

@end
