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

//+ (instancetype)sharedFileInfoRetrieverForMainQueue;

@property(weak, nonatomic) id<GLAFileInfoRetrieverDelegate> delegate;

#pragma mark File Properties

- (void)requestResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL;

- (NSDictionary *)loadedResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL requestIfNeeded:(BOOL)request;
- (NSError *)lastErrorLoadingResourceValuesForURL:(NSURL *)URL;

#pragma mark Applications

- (void)requestApplicationURLsToOpenURL:(NSURL *)URL;
- (NSArray *)applicationsURLsToOpenURL:(NSURL *)URL;
- (NSURL *)defaultApplicationsURLToOpenURL:(NSURL *)URL;

#pragma mark -

- (void)clearCacheForURLs:(NSArray *)URLs;

- (void)cancelAllLoading;

@end


@protocol GLAFileInfoRetrieverDelegate <NSObject>

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)URL;
- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL;

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didRetrieveApplicationURLsToOpenURL:(NSURL *)URL;

@end

/*
 extern NSString *GLAFileInfoRetrieverDidLoadResourceValuesNotification;
 
 extern NSString *GLAFileInfoRetrieverDidExperienceErrorNotification;
 extern NSString *GLAFileInfoRetrieverDidExperienceErrorNotificationErrorKey;
 extern NSString *GLAFileInfoRetrieverDidExperienceErrorNotificationSelectorKey;
 */
