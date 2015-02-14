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


@interface GLACollectedFilesSetting () <GLAFileInfoRetrieverDelegate>

@property(nonatomic) GLADirectoryWatcher *directoryWatcher;

@property(nonatomic) dispatch_queue_t inputDispatchQueue;

@property(nonatomic) NSMutableSet *collectedFileUUIDsUsingURLs;
@property(nonatomic) GLAModelUUIDMap *collectedFileUUIDMap;

@property(nonatomic) NSMutableDictionary *collectedFileUUIDsToAccessedFileInfos;
@property(nonatomic) NSOperationQueue *backgroundOperationQueue;

@property(nonatomic) GLAFileInfoRetriever *fileInfoRetriever;

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
		
		_inputDispatchQueue = dispatch_queue_create("com.burntcaramel.GLACollectedFilesSetting.input", DISPATCH_QUEUE_SERIAL);
		
		_fileInfoRetriever = [[GLAFileInfoRetriever alloc] initWithDelegate:self];
		
		NSOperationQueue *backgroundOperationQueue = [NSOperationQueue new];
		(backgroundOperationQueue.maxConcurrentOperationCount) = 1;
		_backgroundOperationQueue = backgroundOperationQueue;
		
		_infoIdentifiersToRetrieverBlocks = [NSMutableDictionary new];
		_collectedFileUUIDsToDictionaryOfInfoIdentifiersToLastRetrievedValues = [NSCache new];
	}
	return self;
}

- (void)dealloc
{
	[self stopAccessingAllCollectedFilesWaitingUntilDone];
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
#if DEBUG
	NSLog(@"directoryWatcherDirectoriesDidChangeNotification");
#endif
	[self invalidateAllAccessedFiles];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLACollectedFilesSettingDirectoriesDidChangeNotification object:self];
}

#pragma mark -

- (void)input_startAccessingCollectedFile:(GLACollectedFile *)collectedFile invalidate:(BOOL)invalidate
{
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
				[(self.fileInfoRetriever) requestDefaultResourceKeysForURL:filePathURL];
			}
			
			[self runAsyncOnInputQueue:^(GLACollectedFilesSetting *self) {
				// If has been since been told to stop accessing since, bail.
				if (![collectedFileUUIDsUsingURLs containsObject:collectedFileUUID]) {
					return;
				}
				
				NSMutableDictionary *collectedFileUUIDsToAccessedFileInfos = (self.collectedFileUUIDsToAccessedFileInfos);
				collectedFileUUIDsToAccessedFileInfos[collectedFileUUID] = accessedFileInfo;
			}];
		}];
	}
}

- (void)input_stopAccessingCollectedFile:(GLACollectedFile *)collectedFile
{
	NSMutableSet *collectedFileUUIDsUsingURLs = (self.collectedFileUUIDsUsingURLs);
	
	NSUUID *collectedFileUUID = (collectedFile.UUID);
	
	if ([collectedFileUUIDsUsingURLs containsObject:collectedFileUUID]) {
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

- (GLAAccessedFileInfo *)accessedFileInfoForCollectedFile:(GLACollectedFile *)collectedFile
{
	__block GLAAccessedFileInfo *accessFileInfo = nil;
	dispatch_sync((self.inputDispatchQueue), ^{
		NSMutableDictionary *collectedFileUUIDsToAccessedFileInfos = (self.collectedFileUUIDsToAccessedFileInfos);
		accessFileInfo = collectedFileUUIDsToAccessedFileInfos[(collectedFile.UUID)];
	});
	
	return accessFileInfo;
}

- (NSURL *)copyFileURLForCollectedFileWithUUID:(NSUUID *)collectedFileUUID
{
	__block NSURL *filePathURL = nil;
	dispatch_sync((self.inputDispatchQueue), ^{
		NSMutableDictionary *collectedFileUUIDsToAccessedFileInfos = (self.collectedFileUUIDsToAccessedFileInfos);
		GLAAccessedFileInfo *accessFileInfo = collectedFileUUIDsToAccessedFileInfos[collectedFileUUID];
		if (accessFileInfo) {
			filePathURL = (accessFileInfo.filePathURL);
		}
	});
	
	return filePathURL;
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
		NSMutableDictionary *collectedFileUUIDsToAccessedFileInfos = (self.collectedFileUUIDsToAccessedFileInfos);
		GLAAccessedFileInfo *accessedFileInfo = collectedFileUUIDsToAccessedFileInfos[collectedFileUUID];
		if (!accessedFileInfo) {
			return;
		}
		
		GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
		NSURL *fileURL = (accessedFileInfo.filePathURL);
		
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

- (void)notifyLoadedFileInfoDidChange
{
	NSNotification *note = [NSNotification notificationWithName:GLACollectedFilesSettingLoadedFileInfoDidChangeNotification object:self];
	[[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostASAP coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender) forModes:@[NSRunLoopCommonModes]];
}

#pragma mark - GLAFileInfoRetrieverDelegate

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)URL
{
#if DEBUG
	NSLog(@"didLoadResourceValuesForURL %@", URL);
#endif
	[self notifyLoadedFileInfoDidChange];
}

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL
{
	
}

@end

NSString *GLACollectedFilesSettingDirectoriesDidChangeNotification = @"GLACollectedFilesSettingDirectoriesDidChangeNotification";
NSString *GLACollectedFilesSettingLoadedFileInfoDidChangeNotification = @"GLACollectedFilesSettingLoadedFileInfoDidChangeNotification";
