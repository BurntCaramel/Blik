//
//  GLAFileCollectionViewController.m
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAFileCollectionViewController.h"
#import "GLAUIStyle.h"
#import "GLACollectionFilesListContent.h"
#import "GLACollectedFile.h"
#import "GLAFileInfoRetriever.h"


@interface GLAFileCollectionViewController ()

@property(nonatomic) GLACollectionFilesListContent *private_filesListContent;
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

- (void)setUpFileInfoRetriever
{
	GLAFileInfoRetriever *fileInfoRetriever = [GLAFileInfoRetriever new];
	(fileInfoRetriever.delegate) = self;
	
	(self.fileInfoRetriever) = fileInfoRetriever;
	
}

- (GLACollectionFilesListContent *)filesListContent
{
	return (self.private_filesListContent);
}

- (void)setFilesListContent:(GLACollectionFilesListContent *)filesListContent
{
	(self.private_filesListContent) = filesListContent;
	[self reloadSourceFiles];
}

- (void)reloadSourceFiles
{
	GLACollectionFilesListContent *filesListContent = (self.filesListContent);
	if (filesListContent) {
		(self.collectedFiles) = [(self.filesListContent) copyFiles];
	}
	else {
		(self.collectedFiles) = @[];
	}
	
	[(self.sourceFilesListTableView) reloadData];
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
	GLACollectionFilesListContent *filesListContent = (self.filesListContent);
	
	NSMutableArray *collectedFiles = [NSMutableArray array];
	for (NSURL *fileURL in fileURLs) {
		[collectedFiles addObject:[GLACollectedFile collectedFileWithFileURL:fileURL]];
	}
	[(filesListContent.filesListEditing) addChildren:collectedFiles];
	
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
