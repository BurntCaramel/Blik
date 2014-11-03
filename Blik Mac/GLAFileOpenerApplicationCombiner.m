//
//  GLAFileURLOpenerApplicationCombiner.m
//  Blik
//
//  Created by Patrick Smith on 3/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAFileOpenerApplicationCombiner.h"


@interface GLAFileOpenerApplicationCombiner () <GLAFileInfoRetrieverDelegate>

@property(readwrite, nonatomic) GLAFileInfoRetriever *fileInfoRetriever;

@property(nonatomic) NSMutableSet *mutableFileURLs;

@property(nonatomic) NSMutableDictionary *URLsToOpenerApplicationURLs;
@property(nonatomic) NSMutableDictionary *URLsToDefaultOpenerApplicationURL;

@property(nonatomic) NSUInteger combinedCountSoFar;
@property(nonatomic) NSMutableSet *mutableCombinedOpenerApplicationURLs;
@property(nonatomic) NSURL *combinedDefaultOpenerApplicationURL;

- (void)recombineAllFileURLs;

@end

@implementation GLAFileOpenerApplicationCombiner

- (instancetype)init
{
	self = [super init];
	if (self) {
		[self setUpFileInfoRetriever];
	}
	return self;
}

- (void)setUpFileInfoRetriever
{
	GLAFileInfoRetriever *fileInfoRetriever = [GLAFileInfoRetriever new];
	(fileInfoRetriever.delegate) = self;
	
	(self.fileInfoRetriever) = fileInfoRetriever;
}

- (void)addFileURLs:(NSSet *)fileURLsSet
{
	[(self.mutableFileURLs) unionSet:fileURLsSet];
	
	for (NSURL *fileURL in fileURLsSet) {
		[self combineOpenerApplicationURLsForFileURL:fileURL loadIfNeeded:YES];
	}
}

- (void)removeFileURLs:(NSSet *)fileURLsSet
{
	[(self.mutableFileURLs) minusSet:fileURLsSet];
	
	[self recombineAllFileURLs];
}

- (BOOL)hasFileURL:(NSURL *)fileURL
{
	return [(self.mutableFileURLs) containsObject:fileURL];
}

- (NSSet *)fileURLs
{
	return [(self.mutableFileURLs) copy];
}

- (void)setFileURLs:(NSSet *)fileURLs
{
	NSMutableSet *mutableFileURLs = (self.mutableFileURLs);
	
	NSMutableSet *fileURLsBeingAdded = [fileURLs mutableCopy];
	[fileURLsBeingAdded minusSet:mutableFileURLs];
	
	NSMutableSet *fileURLsBeingRemoved = [mutableFileURLs mutableCopy];
	[fileURLsBeingRemoved minusSet:fileURLs];
	
	BOOL isRemoving = (fileURLsBeingRemoved.count) > 0;
	BOOL isAdding = (fileURLsBeingAdded.count) > 0;
	
	if (isRemoving) {
		[mutableFileURLs minusSet:fileURLsBeingRemoved];
	}
	
	if (isAdding) {
		[mutableFileURLs unionSet:fileURLsBeingAdded];
	}
	
	if (isRemoving) {
		[self recombineAllFileURLs];
	}
	else if (isAdding) {
		for (NSURL *fileURL in fileURLsBeingAdded) {
			[self combineOpenerApplicationURLsForFileURL:fileURL loadIfNeeded:YES];
		}
	}
}

#pragma mark -

- (void)clearCombinedApplicationURLs
{
	(self.combinedCountSoFar) = 0;
	
	NSMutableSet *mutableCombinedOpenerApplicationURLs = (self.mutableCombinedOpenerApplicationURLs);
	if (mutableCombinedOpenerApplicationURLs) {
		[mutableCombinedOpenerApplicationURLs removeAllObjects];
	}
}

- (void)combineOpenerApplicationURLsForFileURL:(NSURL *)URL loadIfNeeded:(BOOL)load
{
	NSMutableDictionary *URLsToOpenerApplicationURLs = (self.URLsToOpenerApplicationURLs);
	NSArray *applicationURLs = URLsToOpenerApplicationURLs ? URLsToOpenerApplicationURLs[URL] : nil;
	
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	
	if (!applicationURLs) {
		if (load) {
			[fileInfoRetriever requestApplicationURLsToOpenURL:URL];
		}
		return;
	}
	
	NSURL *defaultOpenerApplicationURL = [fileInfoRetriever defaultApplicationURLToOpenURL:URL];
	
	NSMutableSet *mutableCombinedOpenerApplicationURLs = (self.mutableCombinedOpenerApplicationURLs);
	if (!mutableCombinedOpenerApplicationURLs) {
		mutableCombinedOpenerApplicationURLs = (self.mutableCombinedOpenerApplicationURLs) = [NSMutableSet new];
	}
	
	if ((self.combinedCountSoFar) == 0) {
		[mutableCombinedOpenerApplicationURLs addObjectsFromArray:applicationURLs];
		(self.combinedDefaultOpenerApplicationURL) = defaultOpenerApplicationURL;
		
		[self didChangeCombinedOpenerApplicationURLs];
	}
	else {
		NSUInteger countBefore = (mutableCombinedOpenerApplicationURLs.count);
		[mutableCombinedOpenerApplicationURLs intersectSet:[NSSet setWithArray:applicationURLs]];
		NSUInteger countAfter = (mutableCombinedOpenerApplicationURLs.count);
		
		if (defaultOpenerApplicationURL != (self.combinedDefaultOpenerApplicationURL)) {
			(self.combinedDefaultOpenerApplicationURL) = nil;
		}
		
		if (countBefore != countAfter) {
			[self didChangeCombinedOpenerApplicationURLs];
		}
	}
	
	(self.combinedCountSoFar)++;
}

- (void)recombineAllFileURLs
{
	[self clearCombinedApplicationURLs];
	
	NSSet *fileURLs = (self.fileURLs);
	for (NSURL *fileURL in fileURLs) {
		[self combineOpenerApplicationURLsForFileURL:fileURL loadIfNeeded:YES];
	}
}

- (void)didChangeCombinedOpenerApplicationURLs
{
	NSNotification *note = [NSNotification notificationWithName:GLAFileURLOpenerApplicationCombinerDidChangeNotification object:self];
	[[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostWhenIdle];
}

#pragma mark File Info Retriever Delegate

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didRetrieveApplicationURLsToOpenURL:(NSURL *)URL
{
	NSMutableDictionary *URLsToOpenerApplicationURLs = (self.URLsToOpenerApplicationURLs);
	if (!URLsToOpenerApplicationURLs) {
		URLsToOpenerApplicationURLs = (self.URLsToOpenerApplicationURLs) = [NSMutableDictionary new];
	}
	
	NSArray *applicationURLs = [fileInfoRetriever applicationsURLsToOpenURL:URL];
	URLsToOpenerApplicationURLs[URL] = applicationURLs;
	
	NSMutableDictionary *URLsToDefaultOpenerApplicationURL = (self.URLsToDefaultOpenerApplicationURL);
	if (!URLsToDefaultOpenerApplicationURL) {
		URLsToDefaultOpenerApplicationURL = (self.URLsToDefaultOpenerApplicationURL) = [NSMutableDictionary new];
	}
	
	NSURL *defaultApplicationURL = [fileInfoRetriever defaultApplicationURLToOpenURL:URL];
	URLsToDefaultOpenerApplicationURL[URL] = defaultApplicationURL;
	
	if ([self hasFileURL:URL]) {
		[self combineOpenerApplicationURLsForFileURL:URL loadIfNeeded:NO];
	}
}

#pragma mark -

+ (void)openFileURLs:(NSArray *)fileURLs withApplicationURL:(NSURL *)applicationURL
{
	LSLaunchURLSpec launchURLSpec = {
		.appURL =  (__bridge CFURLRef)(applicationURL),
		.itemURLs = (__bridge CFArrayRef)fileURLs,
		.passThruParams = NULL,
		.launchFlags = kLSLaunchDefaults,
		.asyncRefCon = NULL
	};
	
	LSOpenFromURLSpec(&launchURLSpec, NULL);
}

@end

NSString *GLAFileURLOpenerApplicationCombinerDidChangeNotification = @"GLAFileURLOpenerApplicationCombinerDidChangeNotification";
