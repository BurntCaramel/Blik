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

// Designated Init
- (instancetype)initWithDelegate:(id<GLAFileInfoRetrieverDelegate>)delegate;

@property(weak, nonatomic) id<GLAFileInfoRetrieverDelegate> delegate;

#pragma mark File Properties

- (void)requestResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL;

- (NSDictionary *)loadedResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL requestIfNeeded:(BOOL)request;
- (NSError *)lastErrorLoadingResourceValuesForURL:(NSURL *)URL;

#pragma mark Applications

- (void)requestApplicationURLsToOpenURL:(NSURL *)URL;
- (NSArray *)applicationsURLsToOpenURL:(NSURL *)URL;
- (NSURL *)defaultApplicationURLToOpenURL:(NSURL *)URL;

#pragma mark -

- (void)clearCacheForURLs:(NSArray *)URLs;

- (void)cancelAllLoading;

@end


@protocol GLAFileInfoRetrieverDelegate <NSObject>

@optional

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)URL;
- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL;

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didRetrieveApplicationURLsToOpenURL:(NSURL *)URL;

@end
