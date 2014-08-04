//
//  GLAFileURLInfoRetriever.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
@class GLAFileURLInfoRetriever;


typedef void(^GLAFileURLInfoRetrieverLoadedCallback)(GLAFileURLInfoRetriever *infoRetriever, NSURL *URL, NSError *error);

@interface GLAFileURLInfoRetriever : NSObject

//+ (instancetype)sharedFileInfoRetrieverForMainQueue;

@property(strong, nonatomic) GLAFileURLInfoRetrieverLoadedCallback loadedCallback;

- (void)requestResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL;

- (NSDictionary *)loadedResourceValuesForKeys:(NSArray *)keys forURL:(NSURL *)URL;
- (NSError *)lastErrorLoadingResourceValuesForURL:(NSURL *)URL;

- (void)cancelAllLoading;

@end

/*
 extern NSString *GLAFileURLInfoRetrieverDidLoadResourceValuesNotification;
 
 extern NSString *GLAFileURLInfoRetrieverDidExperienceErrorNotification;
 extern NSString *GLAFileURLInfoRetrieverDidExperienceErrorNotificationErrorKey;
 extern NSString *GLAFileURLInfoRetrieverDidExperienceErrorNotificationSelectorKey;
 */
