//
//  GLAFolderQueryResults.m
//  Blik
//
//  Created by Patrick Smith on 14/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAFolderQueryResults.h"
#import "GLAFolderQuery.h"


@interface GLAFolderQueryResults ()

@property(nonatomic) MDQueryRef MDQuery;
@property(nonatomic) dispatch_queue_t resultsDispatchQueue;

@property(copy, nonatomic) NSArray *results_fileURLs;

@end

@implementation GLAFolderQueryResults

- (instancetype)initWithFolderQuery:(GLAFolderQuery *)folderQuery folderURLs:(NSArray *)folderURLs
{
	self = [super init];
	if (self) {
		_folderQuery = folderQuery;
		_folderURLs = [folderURLs copy];
		
		_resultsDispatchQueue = dispatch_queue_create("com.burntcaramel.GLAFolderQueryResults", DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

- (void)clearMDQuery
{
	MDQueryRef MDQuery = (self.MDQuery);
	if (!MDQuery) {
		return;
	}
	
	MDQueryStop(MDQuery);
	CFRelease(MDQuery);
}

- (void)createAndExecuteMDQuery
{
	[self clearMDQuery];
	
	GLAFolderQuery *folderQuery = (self.folderQuery);
	NSString *metadataQueryString = [folderQuery fileMetadataQueryRepresentation];
	NSArray *valueListAttrs = @[(__bridge NSString *)kMDItemPath, (__bridge NSString *)kMDItemDisplayName,  @"kMDItemUserTags"];
	NSArray *sortingAttrs = @[(__bridge NSString *)kMDItemFSContentChangeDate];

#if DEBUG
	NSLog(@"metadataQueryString %@", metadataQueryString);
#endif
	
	MDQueryRef MDQuery = MDQueryCreate(kCFAllocatorDefault, (__bridge CFStringRef)metadataQueryString, (__bridge CFArrayRef)valueListAttrs, (__bridge CFArrayRef)sortingAttrs);
	
	MDQuerySetDispatchQueue(MDQuery, (self.resultsDispatchQueue));
	
#if 0
	NSURL *folderURL = (folderQuery.folderURL);
	NSArray *scopeFolderPaths = @[folderURL];
	//MDQuerySetSearchScope(MDQuery, (__bridge CFArrayRef)scopeFolderPaths, 0);
	MDQuerySetSearchScope(MDQuery, (__bridge CFArrayRef)@[(__bridge id)kMDQueryScopeAllIndexed], 0);
	
	(self.MDQuery) = MDQuery;
	
	[self startObservingMDQuery];
	
	MDQueryExecute(MDQuery, kMDQueryWantsUpdates);
#if DEBUG
	NSLog(@"EXECUTED MDQUERY");
#endif
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
	NSLog(@"ADDING MD OBSERVER self: %p MDQuery %p", self, MDQuery);
	CFNotificationCenterAddObserver(localNC, (__bridge const void *)(self), &GLAFolderQueryResults_MDQueryProgressNotification, kMDQueryProgressNotification, MDQuery, CFNotificationSuspensionBehaviorCoalesce);
}

void GLAFolderQueryResults_MDQueryProgressNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	NSLog(@"MDQueryProgressNotification");
	
	GLAFolderQueryResults *self = (__bridge id)observer;
	
	//disp
	[self results_MDQueryHasProgress];
}

- (void)stopObservingMDQuery
{
	MDQueryRef MDQuery = (self.MDQuery);
	//CFNotificationCenterRef localNC = CFNotificationCenterGetLocalCenter();
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc removeObserver:self name:nil object:(__bridge id)MDQuery];
}

- (void)results_MDQueryHasProgress
{
	//NSLog(@"HAS PROGRESS %@", dispatch_get_current_queue());
	[self results_updateFileURLs];
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		NSLog(@"QUERY RESULTS: %@", [self copyFileURLs]);
	}];
}

- (void)results_updateFileURLs
{
	MDQueryRef MDQuery = (self.MDQuery);
	if (!MDQuery) {
		return;
	}
	
	NSArray *paths = (__bridge_transfer NSArray *)MDQueryCopyValuesOfAttribute(MDQuery, kMDItemPath);
	
	NSMutableArray *URLs = [NSMutableArray new];
	for (NSString *path in paths) {
		[URLs addObject:[NSURL fileURLWithPath:path]];
	}
	
	(self.results_fileURLs) = URLs;
}

#pragma mark -

- (void)startSearching
{
	[self createAndExecuteMDQuery];
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
	MDQueryRef MDQuery = (self.MDQuery);
	NSAssert(MDQuery != nil, @"Must have a MDQuery");
	
	CFStringRef pathCF = MDQueryGetAttributeValueOfResultAtIndex(MDQuery, kMDItemPath, resultIndex);
	if (!pathCF) {
		return nil;
	}
	
	NSString *path = (__bridge NSString *)pathCF;
	return [NSURL URLWithString:[path copy]];
}

- (NSString *)copyLocalizedNameForResultAtIndex:(NSUInteger)resultIndex
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

@end

NSString *GLAFolderQueryResultsDidUpdateNotification = @"GLAFolderQueryResultsDidUpdateNotification";