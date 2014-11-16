//
//  GLACollectedFilesSetting.m
//  Blik
//
//  Created by Patrick Smith on 3/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectedFilesSetting.h"


@interface GLACollectedFilesSetting ()

@property(nonatomic) NSMutableSet *collectedFileUUIDsUsingURLs;
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
	}
	return self;
}

#pragma mark -

- (void)startAccessingSecurityScopedFileURL:(NSURL *)URL
{
	NSMutableSet *accessedSecurityScopedURLs = (self.accessedSecurityScopedURLs);
	if (!accessedSecurityScopedURLs) {
		(self.accessedSecurityScopedURLs) = accessedSecurityScopedURLs = [NSMutableSet new];
	}
	
	if (![accessedSecurityScopedURLs containsObject:URL]) {
		[URL startAccessingSecurityScopedResource];
		[accessedSecurityScopedURLs addObject:URL];
	}
}

- (void)stopAccessingSecurityScopedFileURL:(NSURL *)URL
{
	NSMutableSet *accessedSecurityScopedURLs = (self.accessedSecurityScopedURLs);
	if (!accessedSecurityScopedURLs) {
		return;
	}
	
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
	
	if (![collectedFileUUIDsUsingURLs containsObject:collectedFile]) {
		[collectedFileUUIDsUsingURLs addObject:collectedFile];
		
		NSURL *fileURL = (collectedFile.URL);
		NSAssert(fileURL != nil, @"Collected file must have a URL.");
		[self startAccessingSecurityScopedFileURL:fileURL];
	}
}

- (void)stopUsingURLForCollectedFile:(GLACollectedFile *)collectedFile
{
	NSMutableSet *collectedFileUUIDsUsingURLs = (self.collectedFileUUIDsUsingURLs);
	
	if ([collectedFileUUIDsUsingURLs containsObject:collectedFile]) {
		[collectedFileUUIDsUsingURLs removeObject:collectedFile];
		
		NSURL *fileURL = (collectedFile.URL);
		NSAssert(fileURL != nil, @"Collected file must have a URL.");
		[self stopAccessingSecurityScopedFileURL:fileURL];
	}
}

- (void)stopUsingURLsForAllCollectedFiles
{
	NSMutableSet *collectedFileUUIDsUsingURLs = (self.collectedFileUUIDsUsingURLs);
	[collectedFileUUIDsUsingURLs removeAllObjects];
	
	[self stopAccessingAllSecurityScopedFileURLs];
}

@end
