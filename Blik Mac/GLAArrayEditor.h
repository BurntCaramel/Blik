//
//  GLAArrayEditor.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;
#import "GLAArrayEditing.h"

@protocol GLAArrayEditorConstraining;
@class GLAArrayEditorChanges;


@interface GLAArrayEditor : NSObject <GLAArrayEditing>

// Designated init
//- (instancetype)initWithObjects:(NSArray *)objects constrainers:(NSArray *)constrainers;
- (instancetype)initWithObjects:(NSArray *)objects;
- (instancetype)init;

- (GLAArrayEditorChanges *)changesMadeInBlock:(void (^)(id<GLAArrayEditing> arrayEditor))editorBlock;

//@property(readonly, copy, nonatomic) NSArray *constrainers;

@end


@protocol GLAArrayEditorConstraining <NSObject>

- (void)didMakeChanges:(GLAArrayEditorChanges *)changes toArray:(id<GLAArrayInspecting>)array;

- (NSArray *)filterPotentialChildren:(NSArray *)objects;

@end


@interface GLAArrayEditorChanges : NSObject

@property(readonly, nonatomic) BOOL hasChanges;

@property(readonly, copy, nonatomic) NSArray *addedChildren;
@property(readonly, copy, nonatomic) NSArray *removedChildren;

@property(readonly, copy, nonatomic) NSArray *replacedChildrenBefore;
@property(readonly, copy, nonatomic) NSArray *replacedChildrenAfter;

@end
