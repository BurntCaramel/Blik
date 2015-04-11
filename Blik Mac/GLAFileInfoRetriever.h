//
//  GLAFileInfoRetriever.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;
@protocol GLAFileInfoRetrieverDelegate;


@interface GLAFileInfoRetriever : NSObject

- (instancetype)initWithDelegate:(id<GLAFileInfoRetrieverDelegate>)delegate defaultResourceKeysToRequest:(NSArray *)defaultResourceKeysToRequest NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithDelegate:(id<GLAFileInfoRetrieverDelegate>)delegate;

@property(weak, nonatomic) id<GLAFileInfoRetrieverDelegate> delegate;

#pragma mark File Properties

@property(nonatomic) NSArray *defaultResourceKeysToRequest;
- (void)requestDefaultResourceKeysForURL:(NSURL *)URL alwaysNotify:(BOOL)alwaysNotify;

// All methods are thread-safe

- (void)requestResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL alwaysNotify:(BOOL)alwaysNotify;

- (NSDictionary *)loadedResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL requestIfNeeded:(BOOL)request;
- (NSError *)lastErrorLoadingResourceValuesForURL:(NSURL *)URL;

#pragma mark Convenience

- (id)resourceValueForKey:(NSString *)key forURL:(NSURL *)URL;
- (NSString *)localizedNameForURL:(NSURL *)URL;
- (NSImage *)effectiveIconImageForURL:(NSURL *)URL;
- (NSImage *)effectiveIconImageForURL:(NSURL *)URL withSizeDimension:(CGFloat)widthAndHeight;

#pragma mark Applications

- (void)requestApplicationURLsToOpenURL:(NSURL *)URL;
- (NSArray *)applicationsURLsToOpenURL:(NSURL *)URL;
- (NSURL *)defaultApplicationURLToOpenURL:(NSURL *)URL;

#pragma mark Directory Contents

- (void)requestChildrenOfDirectoryWithURL:(NSURL *)directoryURL;
- (NSArray *)childURLsOfDirectoryWithURL:(NSURL *)directoryURL requestIfNeeded:(BOOL)requestIfNeeded;
- (NSError *)errorRetrievingChildURLsOfDirectoryWithURL:(NSURL *)directoryURL;

#pragma mark Clearing Cache

- (void)clearCacheForURLs:(NSArray *)URLs;
- (void)clearCacheForAllURLs;
- (void)cancelAllLoading;

@end


@protocol GLAFileInfoRetrieverDelegate <NSObject>

@optional

// All methods called on main queue.

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)URL;
- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL;

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didRetrieveApplicationURLsToOpenURL:(NSURL *)URL;

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didRetrieveContentsOfDirectoryURL:(NSURL *)URL;
- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error retrievingContentsOfDirectoryURL:(NSURL *)URL;

@end


@interface GLAFileInfoRetriever (NotificationObserving)

- (id<NSObject>)addObserver:(id<NSObject>)owner forDidRetrieveContentsOfDirectory:(void (^)(id<NSObject> owner, GLAFileInfoRetriever *fileInfoRetriever, NSURL *directoryURL))block;

- (void)removeObserverWithToken:(id<NSObject>)observerToken;

@end

extern NSString *GLAFileInfoRetrieverDidRetrieveContentsOfDirectoryNotification;
extern NSString *GLAFileInfoRetrieverNotificationInfoDirectoryURL;

