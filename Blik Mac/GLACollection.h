//
//  GLAProjectItem.h
//  Blik
//
//  Created by Patrick Smith on 18/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAModel.h"
@class GLAProject;
@class GLACollectionColor;


extern NSString *GLACollectionTypeFilesList;
extern NSString *GLACollectionTypeFilteredFolder;

extern NSString *GLACollectionViewModeList;
extern NSString *GLACollectionViewModeExpanded;


@protocol GLACollectedItem <NSObject>

@property(readonly, nonatomic) NSUUID *UUID;

@property(readonly, copy, nonatomic) NSString *name;

@end


@protocol GLACollectionEditing <NSObject>

@property(readwrite, copy, nonatomic) NSUUID *projectUUID;

@property(readwrite, copy, nonatomic) NSString *name;
@property(readwrite, nonatomic) GLACollectionColor *color;
@property(readwrite, copy, nonatomic) NSString *viewMode;

@end


@interface GLACollection : GLAModel <GLACollectedItem>

@property(readonly, nonatomic) NSString *type;

@property(readonly, copy, nonatomic) NSUUID *projectUUID;

@property(readonly, copy, nonatomic) NSString *name;
@property(readonly, nonatomic) GLACollectionColor *color;
@property(readonly, copy, nonatomic) NSString *viewMode;

- (instancetype)initWithType:(NSString *)collectionType creatingFromEditing:(void(^)(id<GLACollectionEditing> editor))editingBlock;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLACollectionEditing> editor))editingBlock;

@end


@interface GLACollection (GLADummyContent)

+ (instancetype)dummyCollectionWithName:(NSString *)name color:(GLACollectionColor *)color type:(NSString *)collectionType;

@end
