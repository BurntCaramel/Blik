//
//  GLAFileURLInfoRetriever.m
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAFileURLInfoRetriever.h"


@interface GLAFileURLInfoRetriever ()

@property(readonly, nonatomic) NSOperationQueue *backgroundOperationQueue;
@property(readonly, nonatomic) dispatch_queue_t inputDispatchQueue;

@property(readonly, nonatomic) NSMutableDictionary *URLsToMutableSetOfRequestedResourceKeys;
@property(readonly, nonatomic) NSMutableDictionary *URLsToMutableSetOfLoadingResourceKeys;
@property(readonly, nonatomic) NSMutableDictionary *URLsToLoadingErrors;
//@property(readonly, nonatomic) NSMutableDictionary *URLsToCacheOfResourceValues;
@property(readonly, nonatomic) NSCache *cacheOfURLsToMutableDictionaryOfResourceValues;

@end

@implementation GLAFileURLInfoRetriever

- (instancetype)init
{
	self = [super init];
	if (self) {
		_backgroundOperationQueue = [NSOperationQueue new];
		_inputDispatchQueue = dispatch_queue_create("com.burntcaramel.GLACollectionFile.input", DISPATCH_QUEUE_SERIAL);
		
		_URLsToMutableSetOfRequestedResourceKeys = [NSMutableDictionary new];
		_URLsToMutableSetOfLoadingResourceKeys = [NSMutableDictionary new];
		_URLsToLoadingErrors = [NSMutableDictionary new];
		//_URLsToCacheOfResourceValues = [NSMutableDictionary new];
		_cacheOfURLsToMutableDictionaryOfResourceValues = [NSCache new];
	}
	return self;
}

+ (instancetype)sharedFileInfoRetrieverForMainQueue
{
	static GLAFileURLInfoRetriever *instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [GLAFileURLInfoRetriever new];
	});
	
	return instance;
}

- (void)addRequestedResourceKeys:(NSArray *)resourceKeys forURL:(NSURL *)URL
{
	dispatch_async((self.inputDispatchQueue), ^{
		NSMutableSet *set = (self.URLsToMutableSetOfRequestedResourceKeys)[URL];
		[set addObjectsFromArray:resourceKeys];
	});
}

- (NSSet *)requestedResourceKeysNeedingLoadingForURL:(NSURL *)URL setAreLoading:(BOOL)setAreLoading
{
	__block NSMutableSet *resourceKeysToLoad = nil;
	
	dispatch_sync((self.inputDispatchQueue), ^{
		NSMutableSet *requestedResourceKeysSet = (self.URLsToMutableSetOfRequestedResourceKeys)[URL];
		
		resourceKeysToLoad = [requestedResourceKeysSet mutableCopy];
		
		NSMutableSet *loadingResourceKeys = (self.URLsToMutableSetOfLoadingResourceKeys)[URL];
		if (loadingResourceKeys) {
			[resourceKeysToLoad minusSet:loadingResourceKeys];
		}
		
		NSMutableDictionary *loadedResourceValues = [(self.cacheOfURLsToMutableDictionaryOfResourceValues) objectForKey:URL];
		if (loadedResourceValues) {
			[resourceKeysToLoad minusSet:[NSSet setWithArray:(loadedResourceValues.allKeys)]];
		}
		
		if (setAreLoading && (resourceKeysToLoad.count) > 0) {
			NSMutableSet *loadingResourceKeys = (self.URLsToMutableSetOfLoadingResourceKeys)[URL];
			[loadingResourceKeys unionSet:resourceKeysToLoad];
		}
	});
	
	return resourceKeysToLoad;
}

- (void)loadMissingResourceValuesInBackgroundForURL:(NSURL *)URL
{
	__weak GLAFileURLInfoRetriever *weakSelf = self;
	
	[(self.backgroundOperationQueue) addOperationWithBlock:^{
		GLAFileURLInfoRetriever *self = weakSelf;
		if (!self) {
			return;
		}
		
		NSSet *resourceKeysToLoad = [self requestedResourceKeysNeedingLoadingForURL:URL setAreLoading:YES];
		if (!resourceKeysToLoad || (resourceKeysToLoad.count) == 0) {
			return;
		}
		
		NSError *error = nil;
		// This blocks, the whole reason why this is all in a background queue.
		NSDictionary *loadedResourceValues = [URL resourceValuesForKeys:[resourceKeysToLoad allObjects] error:&error];
		
		dispatch_async((self.inputDispatchQueue), ^{
			GLAFileURLInfoRetriever *self = weakSelf;
			if (!self) {
				return;
			}
			
			if (loadedResourceValues) {
				NSCache *cache = (self.cacheOfURLsToMutableDictionaryOfResourceValues);
				NSMutableDictionary *existingResourceValues = [cache objectForKey:URL];
				if (!existingResourceValues) {
					existingResourceValues = [NSMutableDictionary new];
				}
				[existingResourceValues addEntriesFromDictionary:loadedResourceValues];
				[cache setObject:existingResourceValues forKey:URL];
			}
			// Else error happened:
			else {
				NSMutableDictionary *URLsToLoadingErrors = (self.URLsToLoadingErrors);
				URLsToLoadingErrors[URL] = error;
			}
			
			// Call the callback;
			GLAFileURLInfoRetrieverLoadedCallback loadedCallback = (self.loadedCallback);
			if (loadedCallback) {
				(loadedCallback)(self, URL, error);
			}
		});
	}];
}

#pragma mark

- (void)requestResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL
{
	[self addRequestedResourceKeys:keys forURL:URL];
	[self loadMissingResourceValuesInBackgroundForURL:URL];
}

- (NSDictionary *)loadedResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL
{
	__block NSDictionary *returnedDictionary = nil;
	
	dispatch_sync((self.inputDispatchQueue), ^{
		NSCache *cache = (self.cacheOfURLsToMutableDictionaryOfResourceValues);
		NSMutableDictionary *existingResourceValues = [cache objectForKey:URL];
		returnedDictionary = (existingResourceValues ? [existingResourceValues copy] : nil);
	});
	
	return returnedDictionary;
}

- (NSError *)lastErrorLoadingResourceValuesForURL:(NSURL *)URL
{
	__block NSError *error = nil;
	dispatch_sync((self.inputDispatchQueue), ^{
		NSMutableDictionary *URLsToLoadingErrors = (self.URLsToLoadingErrors);
		error = URLsToLoadingErrors[URL];
	});
	
	return error;
}

- (void)cancelAllLoading
{
	[(self.backgroundOperationQueue) cancelAllOperations];
}

@end
