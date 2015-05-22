//
//  GLAFileURLOpenerApplicationCombiner.h
//  Blik
//
//  Created by Patrick Smith on 3/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;

NS_ASSUME_NONNULL_BEGIN

@interface GLAFileOpenerApplicationFinder : NSObject

- (void)addFileURLs:(NSSet *)fileURLsSet;
- (void)removeFileURLs:(NSSet *)fileURLsSet;
- (BOOL)hasFileURL:(NSURL *)fileURL;
@property(copy, nonatomic) NSSet *fileURLs;

@property(readonly, nonatomic) BOOL hasLoadedAll;

@property(readonly, copy, nonatomic) NSSet *combinedOpenerApplicationURLs;
@property(readonly, nonatomic) NSURL *combinedDefaultOpenerApplicationURL;

#pragma mark -

+ (void)openFileURLs:(NSArray *)fileURLs withApplicationURL:(NSURL * __nullable)applicationURL;
+ (void)openFileURLs:(NSArray *)fileURLs withApplicationURL:(NSURL * __nullable)applicationURL useSecurityScope:(BOOL)useSecurityScope;

- (void)openFileURLsUsingDefaultApplications;

@end

extern NSString *GLAFileURLOpenerApplicationCombinerDidChangeNotification;


@interface GLAFileOpenerApplicationFinder (MenuAdditions)

- (void)updateOpenerApplicationsMenu:(NSMenu *)menu target:(id)target action:(SEL)action preferredApplicationURL:(NSURL * __nullable)preferredApplicationURL;
- (void)updateOpenerApplicationsPullDownPopUpButton:(NSPopUpButton *)popUpButton target:(id)target action:(SEL)action preferredApplicationURL:(NSURL * __nullable)preferredApplicationURL;

- (void)updatePreferredOpenerApplicationsChoiceMenu:(NSMenu *)menu target:(id)target action:(SEL)action chosenPreferredApplicationURL:(NSURL * __nullable)preferredApplicationURL;

- (NSMenuItem *)newMenuItemForApplicationURL:(NSURL *)applicationURL target:(id)target action:(SEL)action;

- (NSURL *)openerApplicationURLForMenuItem:(NSMenuItem *)menuItem;
- (void)openFileURLsUsingMenuItem:(NSMenuItem *)menuItem;
- (void)openFileURLsUsingChosenOpenerApplicationPopUpButton:(NSPopUpButton *)popUpButton;

@end

NS_ASSUME_NONNULL_END
