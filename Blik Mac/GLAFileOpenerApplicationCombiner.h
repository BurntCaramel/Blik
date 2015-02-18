//
//  GLAFileURLOpenerApplicationCombiner.h
//  Blik
//
//  Created by Patrick Smith on 3/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;


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
+ (void)openFileURLs:(NSArray *)fileURLs withApplicationURL:(NSURL *)applicationURL useSecurityScope:(BOOL)useSecurityScope;

@end

extern NSString *GLAFileURLOpenerApplicationCombinerDidChangeNotification;


@interface GLAFileOpenerApplicationCombiner (MenuAdditions)

- (void)updateOpenerApplicationsMenu:(NSMenu *)menu target:(id)target action:(SEL)action preferredApplicationURL:(NSURL *)preferredApplicationURL forPopUpMenu:(BOOL)forPopUpMenu;
- (void)updateOpenerApplicationsMenu:(NSMenu *)menu target:(id)target action:(SEL)action preferredApplicationURL:(NSURL *)preferredApplicationURL;

- (void)updatePreferredOpenerApplicationsChoiceMenu:(NSMenu *)menu target:(id)target action:(SEL)action chosenPreferredApplicationURL:(NSURL *)preferredApplicationURL;

- (NSMenuItem *)newMenuItemForApplicationURL:(NSURL *)applicationURL target:(id)target action:(SEL)action;

@end