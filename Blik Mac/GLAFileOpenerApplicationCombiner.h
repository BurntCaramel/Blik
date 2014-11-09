//
//  GLAFileURLOpenerApplicationCombiner.h
//  Blik
//
//  Created by Patrick Smith on 3/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;


@interface GLAFileOpenerApplicationCombiner : NSObject

- (void)addFileURLs:(NSSet *)fileURLsSet;
- (void)removeFileURLs:(NSSet *)fileURLsSet;
- (BOOL)hasFileURL:(NSURL *)fileURL;
@property(copy, nonatomic) NSSet *fileURLs;

@property(readonly, nonatomic) BOOL hasLoadedAll;

@property(readonly, copy, nonatomic) NSSet *combinedOpenerApplicationURLs;
@property(readonly, nonatomic) NSURL *combinedDefaultOpenerApplicationURL;

#pragma mark -

+ (void)openFileURLs:(NSArray *)fileURLs withApplicationURL:(NSURL *)applicationURL;

@end

extern NSString *GLAFileURLOpenerApplicationCombinerDidChangeNotification;


@interface GLAFileOpenerApplicationCombiner (MenuAdditions)

- (NSMenuItem *)newMenuItemForApplicationURL:(NSURL *)applicationURL target:(id)target action:(SEL)action;
- (void)updateMenuWithOpenerApplications:(NSMenu *)menu target:(id)target action:(SEL)action;

@end