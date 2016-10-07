//
//  GLAFolderQueryResults.m
//  Blik
//
//  Created by Patrick Smith on 14/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAFolderQueryResults.h"
#import "GLAFolderQuery.h"


@interface GLAFolderQueryResults () <GLAFileInfoRetrieverDelegate>

@property(nonatomic) id<GLAFileAccessing> accessedFolder;

@property(nonatomic) MDQueryRef MDQuery;
@property(nonatomic) dispatch_queue_t resultsDispatchQueue;

@property(copy, nonatomic) NSArray *results_fileURLs;

@end

@implementation GLAFolderQueryResults

- (instancetype)initWithFolderQuery:(GLAFolderQuery *)folderQuery
{
	NSParameterAssert(folderQuery != nil);
	self = [super init];
	if (self) {
		_folderQuery = folderQuery;
		
		_resultsDispatchQueue = dispatch_queue_create("com.burntcaramel.GLAFolderQueryResults", DISPATCH_QUEUE_SERIAL);
		
		//_fileInfoRetriever = [[GLAFileInfoRetriever alloc] initWithDelegate:self defaultResourceKeysToRequest:@[NSURLEffectiveIconKey]];
	}
	return self;
}

- (void)dealloc
{
	[self clearMDQuery];
}

- (void)clearMDQuery
{
	(self.accessedFolder) = nil;
	
	MDQueryRef MDQuery = (self.MDQuery);
	if (!MDQuery) {
		return;
	}
	
	[self stopObservingMDQuery];
	
	MDQueryStop(MDQuery);
	CFRelease(MDQuery);
	(self.MDQuery) = nil;
}

- (NSArray *)sortingAttributesToQuery
{
	return @[(id)kMDItemLastUsedDate, (id)kMDItemContentCreationDate, (id)kMDItemFSContentChangeDate, (id)kMDItemFSCreationDate];
}

@synthesize sortingMethod = _sortingMethod;

- (void)setSortingMethod:(GLAFolderQueryResultsSortingMethod)sortingMethod
{
	_sortingMethod = sortingMethod;
	
	[self updateSortingMethodOnMDQuery];
	
	if (self.MDQuery) {
		[self createAndExecuteMDQuery];
	}
}

- (void)updateSortingMethodOnMDQuery
{
	MDQueryRef MDQuery = (self.MDQuery);
	if (!MDQuery) {
		return;
	}
	
	NSMutableArray *allSortingAttributes = [(self.sortingAttributesToQuery) mutableCopy];
	NSString *primarySortingAttribute = nil;
	switch (self.sortingMethod) {
		case GLAFolderQueryResultsSortingMethodDateLastOpened:
			primarySortingAttribute = (id)kMDItemLastUsedDate;
			break;
		
		case GLAFolderQueryResultsSortingMethodDateAdded:
			primarySortingAttribute = (id)kMDItemContentCreationDate;
			break;
		
		case GLAFolderQueryResultsSortingMethodDateModified:
			primarySortingAttribute = (id)kMDItemFSContentChangeDate;
			break;
			
		case GLAFolderQueryResultsSortingMethodDateCreated:
			primarySortingAttribute = (id)kMDItemFSCreationDate;
			break;
			
  default:
			break;
	}
	
	if (primarySortingAttribute) {
		// Put primary sorting attribute first.
		[allSortingAttributes removeObject:primarySortingAttribute];
		[allSortingAttributes insertObject:primarySortingAttribute atIndex:0];
	}
	
	MDQueryDisableUpdates(MDQuery);
	Boolean success = MDQuerySetSortOrder(MDQuery, (__bridge CFArrayRef)allSortingAttributes);
	MDQueryEnableUpdates(MDQuery);
#if DEBUG
	NSLog(@"MDQUERY SET SORT ORDER %@ %@", @(success), allSortingAttributes);
#endif
}

- (void)createAndExecuteMDQuery
{
	[self clearMDQuery];
	
	GLAFolderQuery *folderQuery = (self.folderQuery);
	NSString *metadataQueryString = [folderQuery fileMetadataQueryRepresentation];
	NSArray *valueListAttrs = @[(id)kMDItemPath, (id)kMDItemDisplayName,  @"kMDItemUserTags"];
	NSArray *sortingAttrs = (self.sortingAttributesToQuery);

#if DEBUG
	NSLog(@"metadataQueryString %@", metadataQueryString);
#endif
	
	MDQueryRef MDQuery = MDQueryCreate(kCFAllocatorDefault, (__bridge CFStringRef)metadataQueryString, (__bridge CFArrayRef)valueListAttrs, (__bridge CFArrayRef)sortingAttrs);
	
	MDQuerySetDispatchQueue(MDQuery, (self.resultsDispatchQueue));
	
	GLACollectedFile *collectedFileForFolderURL = (folderQuery.collectedFileForFolderURL);
	id<GLAFileAccessing> accessedFolder = [collectedFileForFolderURL accessFile];
  if (!accessedFolder) {
    // TODO: error
    return;
  }
	(self.accessedFolder) = accessedFolder;
	NSURL *folderURL = (accessedFolder.filePathURL);
	NSArray *scopeFolderPaths = @[folderURL];
	MDQuerySetSearchScope(MDQuery, (__bridge CFArrayRef)scopeFolderPaths, 0);
	//MDQuerySetSearchScope(MDQuery, (__bridge CFArrayRef)@[(__bridge id)kMDQueryScopeAllIndexed], 0);
	
	(self.MDQuery) = MDQuery;
	
	[self updateSortingMethodOnMDQuery];
	
	[self startObservingMDQuery];
	
	MDQueryExecute(MDQuery, kMDQueryWantsUpdates);
#if DEBUG
	NSLog(@"EXECUTED MDQUERY");
#endif
}

- (void)startObservingMDQuery
{
	MDQueryRef MDQuery = (self.MDQuery);
	
#if 0
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self selector:@selector(results_MDQueryHasProgressNotification:) name:(__bridge NSString *)kMDQueryProgressNotification object:(__bridge id)MDQuery];
#endif
	
	CFNotificationCenterRef localNC = CFNotificationCenterGetLocalCenter();
	
	CFNotificationCenterAddObserver(localNC, (__bridge const void *)(self), &GLAFolderQueryResults_MDQueryProgressNotification, kMDQueryProgressNotification, MDQuery, CFNotificationSuspensionBehaviorCoalesce);
	
	CFNotificationCenterAddObserver(localNC, (__bridge const void *)(self), &GLAFolderQueryResults_MDQueryDidUpdateNotification, kMDQueryDidUpdateNotification, MDQuery, CFNotificationSuspensionBehaviorCoalesce);
}

void GLAFolderQueryResults_MDQueryProgressNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	NSLog(@"kMDQueryProgressNotification");
	
	GLAFolderQueryResults *self = (__bridge id)observer;
	
	[self results_MDQueryHasProgress];
}

void GLAFolderQueryResults_MDQueryDidUpdateNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	NSLog(@"kMDQueryDidUpdateNotification");
	
	GLAFolderQueryResults *self = (__bridge id)observer;
	
	[self results_MDQueryDidUpdate];
}

- (void)stopObservingMDQuery
{
	MDQueryRef MDQuery = (self.MDQuery);
	if (!MDQuery) {
		return;
	}
	
	CFNotificationCenterRef localNC = CFNotificationCenterGetLocalCenter();
	
	CFNotificationCenterRemoveObserver(localNC, (__bridge const void *)(self), nil, MDQuery);
}

- (void)results_MDQueryHasProgress
{
	MDQueryRef MDQuery = (self.MDQuery);
#if DEBUG
	NSLog(@"MDQUERY HAS %@ RESULTS", @(MDQueryGetResultCount(MDQuery)));
#endif
	
	//NSLog(@"HAS PROGRESS %@", dispatch_get_current_queue());
	[self results_updateFileURLs];
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAFolderQueryResultsGatheringProgressNotification object:self];
	}];
}

- (void)results_MDQueryDidUpdate
{
	MDQueryRef MDQuery = (self.MDQuery);
#if DEBUG
	NSLog(@"MDQUERY DID %@ UPDATE", @(MDQueryGetResultCount(MDQuery)));
#endif
	
	//NSLog(@"HAS PROGRESS %@", dispatch_get_current_queue());
	[self results_updateFileURLs];
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAFolderQueryResultsDidUpdateNotification object:self];
	}];
}

- (void)results_updateFileURLs
{
	MDQueryRef MDQuery = (self.MDQuery);
	if (!MDQuery) {
		return;
	}
	
	CFIndex resultCount = MDQueryGetResultCount(MDQuery);
	NSMutableArray *URLs = [[NSMutableArray alloc] initWithCapacity:resultCount];
	
	for (CFIndex resultIndex = 0; resultIndex < resultCount; resultIndex++) {
		MDItemRef item = (MDItemRef)MDQueryGetResultAtIndex(MDQuery, resultIndex);
		NSString *path = CFBridgingRelease(MDItemCopyAttribute(item, kMDItemPath));
		[URLs addObject:[NSURL fileURLWithPath:path]];
		
#if 0
		NSDictionary *itemAttributes = CFBridgingRelease(MDItemCopyAttributes(item, (__bridge CFArrayRef)
  @[
	(id)kMDItemPath,
	(id)kMDItemDisplayName,
	(id)kMDItemFSContentChangeDate
	]));
		NSLog(@"Item attributes %@ %@", @(resultIndex), itemAttributes);
		NSString *path = MDQueryGetAttributeValueOfResultAtIndex(MDQuery, kMDItemDisplayName, resultIndex);
		NSLog(@"Item path %@ %@", @(resultIndex), path);
#endif
	}
	
	//NSArray *paths = (__bridge_transfer NSArray *)MDQueryCopyValuesOfAttribute(MDQuery, kMDItemPath);
	
	(self.results_fileURLs) = [URLs copy];
}

#pragma mark -

- (void)startSearching
{
	[self createAndExecuteMDQuery];
}

- (void)beginAccessingResults
{
	MDQueryRef MDQuery = (self.MDQuery);
	NSAssert(MDQuery != nil, @"Query must have been started");
	
	MDQueryDisableUpdates(MDQuery);
}

- (void)finishAccessingResults
{
	MDQueryRef MDQuery = (self.MDQuery);
	NSAssert(MDQuery != nil, @"Query must have been started");
	
	MDQueryEnableUpdates(MDQuery);
}

- (NSUInteger)resultCount
{
	MDQueryRef MDQuery = (self.MDQuery);
	if (MDQuery) {
		return MDQueryGetResultCount(MDQuery);
	}
	else {
		return 0;
	}
}

- (NSArray *)copyFileURLs
{
	__block NSArray *fileURLs;
	dispatch_sync((self.resultsDispatchQueue), ^{
		fileURLs = [(self.results_fileURLs) copy];
	});
	return fileURLs;
}

- (NSURL *)fileURLForResultAtIndex:(NSUInteger)resultIndex
{
#if 1
	__block NSURL *fileURL;
	dispatch_sync((self.resultsDispatchQueue), ^{
		fileURL = (self.results_fileURLs)[resultIndex];
	});
	return fileURL;
#else
	MDQueryRef MDQuery = (self.MDQuery);
	NSAssert(MDQuery != nil, @"Must have a MDQuery");
	
	MDItemRef item = (MDItemRef)MDQueryGetResultAtIndex(MDQuery, resultIndex);
	NSString *path = CFBridgingRelease(MDItemCopyAttribute(item, kMDItemPath));
	if (!path) {
		return nil;
	}
	
	return [NSURL URLWithString:[path copy]];
#endif
}

- (NSString *)localizedNameForResultAtIndex:(NSUInteger)resultIndex
{
	MDQueryRef MDQuery = (self.MDQuery);
	NSAssert(MDQuery != nil, @"Must have a MDQuery");
	
	CFStringRef displayNameCF = MDQueryGetAttributeValueOfResultAtIndex(MDQuery, kMDItemDisplayName, resultIndex);
	if (!displayNameCF) {
		return nil;
	}
	
	NSString *displayName = (__bridge NSString *)displayNameCF;
	return [displayName copy];
}

#if 0

- (NSImage *)copyEffectiveIconForResultAtIndex:(NSUInteger)resultIndex withSizeDimension:(CGFloat)sizeDimension
{
	NSURL *fileURL = [self fileURLForResultAtIndex:resultIndex];
	if (!fileURL) {
		return nil;
	}
	
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	return [fileInfoRetriever effectiveIconImageForURL:fileURL withSizeDimension:sizeDimension];
}

#endif

@end

NSString *GLAFolderQueryResultsGatheringProgressNotification = @"GLAFolderQueryResultsGatheringProgressNotification";
NSString *GLAFolderQueryResultsDidUpdateNotification = @"GLAFolderQueryResultsDidUpdateNotification";
