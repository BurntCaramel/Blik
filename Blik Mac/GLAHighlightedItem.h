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


@protocol GLAHighlightedItemEditing <NSObject>

@property(readwrite, copy, nonatomic) NSUUID *projectUUID;

@end

@interface GLAHighlightedItem : GLAModel

@property(readonly, copy, nonatomic) NSUUID *projectUUID;

- (instancetype)initByEditing:(void(^)(id<GLAHighlightedItemEditing> editor))editingBlock;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedItemEditing> editor))editingBlock;

@end



@protocol GLAHighlightedCollectedItem <NSObject>

@property(readonly, nonatomic) NSUUID *holdingCollectionUUID;

@end

@protocol GLAHighlightedCollectedItemEditing <GLAHighlightedItemEditing>

@property(readwrite, nonatomic) NSUUID *holdingCollectionUUID;

@end



#if 0
@protocol GLAHighlightedCollectionEditing <GLAHighlightedItemEditing>

@property(readwrite, nonatomic) GLACollection *collection;

@end

@interface GLAHighlightedCollection : GLAHighlightedItem

@property(readonly, nonatomic) GLACollection *collection;

- (instancetype)initByEditing:(void(^)(id<GLAHighlightedCollectionEditing> editor))editingBlock;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedCollectionEditing>editor))editingBlock;

@end
#endif


@protocol GLAHighlightedCollectedFileEditing <GLAHighlightedCollectedItemEditing>

@property(readwrite, nonatomic) NSUUID *collectedFileUUID;

@property(readwrite, nonatomic) GLACollectedFile *applicationToOpenFile;

@end

@interface GLAHighlightedCollectedFile : GLAHighlightedItem <GLAHighlightedCollectedItem>

@property(readonly, nonatomic) NSUUID *collectedFileUUID;

@property(readonly, nonatomic) GLACollectedFile *applicationToOpenFile;

- (instancetype)initByEditing:(void(^)(id<GLAHighlightedCollectedFileEditing> editor))editingBlock;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedCollectedFileEditing> editor))editingBlock;

@end
