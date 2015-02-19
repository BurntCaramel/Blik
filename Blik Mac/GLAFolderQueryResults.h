//
//  GLAFolderQueryResults.h
//  Blik
//
//  Created by Patrick Smith on 14/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;
@class GLAFolderQuery;
#import "GLAFileInfoRetriever.h"


typedef NS_ENUM(NSUInteger, GLAFolderQueryResultsSortingMethod) {
	GLAFolderQueryResultsSortingMethodDateLastOpened = 0,
	GLAFolderQueryResultsSortingMethodDateAdded,
	GLAFolderQueryResultsSortingMethodDateModified,
	GLAFolderQueryResultsSortingMethodDateCreated
};


@interface GLAFolderQueryResults : NSObject

- (instancetype)initWithFolderQuery:(GLAFolderQuery *)folderQuery;

@property(readonly, nonatomic) GLAFolderQuery *folderQuery;
@property(readonly, nonatomic) GLAFileInfoRetriever *fileInfoRetriever;

@property(nonatomic) GLAFolderQueryResultsSortingMethod sortingMethod;

- (void)startSearching;

- (void)beginAccessingResults;
- (void)finishAccessingResults;

@property(readonly, nonatomic) NSUInteger resultCount;
- (NSArray *)copyFileURLs;

- (NSURL *)fileURLForResultAtIndex:(NSUInteger)resultIndex;
- (NSString *)localizedNameForResultAtIndex:(NSUInteger)resultIndex;
//- (NSImage *)copyEffectiveIconForResultAtIndex:(NSUInteger)resultIndex withSizeDimension:(CGFloat)dimension;

@end

extern NSString *GLAFolderQueryResultsGatheringProgressNotification;
extern NSString *GLAFolderQueryResultsDidUpdateNotification;
