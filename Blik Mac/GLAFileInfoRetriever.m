//
//  GLAFileInfoRetriever.m
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
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

@property(readonly, nonatomic) NSMutableSet *URLsHavingApplicationURLsLoaded;
@property(readonly, nonatomic) NSCache *cacheOfURLsToApplicationURLs;
@property(readonly, nonatomic) NSCache *cacheOfURLsToDefaultApplicationURLs;

@end

@implementation GLAFileInfoRetriever

- (instancetype)initWithDelegate:(id<GLAFileInfoRetrieverDelegate>)delegate defaultResourceKeysToRequest:(NSArray *)defaultResourceKeysToRequest
{
	self = [super init];
	if (self) {
		_delegate = delegate;
		
		_input_defaultResourceKeysToRequest = [defaultResourceKeysToRequest copy];
		
		_backgroundOperationQueue = [NSOperationQueue new];
		(_backgroundOperationQueue.name) = @"com.burntcaramel.GLAFileInfoRetriever.background";
		_inputDispatchQueue = dispatch_queue_create("com.burntcaramel.GLAFileInfoRetriever.input", DISPATCH_QUEUE_SERIAL);
		
		_URLsToMutableSetOfRequestedResourceKeys = [NSMutableDictionary new];
		_URLsToMutableSetOfLoadingResourceKeys = [NSMutableDictionary new];
		_URLsToLoadingErrors = [NSMutableDictionary new];
		//_URLsToCacheOfResourceValues = [NSMutableDictionary new];
		_cacheOfURLsToMutableDictionaryOfResourceValues = [NSCache new];
		
		_URLsHavingApplicationURLsLoaded = [NSMutableSet new];
		_cacheOfURLsToApplicationURLs = [NSCache new];
		_cacheOfURLsToDefaultApplicationURLs = [NSCache new];
	}
	return self;
}

- (instancetype)initWithDelegate:(id<GLAFileInfoRetrieverDelegate>)delegate
{
	return [self initWithDelegate:delegate defaultResourceKeysToRequest:@[]];
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

- (void)runAsyncOnInputQueue:(void (^)(GLAFileInfoRetriever *self))block
{
	__weak GLAFileInfoRetriever *weakSelf = self;
	dispatch_async((self.inputDispatchQueue), ^{
		GLAFileInfoRetriever *retriever = weakSelf;
		if (!retriever) {
			return;
		}
		
		block(retriever);
	});
}

- (void)runAsyncInBackground:(void (^)(GLAFileInfoRetriever *self))block
{
	__weak GLAFileInfoRetriever *weakSelf = self;
	
	[(self.backgroundOperationQueue) addOperationWithBlock:^{
		GLAFileInfoRetriever *retriever = weakSelf;
		if (!retriever) {
			return;
		}
		
		block(retriever);
	}];
}

- (void)useDelegateOnMainQueue:(void (^)(GLAFileInfoRetriever *retriever, id<GLAFileInfoRetrieverDelegate> delegate))block
{
	__weak GLAFileInfoRetriever *weakSelf = self;
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		GLAFileInfoRetriever *retriever = weakSelf;
		if (!retriever) {
			return;
		}
		
		id<GLAFileInfoRetrieverDelegate> delegate = (self.delegate);
		if (!delegate) {
			return;
		}
		
		block(retriever, delegate);
	}];
}

#pragma mark -

@synthesize delegate = _delegate;

- (void)setDelegate:(id<GLAFileInfoRetrieverDelegate>)delegate
{
	[self runAsyncOnInputQueue:^(GLAFileInfoRetriever *retriever) {
		retriever->_delegate = delegate;
	}];
}

- (id<GLAFileInfoRetrieverDelegate>)delegateFromInsideInputQueue
{
	return _delegate;
}

- (id<GLAFileInfoRetrieverDelegate>)delegate
{
	__block id<GLAFileInfoRetrieverDelegate> delegate;
	
	dispatch_sync((self.inputDispatchQueue), ^{
		delegate = (self.delegateFromInsideInputQueue);
	});
	
	return delegate;
}

@synthesize defaultResourceKeysToRequest = _input_defaultResourceKeysToRequest;

- (NSArray *)defaultResourceKeysToRequest
{
	__block NSArray *defaultResourceKeysToRequest;
	
	dispatch_sync((self.inputDispatchQueue), ^{
		defaultResourceKeysToRequest = self->_input_defaultResourceKeysToRequest;
	});
	
	return defaultResourceKeysToRequest;
}

- (void)setDefaultResourceKeysToRequest:(NSArray *)defaultResourceKeysToRequest
{
	defaultResourceKeysToRequest = [defaultResourceKeysToRequest copy];
	
	[self runAsyncOnInputQueue:^(GLAFileInfoRetriever *retriever) {
		retriever->_input_defaultResourceKeysToRequest = defaultResourceKeysToRequest;
	}];
}

#pragma mark -

- (void)addRequestedResourceKeys:(NSArray *)resourceKeys forURL:(NSURL *)URL
{
	NSParameterAssert(URL != nil);
	
	[self runAsyncOnInputQueue:^(GLAFileInfoRetriever *self) {
		NSMutableSet *set = (self.URLsToMutableSetOfRequestedResourceKeys)[URL];
		if (!set) {
			set = [NSMutableSet new];
			(self.URLsToMutableSetOfRequestedResourceKeys)[URL] = set;
		}
		
		[set addObjectsFromArray:resourceKeys];
	}];
}

- (NSSet *)requestedResourceKeysNeedingLoadingForURL:(NSURL *)URL setAreLoading:(BOOL)setAreLoading
{
	__block NSMutableSet *resourceKeysToLoad = nil;
	
	// No retain cycle with dispatch_sync, unlike dispatch_async.
	dispatch_sync((self.inputDispatchQueue), ^{
		NSMutableSet *requestedResourceKeysSet = (self.URLsToMutableSetOfRequestedResourceKeys)[URL];
		resourceKeysToLoad = [requestedResourceKeysSet mutableCopy];
		
		NSMutableSet *loadingResourceKeys = (self.URLsToMutableSetOfLoadingResourceKeys)[URL];
		if (loadingResourceKeys) {
			[resourceKeysToLoad minusSet:loadingResourceKeys];
		}
		
		NSMutableDictionary *loadedResourceValues = [(self.cacheOfURLsToMutableDictionaryOfResourceValues) objectForKey:URL];
		if (loadedResourceValues) {
			// TODO put these in a temporary dictionary in case these get cleared out of the cache.
			[resourceKeysToLoad minusSet:[NSSet setWithArray:(loadedResourceValues.allKeys)]];
		}
		
		if (setAreLoading && (resourceKeysToLoad.count) > 0) {
			NSMutableSet *loadingResourceKeys = (self.URLsToMutableSetOfLoadingResourceKeys)[URL];
			[loadingResourceKeys unionSet:resourceKeysToLoad];
		}
	});
	
	return resourceKeysToLoad;
}

- (void)loadMissingResourceValuesInBackgroundForURL:(NSURL *)URL alwaysNotify:(BOOL)alwaysNotify
{
	[self runAsyncInBackground:^(GLAFileInfoRetriever *self) {
		NSSet *resourceKeysToLoad = [self requestedResourceKeysNeedingLoadingForURL:URL setAreLoading:YES];
		if (!resourceKeysToLoad) {
			return;
		}
		
		BOOL hasStuffToLoad = (resourceKeysToLoad.count) > 0;
		NSError *error = nil;
		NSDictionary *loadedResourceValues = nil;
		
		if (hasStuffToLoad) {
			// This blocks, the whole reason why this is all in a background queue.
			loadedResourceValues = [URL resourceValuesForKeys:[resourceKeysToLoad allObjects] error:&error];
		}
		
		[self runAsyncOnInputQueue:^(GLAFileInfoRetriever *self) {
			if (hasStuffToLoad) {
				[self input_processLoadedResourceValues:loadedResourceValues error:error forURL:URL];
			}
			
			if (hasStuffToLoad || alwaysNotify) {
				[self useDelegateOnMainQueue:^(GLAFileInfoRetriever *retriever, id<GLAFileInfoRetrieverDelegate> delegate) {
					if (loadedResourceValues || !hasStuffToLoad) {
						[delegate fileInfoRetriever:self didLoadResourceValuesForURL:URL];
					}
					else {
						[delegate fileInfoRetriever:self didFailWithError:error loadingResourceValuesForURL:URL];
					}
				}];
			}
		}];
	}];
}

- (void)input_processLoadedResourceValues:(NSDictionary *)loadedResourceValues error:(NSError *)error forURL:(NSURL *)URL
{
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
}

#pragma mark

- (void)requestResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL alwaysNotify:(BOOL)alwaysNotify
{
	[self addRequestedResourceKeys:keys forURL:URL];
	[self loadMissingResourceValuesInBackgroundForURL:URL alwaysNotify:alwaysNotify];
}

- (NSDictionary *)loadedResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL requestIfNeeded:(BOOL)request
{
	__block NSDictionary *returnedDictionary = nil;
	
	if (request) {
		[self requestResourceValuesForKeys:keys forURL:URL alwaysNotify:NO];
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

#pragma mark Convenience

- (void)requestDefaultResourceKeysForURL:(NSURL *)URL alwaysNotify:(BOOL)alwaysNotify
{
	NSArray *defaultResourceKeysToRequest = (self.defaultResourceKeysToRequest);
	if ((defaultResourceKeysToRequest.count) == 0) {
		return;
	}
	
	[self requestResourceValuesForKeys:defaultResourceKeysToRequest forURL:URL alwaysNotify:alwaysNotify];
}

- (id)resourceValueForKey:(NSString *)key forURL:(NSURL *)URL
{
	NSParameterAssert(URL != nil);
	
	NSArray *defaultResourceKeysToRequest = (self.defaultResourceKeysToRequest);
	BOOL isDefault = ([defaultResourceKeysToRequest indexOfObject:key] != NSNotFound);
	if (isDefault) {
		[self requestDefaultResourceKeysForURL:URL alwaysNotify:NO];
	}
	
	NSDictionary *resourceValues = [self loadedResourceValuesForKeys:@[key] forURL:URL requestIfNeeded:!isDefault];
	return resourceValues[key];
}

- (NSString *)localizedNameForURL:(NSURL *)URL
{
	return [self resourceValueForKey:NSURLLocalizedNameKey forURL:URL];
}

- (NSImage *)effectiveIconImageForURL:(NSURL *)URL
{
	return [self resourceValueForKey:NSURLEffectiveIconKey forURL:URL];
}

- (NSImage *)effectiveIconImageForURL:(NSURL *)URL withSizeDimension:(CGFloat)widthAndHeight
{
	NSImage *iconImage = [[self effectiveIconImageForURL:URL] copy];
	if (iconImage) {
		(iconImage.size) = NSMakeSize(widthAndHeight, widthAndHeight);
	}
	return iconImage;
}

#pragma mark Applications

- (void)requestApplicationURLsToOpenURL:(NSURL *)URL
{
	[self runAsyncOnInputQueue:^(GLAFileInfoRetriever *retriever) {
		NSMutableSet *URLsHavingApplicationURLsLoaded = (retriever.URLsHavingApplicationURLsLoaded);
		if ([URLsHavingApplicationURLsLoaded containsObject:URL]) {
			return;
		}
		
		[URLsHavingApplicationURLsLoaded addObject:URL];
		
		[retriever runAsyncInBackground:^(GLAFileInfoRetriever *retriever) {
			CFArrayRef applicationURLs_cf = LSCopyApplicationURLsForURL((__bridge CFURLRef)URL, kLSRolesViewer | kLSRolesEditor);
			NSArray *applicationURLs = CFBridgingRelease(applicationURLs_cf);
			
			// Standardize the paths (some may have trailing slashes, some not).
			applicationURLs = [applicationURLs valueForKey:@"URLByStandardizingPath"];
			// Remove duplicates.
			applicationURLs = [NSSet setWithArray:applicationURLs].allObjects;
			
			NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
			NSURL *defaultApplicationURL = [workspace URLForApplicationToOpenURL:URL];
			
			[retriever background_processLoadedApplicationURLs:applicationURLs defaultApplicationURL:defaultApplicationURL forURL:URL];
		}];
	}];
}

- (void)background_processLoadedApplicationURLs:(NSArray *)applicationURLs defaultApplicationURL:(NSURL *)defaultApplicationURL forURL:(NSURL *)URL
{
	[self runAsyncOnInputQueue:^(GLAFileInfoRetriever *retriever) {
		NSMutableSet *URLsHavingApplicationURLsLoaded = (retriever.URLsHavingApplicationURLsLoaded);
		[URLsHavingApplicationURLsLoaded removeObject:URL];
		
		NSCache *cacheOfURLsToApplicationURLs = (retriever.cacheOfURLsToApplicationURLs);
		[cacheOfURLsToApplicationURLs setObject:applicationURLs forKey:URL];
		
		if (defaultApplicationURL) {
			NSCache *cacheOfURLsToDefaultApplicationURLs = (retriever.cacheOfURLsToDefaultApplicationURLs);
			[cacheOfURLsToDefaultApplicationURLs setObject:defaultApplicationURL forKey:URL];
		}
		
		[retriever useDelegateOnMainQueue:^(GLAFileInfoRetriever *retriever, id<GLAFileInfoRetrieverDelegate> delegate) {
			[delegate fileInfoRetriever:self didRetrieveApplicationURLsToOpenURL:URL];
		}];
	}];
}

- (NSArray *)applicationsURLsToOpenURL:(NSURL *)URL
{
	__block NSArray *applicationURLs;
	
	dispatch_sync((self.inputDispatchQueue), ^{
		NSCache *cacheOfURLsToApplicationURLs = (self.cacheOfURLsToApplicationURLs);
		
		applicationURLs = [cacheOfURLsToApplicationURLs objectForKey:URL];
	});
	
	return applicationURLs;
}

- (NSURL *)defaultApplicationURLToOpenURL:(NSURL *)URL
{
	__block NSURL *defaultApplicationURL;
	
	dispatch_sync((self.inputDispatchQueue), ^{
		NSCache *cacheOfURLsToDefaultApplicationURLs = (self.cacheOfURLsToDefaultApplicationURLs);
		
		defaultApplicationURL = [cacheOfURLsToDefaultApplicationURLs objectForKey:URL];
	});
	
	return defaultApplicationURL;
}

#pragma mark -

- (void)clearCacheForURLs:(NSArray *)URLs
{
	dispatch_sync((self.inputDispatchQueue), ^{
		NSCache *cacheOfURLsToMutableDictionaryOfResourceValues = (self.cacheOfURLsToMutableDictionaryOfResourceValues);
		NSCache *cacheOfURLsToApplicationURLs = (self.cacheOfURLsToApplicationURLs);
		
		for (NSURL *fileURL in URLs) {
			[cacheOfURLsToMutableDictionaryOfResourceValues removeObjectForKey:fileURL];
			[cacheOfURLsToApplicationURLs removeObjectForKey:fileURL];
		}
	});
}

- (void)clearCacheForAllURLs
{
	[self cancelAllLoading];
	
	dispatch_sync((self.inputDispatchQueue), ^{
		NSCache *cacheOfURLsToMutableDictionaryOfResourceValues = (self.cacheOfURLsToMutableDictionaryOfResourceValues);
		NSCache *cacheOfURLsToApplicationURLs = (self.cacheOfURLsToApplicationURLs);
		
		[cacheOfURLsToMutableDictionaryOfResourceValues removeAllObjects];
		[cacheOfURLsToApplicationURLs removeAllObjects];
	});
}

- (void)cancelAllLoading
{
	[(self.backgroundOperationQueue) cancelAllOperations];
}

@end
