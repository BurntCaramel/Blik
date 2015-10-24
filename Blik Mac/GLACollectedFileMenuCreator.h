//
//  GLACollectedFileMenuCreator.h
//  Blik
//
//  Created by Patrick Smith on 15/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLACollectedFile.h"
#import "GLAHighlightedItem.h"
#import "GLAFileOpenerApplicationFinder.h"


typedef NS_ENUM(NSUInteger, GLACollectedFileMenuContext) {
	GLACollectedFileMenuContextUnknown = 0,
	GLACollectedFileMenuContextInHighlights,
	GLACollectedFileMenuContextInCollection
};


@interface GLACollectedFileMenuCreator : NSObject

@property(nonatomic) NSURL *fileURL;

@property(nonatomic) GLACollectedFile *collectedFile;
@property(nonatomic) GLAHighlightedCollectedFile *highlightedCollectedFile;

@property(nonatomic) GLACollectedFileMenuContext context;

@property(weak, nonatomic) id target;
@property(nonatomic) SEL openInApplicationAction;
@property(nonatomic) SEL changePreferredOpenerApplicationAction;
@property(nonatomic) SEL showInFinderAction;
@property(nonatomic) SEL changeCustomNameHighlightsAction;
@property(nonatomic) SEL removeFromHighlightsAction;

- (void)updateMenu:(NSMenu *)menu;

@end

extern NSString *GLACollectedFileMenuCreatorNeedsUpdateNotification;
