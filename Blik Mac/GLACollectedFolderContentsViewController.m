//
//  GLACollectedFolderContentViewController.m
//  Blik
//
//  Created by Patrick Smith on 10/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLACollectedFolderContentsViewController.h"
#import "GLAFileInfoRetriever.h"
#import "GLAArrangedDirectoryChildren.h"
#import "GLAUIStyle.h"
#import "GLAQuickLookPreviewHelper.h"


@interface GLACollectedFolderContentsViewController () <GLAFileInfoRetrieverDelegate, GLAArrangedDirectoryChildrenDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, GLAQuickLookPreviewHelperDelegate>

@property(nonatomic) GLAFileInfoRetriever *fileInfoRetriever;
@property(nonatomic) NSMutableDictionary *directoryURLToArrangedChildren;

@property(nonatomic) NSDateFormatter *dateFormatter;

@property(nonatomic) GLAQuickLookPreviewHelper *quickLookPreviewHelper;

@end

@implementation GLACollectedFolderContentsViewController

- (instancetype)init
{
	return [self initWithNibName:[self className] bundle:nil];
}

- (void)prepareView
{
	[self insertIntoResponderChain];
	
	NSArray *defaultResourceKeys =
	@[
	  NSURLIsDirectoryKey,
	  NSURLIsPackageKey,
	  NSURLIsRegularFileKey,
	  NSURLIsSymbolicLinkKey,
	  NSURLLocalizedNameKey,
	  NSURLEffectiveIconKey,
	  NSURLIsHiddenKey,
	  NSURLContentModificationDateKey
	  ];
	_fileInfoRetriever = [[GLAFileInfoRetriever alloc] initWithDelegate:self defaultResourceKeysToRequest:defaultResourceKeys];
	
	_resourceKeyToSortBy = NSURLLocalizedNameKey;
	_sortsAscending = YES;
	_hidesInvisibles = YES;
	
	_directoryURLToArrangedChildren = [NSMutableDictionary new];
	
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	
	NSOutlineView *folderContentOutlineView = (self.folderContentOutlineView);
	
	NSSortDescriptor *nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSURLLocalizedNameKey ascending:YES];
	NSSortDescriptor *dateModifiedSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSURLContentModificationDateKey ascending:NO];
	[[folderContentOutlineView tableColumnWithIdentifier:@"displayNameAndIcon"] setSortDescriptorPrototype:nameSortDescriptor];
	[[folderContentOutlineView tableColumnWithIdentifier:@"dateModified"] setSortDescriptorPrototype:dateModifiedSortDescriptor];
	(folderContentOutlineView.sortDescriptors) = @[nameSortDescriptor];
	
	// Individually autosaves each folder by URL.
	(folderContentOutlineView.autosaveTableColumns) = YES;
	(folderContentOutlineView.autosaveExpandedItems) = YES;
	(folderContentOutlineView.autosaveName) = [NSString stringWithFormat:@"collectedFolderContentsOutlineView-%@", (self.sourceDirectoryURL.path)];
	
	[self updateSortingFromOutlineView];
	
	(folderContentOutlineView.dataSource) = self;
	(folderContentOutlineView.delegate) = self;
	[style prepareContentTableView:folderContentOutlineView];
	
	NSDateFormatter *dateFormatter = [NSDateFormatter new];
	(dateFormatter.dateStyle) = NSDateFormatterMediumStyle;
	(dateFormatter.timeStyle) = NSDateFormatterShortStyle;
	(dateFormatter.doesRelativeDateFormatting) = YES;
	_dateFormatter = dateFormatter;
	
	[self reloadContentsOfFolder];
	
	_quickLookPreviewHelper = [GLAQuickLookPreviewHelper new];
	(_quickLookPreviewHelper.delegate) = self;
	(_quickLookPreviewHelper.tableView) = folderContentOutlineView;
}

- (void)dealloc
{
	
}

#pragma mark -

- (void)setSourceDirectoryURL:(NSURL *)sourceDirectoryURL
{
	if (sourceDirectoryURL) {
		sourceDirectoryURL = [sourceDirectoryURL copy];
	}
	_sourceDirectoryURL = sourceDirectoryURL;
	
	[self reloadContentsOfFolder];
	
}

- (void)reloadContentsOfFolder
{
	[(self.folderContentOutlineView) reloadData];
	
#if DEBUG && 0
	NSLog(@"outline view size %@", NSStringFromSize(self.folderContentOutlineView.fittingSize));
#endif
}

- (void)updateSortingFromOutlineView
{
	NSArray *sortDescriptors = (self.folderContentOutlineView.sortDescriptors);
	if (sortDescriptors && (sortDescriptors.count) > 0) {
		NSSortDescriptor *firstSortDescriptor = sortDescriptors[0];
		
		NSString *sortingKey = (firstSortDescriptor.key);
		(self.resourceKeyToSortBy) = sortingKey;
		(self.sortsAscending) = (firstSortDescriptor.ascending);
		
		[self updateAllArrangedChildrenWithSortingOptions];
	}
}

- (NSArray *)arrangedChildrenForDirectoryURL:(NSURL *)directoryURL
{
	NSMutableDictionary *directoryURLToArrangedChildren = (self.directoryURLToArrangedChildren);
	GLAArrangedDirectoryChildren *arrangedChildren = directoryURLToArrangedChildren[directoryURL];
	
	if (!arrangedChildren) {
		arrangedChildren = [[GLAArrangedDirectoryChildren alloc] initWithDirectoryURL:directoryURL delegate:self fileInfoRetriever:(self.fileInfoRetriever)];
		directoryURLToArrangedChildren[directoryURL] = arrangedChildren;
		
		[self updateArrangedChildrenWithSortingOptions:arrangedChildren];
	}
	
	return (arrangedChildren.arrangedChildren);
}

- (void)updateArrangedChildrenWithSortingOptions:(GLAArrangedDirectoryChildren *)arrangedChildren
{
	[arrangedChildren updateAfterEditingOptions:^(id<GLAArrangedDirectoryChildrenOptionEditing> editor) {
		(editor.resourceKeyToSortBy) = (self.resourceKeyToSortBy);
		(editor.sortsAscending) = (self.sortsAscending);
		(editor.hidesInvisibles) = (self.hidesInvisibles);
	}];
}

- (void)updateAllArrangedChildrenWithSortingOptions
{
	NSMutableDictionary *directoryURLToArrangedChildren = (self.directoryURLToArrangedChildren);
	
	for (GLAArrangedDirectoryChildren *arrangedChildren in (directoryURLToArrangedChildren.allValues)) {
		[self updateArrangedChildrenWithSortingOptions:arrangedChildren];
	}
}

#pragma mark GLAFileInfoRetriever

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didRetrieveContentsOfDirectoryURL:(NSURL *)directoryURL
{
	
}

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error retrievingContentsOfDirectoryURL:(NSURL *)directoryURL
{
	if ([directoryURL isEqual:(self.sourceDirectoryURL)]) {
		[(self.folderContentOutlineView) reloadData];
	}
	else {
		[(self.folderContentOutlineView) reloadItem:directoryURL reloadChildren:YES];
	}
}

#pragma mark

- (void)arrangedDirectoryChildrenDidUpdateChildren:(GLAArrangedDirectoryChildren *)arrangedDirectoryChildren
{
	NSURL *directoryURL = (arrangedDirectoryChildren.directoryURL);
	
	if ([directoryURL isEqual:(self.sourceDirectoryURL)]) {
		[(self.folderContentOutlineView) reloadData];
	}
	else {
		[(self.folderContentOutlineView) reloadItem:directoryURL reloadChildren:YES];
	}
}

#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	
	NSURL *directoryURL;
	if (item == nil) {
		directoryURL = (self.sourceDirectoryURL);
		if (!directoryURL) {
			return 0;
		}
	}
	else {
		directoryURL = (NSURL *)item;
	}
	
	NSArray *childURLs = [self arrangedChildrenForDirectoryURL:directoryURL];
	if (childURLs) {
		return (childURLs.count);
	}
	else {
		NSError *errorLoadingChildURLs = [fileInfoRetriever errorRetrievingChildURLsOfDirectoryWithURL:directoryURL];
		if (errorLoadingChildURLs) {
			// TODO: present error some way.
		}
		
		return 0;
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	
	NSURL *fileURL = (NSURL *)item;
	
	NSNumber *isRegularFileValue = [fileInfoRetriever resourceValueForKey:NSURLIsRegularFileKey forURL:fileURL];
	NSNumber *isPackageValue = [fileInfoRetriever resourceValueForKey:NSURLIsPackageKey forURL:fileURL];
	
	if (isRegularFileValue != nil && isPackageValue != nil) {
		BOOL isRegularFile = [isRegularFileValue isEqual:@YES];
		BOOL isPackage = [isPackageValue isEqual:@YES];
		BOOL treatAsFile = (isRegularFile || isPackage);
		return (!treatAsFile);
	}
	
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	NSURL *directoryURL;
	if (item == nil) {
		directoryURL = (self.sourceDirectoryURL);
	}
	else {
		directoryURL = (NSURL *)item;
	}
	
	NSArray *childURLs = [self arrangedChildrenForDirectoryURL:directoryURL];
	if (childURLs) {
		return childURLs[index];
	}
	else {
		return [NSNull null];
	}
}

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	[self updateSortingFromOutlineView];
}

#pragma mark NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSString *identifier = (tableColumn.identifier);
	NSTableCellView *cellView = [outlineView makeViewWithIdentifier:identifier owner:nil];
	
	NSURL *fileURL = (NSURL *)item;
	
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	
	if ([identifier isEqualToString:@"displayNameAndIcon"]) {
		NSString *displayName = nil;
		NSImage *iconImage = nil;
		BOOL hasImageView = (cellView.imageView != nil);
		
		displayName = [fileInfoRetriever resourceValueForKey:NSURLLocalizedNameKey forURL:fileURL];
		if (hasImageView) {
			iconImage = [fileInfoRetriever resourceValueForKey:NSURLEffectiveIconKey forURL:fileURL];
		}
		
		(cellView.textField.stringValue) = displayName ?: @"Loading…";
		if (hasImageView) {
			(cellView.imageView.image) = iconImage;
		}
	}
	else if ([identifier isEqualToString:@"dateModified"]) {
		NSDate *dateModified = [fileInfoRetriever resourceValueForKey:NSURLContentModificationDateKey forURL:fileURL];
		NSDateFormatter *dateFormatter = (self.dateFormatter);
		
		(cellView.textField.stringValue) = [dateFormatter stringFromDate:dateModified];
	}
	
	return cellView;
}

#pragma mark GLAQuickLookPreviewHelper

- (NSArray *)selectedURLsForQuickLookPreviewHelper:(GLAQuickLookPreviewHelper *)helper
{
	NSOutlineView *folderContentOutlineView = (self.folderContentOutlineView);
	
	NSIndexSet *selectedRowIndexes = (folderContentOutlineView.selectedRowIndexes);
	NSMutableArray *selectedURLs = [NSMutableArray new];
	[selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger rowIndex, BOOL *stop) {
		NSURL *fileURL = [folderContentOutlineView itemAtRow:rowIndex];
		[selectedURLs addObject:fileURL];
	}];
	
	return selectedURLs;
}

- (NSInteger)quickLookPreviewHelper:(GLAQuickLookPreviewHelper *)helper tableRowForSelectedURL:(NSURL *)fileURL
{
	NSOutlineView *folderContentOutlineView = (self.folderContentOutlineView);
	
	return [folderContentOutlineView rowForItem:fileURL];
}

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel
{
#if DEBUG
	NSLog(@"gg acceptsPreviewPanelControl");
#endif
	return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
	GLAQuickLookPreviewHelper *quickLookPreviewHelper = (self.quickLookPreviewHelper);
	
	[quickLookPreviewHelper beginPreviewPanelControl:panel];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
	GLAQuickLookPreviewHelper *quickLookPreviewHelper = (self.quickLookPreviewHelper);
	
	[quickLookPreviewHelper endPreviewPanelControl:panel];
}

- (void)quickLookPreviewItems:(id)sender
{
	GLAQuickLookPreviewHelper *quickLookPreviewHelper = (self.quickLookPreviewHelper);
	
	[quickLookPreviewHelper quickLookPreviewItems:sender];
}

#pragma mark Events

- (void)keyDown:(NSEvent *)theEvent
{
	unichar u = [(theEvent.charactersIgnoringModifiers) characterAtIndex:0];
	
	if (u == NSCarriageReturnCharacter || u == NSEnterCharacter) {
#if 0
		if (modifierFlags & NSCommandKeyMask) {
			[self revealSelectedFilesInFinder:self];
		}
		else {
			[self openSelectedFiles:self];
		}
#endif
	}
	else if (u == ' ') {
		[self quickLookPreviewItems:self];
	}
}

@end
