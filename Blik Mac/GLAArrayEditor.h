//
//  GLAArrayEditor.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;
#import "GLAArrayEditing.h"

@protocol GLAArrayEditorObserving, GLAArrayEditorIndexing, GLAArrayEditorConstraining, GLAArrayStoring;
@class GLAArrayEditorOptions;
@class GLAArrayEditorChanges;


@interface GLAArrayEditor : NSObject <GLAArrayInspecting>

// Designated init
- (instancetype)initWithObjects:(NSArray *)objects options:(GLAArrayEditorOptions *)options NS_DESIGNATED_INITIALIZER;

- (instancetype)init;

// Use this method to notify observers and work with changes easily.
- (GLAArrayEditorChanges *)changesMadeInBlock:(GLAArrayEditingBlock)editorBlock;
- (void)addChildren:(NSArray *)objects queueIfNeedsLoading:(BOOL)queue;

// Use this if a primary indexer was passed at initialization.
- (id)objectForKeyedSubscript:(id <NSCopying>)key;

@property(readonly, nonatomic) id<GLAArrayStoring> store;
@property(readonly, nonatomic) BOOL needsLoadingFromStore;
@property(readonly, nonatomic) BOOL finishedLoadingFromStore;

- (NSArray *)constrainPotentialChildren:(NSArray *)potentialChildren;

@end


@interface GLAArrayEditorOptions : NSObject <NSCopying>

- (void)addObserver:(id<GLAArrayEditorObserving>)observer;

- (void)addIndexer:(id<GLAArrayEditorIndexing>)indexer;
- (void)setPrimaryIndexer:(id<GLAArrayEditorIndexing>)indexer;

- (void)addConstrainer:(id<GLAArrayEditorConstraining>)constrainer;

- (void)setStore:(id<GLAArrayStoring>)store;

@end


@interface GLAArrayEditorChanges : NSObject

@property(readonly, nonatomic) BOOL hasChanges;

@property(readonly, copy, nonatomic) NSArray *addedChildren;
@property(readonly, copy, nonatomic) NSArray *removedChildren;

@property(readonly, copy, nonatomic) NSArray *replacedChildrenBefore;
@property(readonly, copy, nonatomic) NSArray *replacedChildrenAfter;

@property(readonly, nonatomic) BOOL didMoveChildren;

@end


@protocol GLAArrayEditorObserving <NSObject>

@optional

- (void)arrayEditorWasCreated:(GLAArrayEditor *)arrayEditor;
- (void)arrayEditorDidLoad:(GLAArrayEditor *)arrayEditor;

- (void)arrayEditor:(GLAArrayEditor *)arrayEditor didMakeChanges:(GLAArrayEditorChanges *)changes;

@end


@protocol GLAArrayEditorIndexing <GLAArrayEditorObserving>

// Return nil if key is not indexed by the receiver.
- (id)arrayEditor:(GLAArrayEditor *)array firstIndexedChildWhoseKey:(NSString *)key hasValue:(id)value;

@end


@protocol GLAArrayEditorConstraining <GLAArrayEditorObserving>

- (NSArray *)arrayEditor:(GLAArrayEditor *)array filterPotentialChildren:(NSArray *)potentialChildren;

@end



typedef NS_ENUM(NSUInteger, GLAArrayStoringLoadState) {
	GLAArrayStoringLoadStateNeedsLoading,
	GLAArrayStoringLoadStateCurrentlyLoading,
	GLAArrayStoringLoadStateFinishedLoading
};

typedef NS_ENUM(NSUInteger, GLAArrayStoringSaveState) {
	GLAArrayStoringSaveStateNeedsSaving,
	GLAArrayStoringSaveStateCurrentlySaving,
	GLAArrayStoringSaveStateFinishedSaving
};


@protocol GLAArrayStoring <GLAArrayEditorObserving>

@property(readonly, nonatomic) BOOL freshlyMade;

@property(readonly, nonatomic) GLAArrayStoringLoadState loadState;
- (BOOL)loadIfNeededWithChildProcessor:(GLAArrayChildVisitorBlock)childProcessor completionBlock:(void (^)(NSArray *loadedItems))completionBlock;

@property(readonly, nonatomic) GLAArrayStoringSaveState saveState;
// Changes have been sent via GLAArrayObserving methods.
- (BOOL)saveIfNeededWithCompletionBlock:(dispatch_block_t)completionBlock;

@end

extern NSString *GLAArrayStoringDidLoadNotification;
extern NSString *GLAArrayStoringDidLoadNotificationUserInfoLoadedChildren;
