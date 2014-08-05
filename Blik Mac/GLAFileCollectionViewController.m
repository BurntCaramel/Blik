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


@interface GLAFileCollectionViewController ()

@property(nonatomic) GLACollectionFilesListContent *private_filesListContent;
@property(copy, nonatomic) NSArray *collectedFiles;

@property(nonatomic) NSMutableSet *accessedSecurityScopedURLs;

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
	[[GLAUIStyle activeStyle] prepareContentTableView:tableView];
	
	[self reloadSourceFiles];
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

- (void)viewWillDisappear
{
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
	
	[self addAccessedSecurityScopedFileURL:(collectedFile.URL)];
	
	return collectedFile;
}

#pragma mark Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	
	GLACollectedFile *collectedFile = (self.collectedFiles)[row];
	//NSString *displayName = (project.name);
	NSString *displayName = @"hello";
	(cellView.objectValue) = collectedFile;
	//(cellView.textField.stringValue) = displayName;
	(cellView.textField.stringValue) = (collectedFile.URL.path);
	
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

@end
