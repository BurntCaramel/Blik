//
//  GLAArrayEditor.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;
#import "GLAArrayEditing.h"

@protocol GLAArrayObserving, GLAArrayConstraining;
@class GLAArrayEditorOptions;
@class GLAArrayEditorChanges;


@interface GLAArrayEditor : NSObject <GLAArrayEditing>

// Designated init
- (instancetype)initWithObjects:(NSArray *)objects options:(GLAArrayEditorOptions *)options;

- (instancetype)init;

// Use this method to notify observers and work with changes easily.
- (GLAArrayEditorChanges *)changesMadeInBlock:(GLAArrayEditingBlock)editorBlock;

@property(readonly, copy, nonatomic) NSArray *observers;
@property(readonly, copy, nonatomic) NSArray *constrainers;

- (NSArray *)useConstrainersToFilterPotentialChildren:(NSArray *)potentialChildren;

@end


@interface GLAArrayEditorOptions : NSObject <NSCopying>

- (void)addObserver:(id<GLAArrayObserving>)observer;
- (void)addConstrainer:(id<GLAArrayConstraining>)constrainer;

@property(readonly, copy, nonatomic) NSArray *observers;
@property(readonly, copy, nonatomic) NSArray *constrainers;

@end


@interface GLAArrayEditorChanges : NSObject

@property(readonly, nonatomic) BOOL hasChanges;

@property(readonly, copy, nonatomic) NSArray *addedChildren;
@property(readonly, copy, nonatomic) NSArray *removedChildren;

@property(readonly, copy, nonatomic) NSArray *replacedChildrenBefore;
@property(readonly, copy, nonatomic) NSArray *replacedChildrenAfter;

@end


@protocol GLAArrayObserving <NSObject>

- (void)arrayWasCreated:(id<GLAArrayInspecting>)array;

- (void)array:(id<GLAArrayInspecting>)array didMakeChanges:(GLAArrayEditorChanges *)changes;

@end


@protocol GLAArrayConstraining <GLAArrayObserving>

- (NSArray *)array:(id<GLAArrayInspecting>)array filterPotentialChildren:(NSArray *)potentialChildren;

@end
