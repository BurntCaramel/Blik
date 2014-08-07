//
//  GLAFileInfoRetriever.m
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAFileInfoRetriever.h"


@interface GLAFileInfoRetriever ()

@property(readonly, nonatomic) NSOperationQueue *backgroundOperationQueue;
@property(readonly, nonatomic) dispatch_queue_t inputDispatchQueue;

@property(readonly, nonatomic) NSMutableDictionary *URLsToMutableSetOfRequestedResourceKeys;
@property(readonly, nonatomic) NSMutableDictionary *URLsToMutableSetOfLoadingResourceKeys;
@property(readonly, nonatomic) NSMutableDictionary *URLsToLoadingErrors;
//@property(readonly, nonatomic) NSMutableDictionary *URLsToCacheOfResourceValues;
@property(readonly, nonatomic) NSCache *cacheOfURLsToMutableDictionaryOfResourceValues;

@end

@implementation GLAFileInfoRetriever

- (instancetype)init
{
	self = [super init];
	if (self) {
		_backgroundOperationQueue = [NSOperationQueue new];
		(_backgroundOperationQueue.name) = @"com.burntcaramel.GLAFileInfoRetriever.background";
		_inputDispatchQueue = dispatch_queue_create("com.burntcaramel.GLAFileInfoRetriever.input", DISPATCH_QUEUE_SERIAL);
		
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
	static GLAFileInfoRetriever *instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [GLAFileInfoRetriever new];
	});
	
	return instance;
}

#pragma mark -

- (void)setDelegate:(id<GLAFileInfoRetrieverDelegate>)delegate
{
	__weak GLAFileInfoRetriever *weakSelf = self;
	dispatch_async((self.inputDispatchQueue), ^{
		GLAFileInfoRetriever *self = weakSelf;
		if (!self) {
			return;
		}
		
		self->_delegate = delegate;
	});
}

- (void)addRequestedResourceKeys:(NSArray *)resourceKeys forURL:(NSURL *)URL
{
	__weak GLAFileInfoRetriever *weakSelf = self;
	dispatch_async((self.inputDispatchQueue), ^{
		GLAFileInfoRetriever *self = weakSelf;
		if (!self) {
			return;
		}
		
		NSMutableSet *set = (self.URLsToMutableSetOfRequestedResourceKeys)[URL];
		if (!set) {
			set = [NSMutableSet new];
			(self.URLsToMutableSetOfRequestedResourceKeys)[URL] = set;
		}
		
		[set addObjectsFromArray:resourceKeys];
	});
}

- (NSSet *)requestedResourceKeysNeedingLoadingForURL:(NSURL *)URL setAreLoading:(BOOL)setAreLoading
{
	__weak GLAFileInfoRetriever *weakSelf = self;
	__block NSMutableSet *resourceKeysToLoad = nil;
	
	dispatch_sync((self.inputDispatchQueue), ^{
		GLAFileInfoRetriever *self = weakSelf;
		if (!self) {
			return;
		}
		
		NSMutableSet *requestedResourceKeysSet = (self.URLsToMutableSetOfRequestedResourceKeys)[URL];
		NSLog(@"requestedResourceKeysSet %@", requestedResourceKeysSet);
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
	__weak GLAFileInfoRetriever *weakSelf = self;
	
	[(self.backgroundOperationQueue) addOperationWithBlock:^{
		GLAFileInfoRetriever *self = weakSelf;
		if (!self) {
			return;
		}
		
		NSSet *resourceKeysToLoad = [self requestedResourceKeysNeedingLoadingForURL:URL setAreLoading:YES];
		NSLog(@"resourceKeysToLoad %@", resourceKeysToLoad);
		if (!resourceKeysToLoad || (resourceKeysToLoad.count) == 0) {
			return;
		}
		
		NSError *error = nil;
		NSLog(@"LAODING %@", URL);
		// This blocks, the whole reason why this is all in a background queue.
		NSDictionary *loadedResourceValues = [URL resourceValuesForKeys:[resourceKeysToLoad allObjects] error:&error];
		
		dispatch_async((self.inputDispatchQueue), ^{
			GLAFileInfoRetriever *self = weakSelf;
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
			
			id<GLAFileInfoRetrieverDelegate> delegate = (self.delegate);
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				NSLog(@"SENDING TO DELEGATE");
				if (delegate) {
					if (loadedResourceValues) {
						[delegate fileInfoRetriever:self didLoadResourceValuesForURL:URL];
					}
					else {
						[delegate fileInfoRetriever:self didFailWithError:error loadingResourceValuesForURL:URL];
					}
				}
			}];
			// Call the callback;
			//GLAFileInfoRetrieverLoadedCallback loadedCallback = (self.loadedCallback);
			//if (loadedCallback) {
			//	(loadedCallback)(self, URL, error);
			//}
		});
	}];
}

#pragma mark

- (void)requestResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL
{NSLog(@"requestResourceValuesForKeys");
	[self addRequestedResourceKeys:keys forURL:URL];
	[self loadMissingResourceValuesInBackgroundForURL:URL];
}

- (NSDictionary *)loadedResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL requestIfNeed:(BOOL)request
{
	__block NSDictionary *returnedDictionary = nil;
	
	if (request) {
		[self requestResourceValuesForKeys:keys forURL:URL];
	}
	
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
