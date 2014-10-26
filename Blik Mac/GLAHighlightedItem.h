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


@interface GLAHighlightedItem : GLAModel

@end



@protocol GLAHighlightedCollectionEditing <NSObject>

@property(readwrite, nonatomic) GLACollection *collection;

@end

@interface GLAHighlightedCollection : GLAHighlightedItem

@property(readonly, nonatomic) GLACollection *collection;

+ (instancetype)newCreatingFromEditing:(void(^)(id<GLAHighlightedCollectionEditing> editor))editingBlock;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedCollectionEditing>editor))editingBlock;

@end



@protocol GLAHighlightedCollectedFileEditing <NSObject>

@property(readwrite, nonatomic) GLACollectedFile *collectedFile;
@property(readwrite, nonatomic) GLACollection *holdingCollection;

@property(readwrite, nonatomic) GLACollectedFile *applicationToOpenFile;


@end

@interface GLAHighlightedCollectedFile : GLAHighlightedItem

@property(readonly, nonatomic) GLACollectedFile *collectedFile;
@property(readonly, nonatomic) GLACollection *holdingCollection;

@property(readonly, nonatomic) GLACollectedFile *applicationToOpenFile;

+ (instancetype)newCreatingFromEditing:(void(^)(id<GLAHighlightedCollectedFileEditing> editor))editingBlock;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedCollectedFileEditing>editor))editingBlock;

@end