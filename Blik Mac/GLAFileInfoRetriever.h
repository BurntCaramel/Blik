//
//  GLAFileInfoRetriever.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
@protocol GLAFileInfoRetrieverDelegate;


@interface GLAFileInfoRetriever : NSObject

//+ (instancetype)sharedFileInfoRetrieverForMainQueue;

@property(weak, nonatomic) id<GLAFileInfoRetrieverDelegate> delegate;

- (void)requestResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL;

- (NSDictionary *)loadedResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL requestIfNeed:(BOOL)request;
- (NSError *)lastErrorLoadingResourceValuesForURL:(NSURL *)URL;

- (void)cancelAllLoading;

@end


@protocol GLAFileInfoRetrieverDelegate <NSObject>

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)URL;
- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL;

@end

/*
 extern NSString *GLAFileInfoRetrieverDidLoadResourceValuesNotification;
 
 extern NSString *GLAFileInfoRetrieverDidExperienceErrorNotification;
 extern NSString *GLAFileInfoRetrieverDidExperienceErrorNotificationErrorKey;
 extern NSString *GLAFileInfoRetrieverDidExperienceErrorNotificationSelectorKey;
 */
