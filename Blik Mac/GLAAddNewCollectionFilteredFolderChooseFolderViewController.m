//
//  GLAAddNewCollectionFilteredFolderChooseFolderViewController.m
//  Blik
//
//  Created by Patrick Smith on 18/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAAddNewCollectionFilteredFolderChooseFolderViewController.h"
#import "GLAUIStyle.h"
#import "GLAFileInfoRetriever.h"
#import "PGWSQueuedBlockConvenience.h"


@interface GLAAddNewCollectionFilteredFolderChooseFolderViewController () <GLAFileInfoRetrieverDelegate>

@property(readwrite, nonatomic) NSURL *chosenFolderURL;
@property(readwrite, copy, nonatomic) NSString *chosenTagName;

@property(nonatomic) GLAFileInfoRetriever *fileInfoRetriever;

@property(nonatomic) dispatch_queue_t backgroundDispatchQueue;

@property(nonatomic) NSArray *sortedAvailableTagNames;

@end

@implementation GLAAddNewCollectionFilteredFolderChooseFolderViewController

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	
	(self.chosenFolderNameField.stringValue) = @"";
	
	[style prepareSecondaryInstructionalTextLabel:(self.chooseFolderLabel)];
	[style prepareSecondaryInstructionalTextLabel:(self.chooseTagLabel)];
	[style prepareContentTextField:(self.chosenFolderNameField)];
	
	GLAFileInfoRetriever *fileInfoRetriever = [[GLAFileInfoRetriever alloc] initWithDelegate:self defaultResourceKeysToRequest:@[NSURLLocalizedNameKey, NSURLEffectiveIconKey]];
	(self.fileInfoRetriever) = fileInfoRetriever;
	
	_backgroundDispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	[self updateUIForChosenFolder];
	[self updateUIForAvailableTags];
	[self updateUIForCanProgress];
}

- (void)prepareForReuse
{
	(self.chosenFolderURL) = nil;
	(self.chosenTagName) = nil;
	
	[self updateUIForChosenFolder];
	[self updateUIForAvailableTags];
	[self updateUIForCanProgress];
}

- (void)viewWillTransitionIn
{
	[self prepareForReuse];
}

- (void)reloadTagsForChosenFolder
{
	(self.chosenTagName) = nil;
	
	[self updateUIForAvailableTags];
	[self updateUIForCanProgress];
	
	NSURL *folderURL = (self.chosenFolderURL);
	[self pgws_useReceiverAsyncOnDispatchQueue:(self.backgroundDispatchQueue) block:^(GLAAddNewCollectionFilteredFolderChooseFolderViewController *self) {
		NSSet *tagNamesSet = [GLAFolderQuery availableTagNamesInsideFolderURL:folderURL];
		NSArray *tagNamesSorted = [[tagNamesSet allObjects] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			// If the folder URL has changed since, then bail.
			if (! [(self.chosenFolderURL) isEqual:folderURL]) {
				return;
			}
			
			(self.sortedAvailableTagNames) = tagNamesSorted;
			[self updateUIForAvailableTags];
			[self updateUIForCanProgress];
		}];
	}];
}

- (void)updateUIForChosenFolder
{
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	NSURL *folderURL = (self.chosenFolderURL);
	BOOL hasChosenFolder = (folderURL != nil);
	
	NSString *localizedName = @"";
	NSImage *iconImage = nil;
	
	if (hasChosenFolder) {
		localizedName = [fileInfoRetriever localizedNameForURL:folderURL];
		iconImage = [fileInfoRetriever effectiveIconImageForURL:folderURL withSizeDimension:16.0];
	}
	
	(self.chosenFolderNameField.stringValue) = localizedName;
	(self.chosenFolderIconImageView.image) = iconImage;
}

- (void)updateUIForAvailableTags
{
	NSArray *sortedAvailableTagNames = (self.sortedAvailableTagNames);
	BOOL hasLoadedTags = (sortedAvailableTagNames != nil);
	BOOL hasChosenFolder = (self.chosenFolderURL != nil);
	
	NSMenu *menu = (self.chooseTagPopUpButton.menu);
	[menu removeAllItems];
	
	if (sortedAvailableTagNames) {
		for (NSString *tagName in sortedAvailableTagNames) {
			[menu addItemWithTitle:tagName action:nil keyEquivalent:@""];
		}
	}
	else {
		NSString *title = NSLocalizedString(@"Loading…", @"Text when tags are loading from chosen folder.");
		[menu addItemWithTitle:title action:nil keyEquivalent:@""];
	}
	
	(self.chooseTagLabel.hidden) = !(hasLoadedTags && hasChosenFolder);
	(self.chooseTagPopUpButton.hidden) = !(hasChosenFolder);
	(self.chooseTagPopUpButton.enabled) = (hasLoadedTags && hasChosenFolder);
	
	[self chosenTagNameDidChange:self];
}

- (void)updateUIForCanProgress
{
	BOOL canGoNext = (self.chosenFolderURL != nil) && (self.chosenTagName != nil);
	(self.nextButton.enabled) = canGoNext;
}

- (void)setChosenFolderURL:(NSURL *)folderURL
{
	_chosenFolderURL = folderURL;
	
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	// We only care about one folder's URL, so can clear the cache here.
	[fileInfoRetriever clearCacheForAllURLs];
	
	if (folderURL) {
		[fileInfoRetriever requestDefaultResourceKeysForURL:folderURL alwaysNotify:YES];
		
		[self reloadTagsForChosenFolder];
	}
}

- (IBAction)chooseFolder:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	(openPanel.canChooseFiles) = NO;
	(openPanel.canChooseDirectories) = YES;
	(openPanel.allowsMultipleSelection) = NO;
	
	NSString *chooseString = NSLocalizedString(@"Choose Folder", @"NSOpenPanel button for choosing folder to use in a filtered folder collection.");
	(openPanel.title) = chooseString;
	(openPanel.prompt) = chooseString;
	
	[openPanel beginWithCompletionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			NSURL *folderURL = (openPanel.URL);
			(self.chosenFolderURL) = folderURL;
		}
	}];
}

- (IBAction)chosenTagNameDidChange:(id)sender
{
	NSString *chosenTagName = nil;
	
	NSInteger chosenTagIndex = (self.chooseTagPopUpButton.indexOfSelectedItem);
	if (chosenTagIndex != -1) {
		NSArray *tagNames = (self.sortedAvailableTagNames);
		if (tagNames.count > 0) {
			chosenTagName = tagNames[chosenTagIndex];
		}
	}
	
	(self.chosenTagName) = chosenTagName;
	
	[self updateUIForCanProgress];
}

- (IBAction)goToNextSection:(id)sender
{
	[(self.sectionNavigator) addNewFilteredFolderCollectionGoToChooseNameAndColorWithChosenFolder:(self.chosenFolderURL) chosenTagName:(self.chosenTagName)];
}

#pragma mark -

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)URL
{
	[self updateUIForChosenFolder];
}

@end
