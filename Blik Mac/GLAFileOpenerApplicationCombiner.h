//
//  GLAFileURLOpenerApplicationCombiner.h
//  Blik
//
//  Created by Patrick Smith on 3/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLAFileInfoRetriever.h"


@interface GLAFileOpenerApplicationCombiner : NSObject

@property(readonly, nonatomic) GLAFileInfoRetriever *fileInfoRetriever;

- (void)addFileURLs:(NSSet *)fileURLsSet;
- (void)removeFileURLs:(NSSet *)fileURLsSet;
- (BOOL)hasFileURL:(NSURL *)fileURL;
@property(copy, nonatomic) NSSet *fileURLs;

@property(readonly, copy, nonatomic) NSSet *combinedOpenerApplicationURLs;
@property(readonly, nonatomic) NSURL *combinedDefaultOpenerApplicationURL;

#pragma mark -

+ (void)openFileURLs:(NSArray *)fileURLs withApplicationURL:(NSURL *)applicationURL;

@end

extern NSString *GLAFileURLOpenerApplicationCombinerDidChangeNotification;
