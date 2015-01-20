//
//  GLACollectedFileTableViewHelper.m
//  Blik
//
//  Created by Patrick Smith on 18/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLACollectedFileListHelper.h"

@implementation GLACollectedFileListHelper

- (instancetype)initWithDelegate:(id<GLACollectedFileListHelperDelegate>)delegate
{
	self = [super init];
	if (self) {
		_delegate = delegate;
		_fileInfoRetriever = [[GLAFileInfoRetriever alloc] initWithDelegate:self];
	}
	return self;
}

- (void)setUpTableCellView:(NSTableCellView *)cellView forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLACollectedFile *collectedFile = (self.collectedFiles)[row];
	(cellView.objectValue) = collectedFile;
	
	NSString *displayName = nil;
	NSImage *iconImage = nil;
	
	if (collectedFile.isMissing) {
		displayName = NSLocalizedString(@"(Missing)", @"Displayed name when a collected file is missing");
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
}

#pragma mark File Info Retriever Delegate

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)fileURL
{
	NSIndexSet *indexesToUpdate = [(self.collectedFiles) indexesOfObjectsPassingTest:^BOOL(GLACollectedFile *collectedFile, NSUInteger idx, BOOL *stop) {
		return [fileURL isEqual:(collectedFile.filePathURL)];
	}];

	id<GLACollectedFileListHelperDelegate> delegate = (self.delegate);
	[delegate collectedFileListHelper:self didLoadInfoForCollectedFilesAtIndexes:indexesToUpdate];
}

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL
{

}

@end
