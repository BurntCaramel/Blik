//
//  GLACollectedFilesSetting.m
//  Blik
//
//  Created by Patrick Smith on 3/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectedFilesSetting.h"
#import "GLAModelUUIDMap.h"


@interface GLACollectedFilesSetting ()

@property(nonatomic) NSMutableSet *collectedFileUUIDsUsingURLs;
@property(nonatomic) GLAModelUUIDMap *collectedFileUUIDMap;
@property(nonatomic) NSMutableSet *accessedSecurityScopedURLs;

- (void)startAccessingSecurityScopedFileURL:(NSURL *)URL;
- (void)stopAccessingSecurityScopedFileURL:(NSURL *)URL;
- (void)stopAccessingAllSecurityScopedFileURLs;

@end

@implementation GLACollectedFilesSetting

- (instancetype)init
{
	self = [super init];
	if (self) {
		_collectedFileUUIDsUsingURLs = [NSMutableSet new];
		_collectedFileUUIDMap = [GLAModelUUIDMap new];
		_accessedSecurityScopedURLs = [NSMutableSet new];
	}
	return self;
}

#pragma mark -

- (void)startAccessingSecurityScopedFileURL:(NSURL *)URL
{
	NSMutableSet *accessedSecurityScopedURLs = (self.accessedSecurityScopedURLs);
	
	if (![accessedSecurityScopedURLs containsObject:URL]) {
		if ([URL startAccessingSecurityScopedResource]) {
			[accessedSecurityScopedURLs addObject:URL];
		}
	}
}

- (void)stopAccessingSecurityScopedFileURL:(NSURL *)URL
{
	NSMutableSet *accessedSecurityScopedURLs = (self.accessedSecurityScopedURLs);
	
	if ([accessedSecurityScopedURLs containsObject:URL]) {
		[URL stopAccessingSecurityScopedResource];
		[accessedSecurityScopedURLs removeObject:URL];
	}
}

- (void)stopAccessingAllSecurityScopedFileURLs
{
	NSMutableSet *accessedSecurityScopedURLs = (self.accessedSecurityScopedURLs);
	if (accessedSecurityScopedURLs) {
		for (NSURL *URL in accessedSecurityScopedURLs) {
			[URL stopAccessingSecurityScopedResource];
		}
		[accessedSecurityScopedURLs removeAllObjects];
	}
}

#pragma mark -

- (void)startUsingURLForCollectedFile:(GLACollectedFile *)collectedFile
{
	NSMutableSet *collectedFileUUIDsUsingURLs = (self.collectedFileUUIDsUsingURLs);
	
	NSUUID *collectedFileUUID = (collectedFile.UUID);
	
	if (![collectedFileUUIDsUsingURLs containsObject:collectedFileUUID]) {
		[collectedFileUUIDsUsingURLs addObject:collectedFileUUID];
		[(self.collectedFileUUIDMap) addObjects:@[collectedFile]];
		
		NSURL *fileReferenceURL = (collectedFile.filePathURL);
		NSAssert(fileReferenceURL != nil, @"Collected file must have a URL.");
		[self startAccessingSecurityScopedFileURL:fileReferenceURL];
		
		NSURL *filePathURL = (collectedFile.filePathURL);
		NSAssert(filePathURL != nil, @"Collected file must have a URL.");
		[self startAccessingSecurityScopedFileURL:filePathURL];
	}
}

- (void)stopUsingURLForCollectedFile:(GLACollectedFile *)collectedFile
{
	NSMutableSet *collectedFileUUIDsUsingURLs = (self.collectedFileUUIDsUsingURLs);
	
	if ([collectedFileUUIDsUsingURLs containsObject:collectedFile]) {
		[collectedFileUUIDsUsingURLs removeObject:collectedFile];
		[(self.collectedFileUUIDMap) removeObjects:@[collectedFile]];
		
		NSURL *fileReferenceURL = (collectedFile.filePathURL);
		NSAssert(fileReferenceURL != nil, @"Collected file must have a URL.");
		[self stopAccessingSecurityScopedFileURL:fileReferenceURL];
		
		NSURL *filePathURL = (collectedFile.filePathURL);
		NSAssert(filePathURL != nil, @"Collected file must have a URL.");
		[self stopAccessingSecurityScopedFileURL:filePathURL];
	}
}

- (void)stopUsingURLsForAllCollectedFiles
{
	[self stopAccessingAllSecurityScopedFileURLs];
	
	NSMutableSet *collectedFileUUIDsUsingURLs = (self.collectedFileUUIDsUsingURLs);
	[collectedFileUUIDsUsingURLs removeAllObjects];
	[(self.collectedFileUUIDMap) removeAllObjects];
}

- (void)startUsingURLsForCollectedFilesRemovingRemainders:(NSArray *)collectedFiles
{
	GLACollectedFilesSetting *selfForBlock = self;
	
	[(self.collectedFileUUIDMap) setObjects:collectedFiles additionsAndRemovalsBlock:^(NSArray *additions, NSArray *removals) {
		for (GLACollectedFile *collectedFile in additions) {
			[selfForBlock startUsingURLForCollectedFile:collectedFile];
		}
		
		for (GLACollectedFile *collectedFile in removals) {
			[selfForBlock stopUsingURLForCollectedFile:collectedFile];
		}
	}];
}

@end
