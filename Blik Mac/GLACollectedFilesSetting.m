//
//  GLACollectedFilesSetting.m
//  Blik
//
//  Created by Patrick Smith on 3/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectedFilesSetting.h"
#import "GLAModelUUIDMap.h"
#import "GLADirectoryWatcher.h"
#import "GLAFolderQuery.h"


@interface GLACollectedFilesSetting () <GLAFileInfoRetrieverDelegate>

@property(nonatomic) GLADirectoryWatcher *directoryWatcher;

@property(nonatomic) dispatch_queue_t inputDispatchQueue;

@property(nonatomic) NSMutableSet *collectedFileUUIDsUsingURLs;
@property(nonatomic) GLAModelUUIDMap *collectedFileUUIDMap;

@property(nonatomic) NSMutableDictionary *collectedFileUUIDsToAccessedFileInfos;
@property(nonatomic) NSMutableDictionary *retrievedURLsToCollectedFileUUIDs;
@property(nonatomic) NSOperationQueue *backgroundOperationQueue;

@property(nonatomic) NSMutableDictionary *infoIdentifiersToRetrieverBlocks;
@property(nonatomic) NSCache *collectedFileUUIDsToDictionaryOfInfoIdentifiersToLastRetrievedValues;
@property(nonatomic) NSCache *fileURLsToCollectedFileUUIDs;

@end

@implementation GLACollectedFilesSetting

- (instancetype)init
{
	self = [super init];
	if (self) {
		_collectedFileUUIDsUsingURLs = [NSMutableSet new];
		_collectedFileUUIDMap = [GLAModelUUIDMap new];
		_collectedFileUUIDsToAccessedFileInfos = [NSMutableDictionary new];
		_retrievedURLsToCollectedFileUUIDs = [NSMutableDictionary new];
		
		_inputDispatchQueue = dispatch_queue_create("com.burntcaramel.GLACollectedFilesSetting.input", DISPATCH_QUEUE_SERIAL);
		
		_fileInfoRetriever = [[GLAFileInfoRetriever alloc] initWithDelegate:self];
		
		NSOperationQueue *backgroundOperationQueue = [NSOperationQueue new];
		(backgroundOperationQueue.maxConcurrentOperationCount) = 1;
		_backgroundOperationQueue = backgroundOperationQueue;
		
		_infoIdentifiersToRetrieverBlocks = [NSMutableDictionary new];
		_collectedFileUUIDsToDictionaryOfInfoIdentifiersToLastRetrievedValues = [NSCache new];
		
		[self startObservingApplication];
	}
	return self;
}

- (void)dealloc
{
	[self stopAccessingAllCollectedFilesWaitingUntilDone];
	[self stopObservingApplication];
}

#pragma mark - Queue Convenience

- (void)runAsyncOnInputQueue:(void (^)(GLACollectedFilesSetting *self))block
{
	__weak GLACollectedFilesSetting *weakSelf = self;
	dispatch_async((self.inputDispatchQueue), ^{
		GLACollectedFilesSetting *strongSelf = weakSelf;
		if (!strongSelf) {
			return;
		}
		
		block(strongSelf);
	});
}

- (void)runAsyncInBackground:(void (^)(GLACollectedFilesSetting *self))block
{
	__weak GLACollectedFilesSetting *weakSelf = self;
	
	[(self.backgroundOperationQueue) addOperationWithBlock:^{
		GLACollectedFilesSetting *strongSelf = weakSelf;
		if (!strongSelf) {
			return;
		}
		
		block(strongSelf);
	}];
}

#pragma mark -

- (void)setDirectoryURLsToWatch:(NSSet *)directoryURLsToWatch
{
	if (!_directoryWatcher) {
		_directoryWatcher = [GLADirectoryWatcher new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(directoryWatcherDirectoriesDidChangeNotification:) name:GLADirectoryWatcherDirectoriesDidChangeNotification object:_directoryWatcher];
	}
	
	directoryURLsToWatch = [directoryURLsToWatch copy];
	_directoryURLsToWatch = directoryURLsToWatch;
	(_directoryWatcher.directoryURLsToWatch) = directoryURLsToWatch;
}

- (void)directoryWatcherDirectoriesDidChangeNotification:(NSNotification *)note
{
	[self invalidateAllAccessedFiles];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLACollectedFilesSettingDirectoriesDidChangeNotification object:self];
}

- (void)startObservingApplication
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillBecomeActive:) name:NSApplicationWillBecomeActiveNotification object:NSApp];
}

- (void)stopObservingApplication
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillBecomeActiveNotification object:NSApp];
}

- (void)applicationWillBecomeActive:(NSNotification *)note
{
	// Update when application becomes active to ensure all files are up to date.
	[self directoryWatcherDirectoriesDidChangeNotification:nil];
}

#pragma mark -

- (void)input_startAccessingCollectedFile:(GLACollectedFile *)collectedFile invalidate:(BOOL)invalidate
{
	if (collectedFile.empty) {
		return;
	}
	
	NSMutableSet *collectedFileUUIDsUsingURLs = (self.collectedFileUUIDsUsingURLs);
	
	NSUUID *collectedFileUUID = (collectedFile.UUID);
	
	BOOL resolve = invalidate;
	
	if (![collectedFileUUIDsUsingURLs containsObject:collectedFileUUID]) {
		[collectedFileUUIDsUsingURLs addObject:collectedFileUUID];
		[(self.collectedFileUUIDMap) addObjects:@[collectedFile]];
		
		resolve = YES;
	}
	
	if (resolve) {
		[self runAsyncInBackground:^(GLACollectedFilesSetting *self) {
			GLAAccessedFileInfo *accessedFileInfo = [collectedFile accessFile];
			NSURL *filePathURL = (accessedFileInfo.filePathURL);
			if (filePathURL) {
				[(self.fileInfoRetriever) requestDefaultResourceKeysForURL:filePathURL alwaysNotify:YES];
			}
			
			[self runAsyncOnInputQueue:^(GLACollectedFilesSetting *self) {
				// If has been since been told to stop accessing since, bail.
				if (![collectedFileUUIDsUsingURLs containsObject:collectedFileUUID]) {
					return;
				}
				
				NSMutableDictionary *collectedFileUUIDsToAccessedFileInfos = (self.collectedFileUUIDsToAccessedFileInfos);
				collectedFileUUIDsToAccessedFileInfos[collectedFileUUID] = accessedFileInfo;
				
				if (filePathURL) {
					(self.retrievedURLsToCollectedFileUUIDs)[filePathURL] = collectedFileUUID;
				}
			}];
		}];
	}
}

- (void)input_stopAccessingCollectedFile:(GLACollectedFile *)collectedFile
{
	NSMutableSet *collectedFileUUIDsUsingURLs = (self.collectedFileUUIDsUsingURLs);
	
	NSUUID *collectedFileUUID = (collectedFile.UUID);
	
	if ([collectedFileUUIDsUsingURLs containsObject:collectedFileUUID]) {
		GLAAccessedFileInfo *accessedFileInfo = [self input_accessedFileInfoForCollectedFileUUID:collectedFileUUID];
		if (accessedFileInfo) {
			NSURL *filePathURL = (accessedFileInfo.filePathURL);
			if (filePathURL) {
				[(self.retrievedURLsToCollectedFileUUIDs) removeObjectForKey:filePathURL];
			}
		}
		
		[collectedFileUUIDsUsingURLs removeObject:collectedFileUUID];
		[(self.collectedFileUUIDMap) removeObjects:@[collectedFile]];
		
		[(self.collectedFileUUIDsToAccessedFileInfos) removeObjectForKey:collectedFileUUID];
	}
}

- (void)startAccessingCollectedFile:(GLACollectedFile *)collectedFile
{
	[self startAccessingCollectedFile:collectedFile invalidate:NO];
}

- (void)startAccessingCollectedFile:(GLACollectedFile *)collectedFile invalidate:(BOOL)invalidate
{
	//NSAssert(![collectedFile isEmpty], @"Collected file must have something");
	
	[self runAsyncOnInputQueue:^(GLACollectedFilesSetting *self) {
		[self input_startAccessingCollectedFile:collectedFile invalidate:invalidate];
	}];
}

- (void)stopAccessingCollectedFile:(GLACollectedFile *)collectedFile
{
	[self runAsyncOnInputQueue:^(GLACollectedFilesSetting *self) {
		[self input_stopAccessingCollectedFile:collectedFile];
	}];
}

- (void)stopAccessingAllCollectedFilesWaitingUntilDone
{
	dispatch_sync((self.inputDispatchQueue), ^{
		NSMutableSet *collectedFileUUIDsUsingURLs = (self.collectedFileUUIDsUsingURLs);
		[collectedFileUUIDsUsingURLs removeAllObjects];
		[(self.collectedFileUUIDMap) removeAllObjects];
		[(self.collectedFileUUIDsToAccessedFileInfos) removeAllObjects];
		[(self.retrievedURLsToCollectedFileUUIDs) removeAllObjects];
	});
}

- (void)startAccessingCollectedFilesStoppingRemainders:(NSArray *)collectedFiles
{
	[self runAsyncOnInputQueue:^(GLACollectedFilesSetting *self) {
		GLACollectedFilesSetting *selfForBlock = self;
		
		[(self.collectedFileUUIDMap) setObjects:collectedFiles additionsAndRemovalsBlock:^(NSArray *additions, NSArray *removals) {
			for (GLACollectedFile *collectedFile in additions) {
				[selfForBlock startAccessingCollectedFile:collectedFile];
			}
			
			for (GLACollectedFile *collectedFile in removals) {
				[selfForBlock stopAccessingCollectedFile:collectedFile];
			}
		}];
	}];
}

- (void)startAccessingCollectedFilesStoppingRemainders:(NSArray *)collectedFiles invalidateAll:(BOOL)invalidateAll
{
	[self runAsyncOnInputQueue:^(GLACollectedFilesSetting *self) {
		GLACollectedFilesSetting *selfForBlock = self;
		
		[(self.collectedFileUUIDMap) setObjects:collectedFiles additionsAndRemovalsBlock:^(NSArray *additions, NSArray *removals) {
			if (!invalidateAll) {
				for (GLACollectedFile *collectedFile in additions) {
					[selfForBlock input_startAccessingCollectedFile:collectedFile invalidate:YES];
				}
			}
			
			for (GLACollectedFile *collectedFile in removals) {
				[selfForBlock input_stopAccessingCollectedFile:collectedFile];
			}
		}];
		
		if (invalidateAll) {
			for (GLACollectedFile *collectedFile in collectedFiles) {
				[selfForBlock input_startAccessingCollectedFile:collectedFile invalidate:YES];
			}
		}
	}];
}

- (void)setSourceCollectedFilesLoadableArray:(id<GLALoadableArrayUsing>)sourceCollectedFilesLoadableArray
{
	_sourceCollectedFilesLoadableArray = sourceCollectedFilesLoadableArray;
	
	if (sourceCollectedFilesLoadableArray) {
		__weak GLACollectedFilesSetting *weakSelf = self;
		(sourceCollectedFilesLoadableArray.changeCompletionBlock) = ^(id<GLAArrayInspecting>arrayInspector) {
			__strong GLACollectedFilesSetting *strongSelf = weakSelf;
			if (!strongSelf) {
				return;
			}
			
			NSArray *collectedFiles = [arrayInspector copyChildren];
			[strongSelf startAccessingCollectedFilesStoppingRemainders:collectedFiles];
		};
		
		NSArray *collectedFiles = [sourceCollectedFilesLoadableArray copyChildrenLoadingIfNeeded];
		[self startAccessingCollectedFilesStoppingRemainders:collectedFiles];
	}
}

#pragma mark -

- (void)invalidateAllAccessedFiles
{
	[(self.fileInfoRetriever) clearCacheForAllURLs];
	
	[self runAsyncOnInputQueue:^(GLACollectedFilesSetting *self) {
		NSArray *allCollectedFiles = (self.collectedFileUUIDMap.allObjects);
		for (GLACollectedFile *collectedFile in allCollectedFiles) {
			[self input_startAccessingCollectedFile:collectedFile invalidate:YES];
		}
	}];
}

#pragma mark -

- (NSArray *)defaultURLResourceKeysToRequest
{
	return (self.fileInfoRetriever.defaultResourceKeysToRequest);
}

- (void)setDefaultURLResourceKeysToRequest:(NSArray *)defaultURLResourceKeysToRequest
{
	(self.fileInfoRetriever.defaultResourceKeysToRequest) = defaultURLResourceKeysToRequest;
}

- (void)addToDefaultURLResourceKeysToRequest:(NSArray *)resourceKeys
{
	(self.defaultURLResourceKeysToRequest) = [(self.defaultURLResourceKeysToRequest) arrayByAddingObjectsFromArray:resourceKeys];
}

- (void)addRetrieverBlockForFileInfo:(GLACollectedFilesSettingFileInfoRetriever)retrieverBlock withIdentifier:(NSString *)infoIdentifier
{
	[self runAsyncOnInputQueue:^(GLACollectedFilesSetting *self) {
		NSMutableDictionary *infoIdentifiersToRetrieverBlocks = (self.infoIdentifiersToRetrieverBlocks);
		infoIdentifiersToRetrieverBlocks[infoIdentifier] = retrieverBlock;
	}];
}

- (GLAAccessedFileInfo *)input_accessedFileInfoForCollectedFileUUID:(NSUUID *)collectedFileUUID
{
	NSMutableDictionary *collectedFileUUIDsToAccessedFileInfos = (self.collectedFileUUIDsToAccessedFileInfos);
	return collectedFileUUIDsToAccessedFileInfos[collectedFileUUID];
}

- (GLACollectedFile *)collectedFileForFilePathURL:(NSURL *)filePathURL
{
	NSUUID *collectedFileUUID = (self.retrievedURLsToCollectedFileUUIDs)[filePathURL];
	if (!collectedFileUUID) {
		return nil;
	}
	
	GLAModelUUIDMap *collectedFileUUIDMap = (self.collectedFileUUIDMap);
	return collectedFileUUIDMap[collectedFileUUID];
}

- (GLAAccessedFileInfo *)accessedFileInfoForCollectedFile:(GLACollectedFile *)collectedFile
{
	__block GLAAccessedFileInfo *accessedFileInfo = nil;
	dispatch_sync((self.inputDispatchQueue), ^{
		accessedFileInfo = [self input_accessedFileInfoForCollectedFileUUID:(collectedFile.UUID)];
	});
	
	return accessedFileInfo;
}

- (NSURL *)filePathURLForCollectedFile:(GLACollectedFile *)collectedFile
{
	GLAAccessedFileInfo *accessedFileInfo = [self accessedFileInfoForCollectedFile:collectedFile];
	if (!accessedFileInfo) {
		return nil;
	}
	
	return (accessedFileInfo.filePathURL);
}

- (id)copyValueUsingRetrieverBlock:(GLACollectedFilesSettingFileInfoRetriever)retrieverBlock infoIdentifier:(NSString *)infoIdentifier forCollectedFile:(GLACollectedFile *)collectedFile
{
	__block id valueToReturn = nil;
	
	dispatch_sync((self.inputDispatchQueue), ^{
		NSUUID *collectedFileUUID = (collectedFile.UUID);
		
		GLACollectedFilesSettingFileInfoRetriever retrieverBlockToUse = retrieverBlock;
		if (!retrieverBlockToUse) {
			// Get info retriever block
			NSMutableDictionary *infoIdentifiersToRetrieverBlocks = (self.infoIdentifiersToRetrieverBlocks);
			retrieverBlockToUse = infoIdentifiersToRetrieverBlocks[infoIdentifier];
			if (!retrieverBlockToUse) {
				return;
			}
		}
		
		// Get accessed file.
		GLAAccessedFileInfo *accessedFileInfo = [self input_accessedFileInfoForCollectedFileUUID:collectedFileUUID];
		if (!accessedFileInfo) {
			return;
		}
		
		GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
		NSURL *fileURL = (accessedFileInfo.filePathURL);
		if (!fileURL) {
			return;
		}
		NSAssert(fileURL != nil, @"Accessed file must have a URL");
		
		valueToReturn = retrieverBlockToUse(fileInfoRetriever, fileURL);
		
		// Get last retrieved values from cache.
		NSCache *collectedFileUUIDsToDictionaryOfInfoIdentifiersToLastRetrievedValues = (self.collectedFileUUIDsToDictionaryOfInfoIdentifiersToLastRetrievedValues);
		NSMutableDictionary *infoIdentifiersToLastRetrievedValues = [collectedFileUUIDsToDictionaryOfInfoIdentifiersToLastRetrievedValues objectForKey:collectedFileUUID];
		if (!infoIdentifiersToLastRetrievedValues) {
			// Add a new mutable dictionary to the cache for the collected file.
			infoIdentifiersToLastRetrievedValues = [NSMutableDictionary new];
			[collectedFileUUIDsToDictionaryOfInfoIdentifiersToLastRetrievedValues setObject:infoIdentifiersToLastRetrievedValues forKey:collectedFileUUID];
		}
		
		// If a value was found, update the cache with it.
		if (valueToReturn) {
			infoIdentifiersToLastRetrievedValues[infoIdentifier] = valueToReturn;
		}
		// Otherwise, use the last retrieved value from the cache.
		else {
			valueToReturn = infoIdentifiersToLastRetrievedValues[infoIdentifier];
		}
	});
	
	return valueToReturn;
}

- (id)copyValueForURLResourceKey:(NSString *)resourceKey forCollectedFile:(GLACollectedFile *)collectedFile
{
	return [self copyValueUsingRetrieverBlock:^id(GLAFileInfoRetriever *fileInfoRetriever, NSURL *fileURL) {
		return [fileInfoRetriever resourceValueForKey:resourceKey forURL:fileURL];
	} infoIdentifier:resourceKey forCollectedFile:collectedFile];
}

- (id)copyValueForFileInfoIdentifier:(NSString *)infoIdentifier forCollectedFile:(GLACollectedFile *)collectedFile
{
	return [self copyValueUsingRetrieverBlock:nil infoIdentifier:infoIdentifier forCollectedFile:collectedFile];
}

- (void)notifyLoadedFileInfoDidChangeForFilePathURL:(NSURL *)filePathURL
{
	GLACollectedFile *collectedFile = [self collectedFileForFilePathURL:filePathURL];
	if (!collectedFile) {
		return;
	}
	
	NSDictionary *userInfo =
	@{
	  GLACollectedFilesSettingLoadedFileInfoDidChangeNotification_CollectedFile: collectedFile
	  };
	
	NSNotification *note = [NSNotification notificationWithName:GLACollectedFilesSettingLoadedFileInfoDidChangeNotification object:self userInfo:userInfo];
	[[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostASAP coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender) forModes:@[NSRunLoopCommonModes]];
}

#pragma mark - GLAFileInfoRetrieverDelegate

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)URL
{
#if 0 && DEBUG
	NSLog(@"didLoadResourceValuesForURL %@", URL);
#endif
	[self notifyLoadedFileInfoDidChangeForFilePathURL:URL];
}

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL
{
	
}

@end

NSString *GLACollectedFilesSettingDirectoriesDidChangeNotification = @"GLACollectedFilesSettingDirectoriesDidChangeNotification";
NSString *GLACollectedFilesSettingLoadedFileInfoDidChangeNotification = @"GLACollectedFilesSettingLoadedFileInfoDidChangeNotification";
NSString *GLACollectedFilesSettingLoadedFileInfoDidChangeNotification_CollectedFile = @"GLACollectedFilesSettingLoadedFileInfoDidChangeNotification_CollectedFile";


@implementation GLACollectedFilesSetting (UIConvenience)

- (void)setUpTableCellView:(NSTableCellView *)cellView forTableColumn:(NSTableColumn *)tableColumn collectedFile:(GLACollectedFile *)collectedFile
{
	NSString *displayName = nil;
	NSImage *iconImage = nil;
	BOOL hasImageView = (cellView.imageView != nil);
	
	if (collectedFile) {
		if (collectedFile.empty) {
			displayName = NSLocalizedString(@"(Gone)", @"Display Name for empty collected file");
		}
		else {
			displayName = [self copyValueForURLResourceKey:NSURLLocalizedNameKey forCollectedFile:collectedFile];
			if (hasImageView) {
				iconImage = [self copyValueForURLResourceKey:NSURLEffectiveIconKey forCollectedFile:collectedFile];
			}
		}
	}
	
	(cellView.textField.stringValue) = displayName ?: @"Loading…";
	if (hasImageView) {
		(cellView.imageView.image) = iconImage;
	}
}

- (void)setUpMenuItem:(NSMenuItem *)menuItem forOptionalCollectedFile:(GLACollectedFile *)collectedFile wantsIcon:(BOOL)wantsIcon
{
	NSString *displayName = nil;
	NSImage *iconImage = nil;
	
	if (collectedFile) {
		if (collectedFile.empty) {
			displayName = NSLocalizedString(@"(Gone)", @"Display Name for empty collected file");
		}
		else {
			displayName = [self copyValueForURLResourceKey:NSURLLocalizedNameKey forCollectedFile:collectedFile];
			if (wantsIcon) {
				iconImage = [self copyValueForURLResourceKey:NSURLEffectiveIconKey forCollectedFile:collectedFile];
				if (iconImage) {
					iconImage = [iconImage copy];
					[iconImage setSize:NSMakeSize(16.0, 16.0)];
				}
			}
		}
	}
	
	(menuItem.title) = displayName ?: @"Loading…";
	if (wantsIcon) {
		(menuItem.image) = iconImage;
	}
}

@end
