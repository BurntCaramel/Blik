//
//  GLADirectoryWatcher.h
//  Blik
//
//  Created by Patrick Smith on 31/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Foundation;

@protocol GLADirectoryWatcherDelegate;


@interface GLADirectoryWatcher : NSObject

- (instancetype)initWithDelegate:(id<GLADirectoryWatcherDelegate>)delegate previousStateData:(NSData *)data;

@property(weak, nonatomic) id<GLADirectoryWatcherDelegate> delegate;

@property(copy, nonatomic) NSSet *directoryURLs;

@property(nonatomic) id representedObject;

@property(readonly, copy, nonatomic) NSData *stateData;

@end

extern NSString *GLADirectoryWatcherDirectoryDidChangeNotification;


@protocol GLADirectoryWatcherDelegate <NSObject>

// All methods are called on a background queue.

- (void)directoryWatcher:(GLADirectoryWatcher *)directoryWatcher directoriesDidChangeForURLs:(NSArray *)directoryURLs;

@optional

// More specific:

- (void)directoryWatcher:(GLADirectoryWatcher *)directoryWatcher subdirectoriesDidChangeForURLs:(NSArray *)subdirectoryURLs;

- (void)directoryWatcher:(GLADirectoryWatcher *)directoryWatcher mainDirectoriesWereMovedOrDeleted:(NSArray *)directoryURLs;

@end
