//
//  GLAProjectItem.h
//  Blik
//
//  Created by Patrick Smith on 18/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "Mantle/Mantle.h"
@class GLAProject;
@class GLACollectionContent;
@class GLACollectionColor;


@protocol GLACollectedItem <NSObject>

@property(copy, readonly, nonatomic) NSString *title;

@end


@protocol GLACollectionEditing <NSObject>

//@property(weak, nonatomic) GLAProject *project;

@property(readwrite, nonatomic) GLACollectionContent *content;
@property(readwrite, copy, nonatomic) NSString *title;

@property(readwrite, nonatomic) GLACollectionColor *color;

@end


@interface GLACollection : MTLModel <GLACollectedItem, MTLJSONSerializing, NSPasteboardReading, NSPasteboardWriting>

//@property(readonly, weak, nonatomic) GLAProject *project;

@property(readonly, nonatomic) GLACollectionContent *content;

@property(readonly, nonatomic) NSUUID *UUID;
@property(readonly, copy, nonatomic) NSString *title;

@property(readonly, nonatomic) GLACollectionColor *color;

+ (instancetype)newWithCreationFromEditing:(void(^)(id<GLACollectionEditing>collectionEditor))editingBlock;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLACollectionEditing>collectionEditor))editingBlock;

@end


@interface GLACollection (PasteboardSupport)

extern NSString *GLACollectionJSONPasteboardType;

- (NSPasteboardItem *)newPasteboardItem;
+ (void)writeCollections:(NSArray *)collections toPasteboard:(NSPasteboard *)pboard;

+ (BOOL)canCopyCollectionsFromPasteboard:(NSPasteboard *)pboard;
+ (NSArray *)copyCollectionsFromPasteboard:(NSPasteboard *)pboard;

@end


@interface GLACollection (GLADummyContent)

+ (instancetype)dummyCollectionWithTitle:(NSString *)title color:(GLACollectionColor *)color content:(GLACollectionContent *)content;

@end
