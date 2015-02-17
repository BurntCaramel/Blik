//
//  GLAFolderQueryResults.h
//  Blik
//
//  Created by Patrick Smith on 14/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;
@class GLAFolderQuery;


@interface GLAFolderQueryResults : NSObject

- (instancetype)initWithFolderQuery:(GLAFolderQuery *)folderQuery folderURLs:(NSArray *)folderURLs;

@property(nonatomic) GLAFolderQuery *folderQuery;
@property(nonatomic) NSArray *folderURLs;

- (void)startSearching;

@property(readonly, nonatomic) NSUInteger resultsCount;
- (NSArray *)copyFileURLs;

- (NSURL *)fileURLForResultAtIndex:(NSUInteger)resultIndex;
- (NSString *)copyLocalizedNameForResultAtIndex:(NSUInteger)resultIndex;
- (NSImage *)copyEffectiveIconForResultAtIndex:(NSUInteger)resultIndex;

@end

extern NSString *GLAFolderQueryResultsDidUpdateNotification;
