//
//  GLAProjectItem.h
//  Blik
//
//  Created by Patrick Smith on 18/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;
#import "Mantle/Mantle.h"
@class GLAProject;
@class GLACollectionColor;


extern NSString *GLACollectionTypeFilesList;


@protocol GLACollectedItem <NSObject>

@property(readonly, nonatomic) NSUUID *UUID;

@property(readonly, copy, nonatomic) NSString *name;

@end


@protocol GLACollectionEditing <NSObject>

@property(readwrite, copy, nonatomic) NSUUID *projectUUID;

@property(readwrite, copy, nonatomic) NSString *name;
@property(readwrite, nonatomic) GLACollectionColor *color;

@end


@interface GLACollection : MTLModel <GLACollectedItem, MTLJSONSerializing>

@property(readonly, copy, nonatomic) NSUUID *projectUUID;

@property(readonly, nonatomic) NSUUID *UUID;
@property(readonly, copy, nonatomic) NSString *name;

@property(readonly, nonatomic) NSString *type;

@property(readonly, nonatomic) GLACollectionColor *color;

+ (instancetype)newWithType:(NSString *)collectionType creatingFromEditing:(void(^)(id<GLACollectionEditing> editor))editingBlock;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLACollectionEditing> editor))editingBlock;

@end


@interface GLACollection (PasteboardSupport) <NSPasteboardReading, NSPasteboardWriting>

extern NSString *GLACollectionJSONPasteboardType;

+ (BOOL)canCopyCollectionsFromPasteboard:(NSPasteboard *)pboard;
+ (NSArray *)copyCollectionsFromPasteboard:(NSPasteboard *)pboard;

@end


@interface GLACollection (GLADummyContent)

+ (instancetype)dummyCollectionWithName:(NSString *)name color:(GLACollectionColor *)color type:(NSString *)collectionType;

@end
