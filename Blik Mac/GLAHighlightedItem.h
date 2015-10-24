//
//  GLAHighlightedItem.h
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAModel.h"
#import "GLACollection.h"
#import "GLACollectedFile.h"

NS_ASSUME_NONNULL_BEGIN

@protocol GLAHighlightedItemEditing <NSObject>

@property(readwrite, copy, nonatomic) NSUUID *projectUUID;

@property(readwrite, copy, nonatomic) NSString * _Nullable customName;

@end

@interface GLAHighlightedItem : GLAModel

@property(readonly, copy, nonatomic) NSUUID *projectUUID;

@property(readonly, copy, nonatomic) NSString * _Nullable customName;

- (instancetype)initByEditing:(void(^)(id<GLAHighlightedItemEditing> editor))editingBlock;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedItemEditing> editor))editingBlock;

@end



@protocol GLAHighlightedCollectedItem <NSObject>

@property(readonly, nonatomic) NSUUID *holdingCollectionUUID;

@end

@protocol GLAHighlightedCollectedItemEditing <GLAHighlightedItemEditing>

@property(readwrite, nonatomic) NSUUID *holdingCollectionUUID;

@end



@protocol GLAHighlightedCollectedFileEditing <GLAHighlightedCollectedItemEditing>

@property(readwrite, nonatomic) NSUUID *collectedFileUUID;

@property(readwrite, nonatomic) GLACollectedFile *_Nullable applicationToOpenFile;

@end

@interface GLAHighlightedCollectedFile : GLAHighlightedItem <GLAHighlightedCollectedItem>

@property(readonly, nonatomic) NSUUID *collectedFileUUID;

@property(readonly, nonatomic) GLACollectedFile * _Nullable applicationToOpenFile;

- (instancetype)initByEditing:(void(^)(id<GLAHighlightedCollectedFileEditing> editor))editingBlock;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedCollectedFileEditing> editor))editingBlock;

@end

NS_ASSUME_NONNULL_END
