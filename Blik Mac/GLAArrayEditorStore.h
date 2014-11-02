//
//  GLAArrayEditorStore.h
//  Blik
//
//  Created by Patrick Smith on 18/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;
#import "GLAArrayEditor.h"
#import "Mantle/Mantle.h"

@protocol GLAArrayEditorStoreDelegate;

/*
@interface GLAArrayEditorStoreDescriptor : NSObject

@end
 */


// For All Projects, Project's Collections, Project's Highlights

@interface GLAArrayEditorStore : NSObject

- (instancetype)initWithDelegate:(id<GLAArrayEditorStoreDelegate>)delegate modelClass:(Class)modelClass JSONFileURL:(NSURL *)JSONFileURL JSONDictionaryKey:(NSString *)JSONKey userInfo:(NSDictionary *)userInfo;

@property(nonatomic, weak, readonly) id<GLAArrayEditorStoreDelegate> delegate;

@property(nonatomic, readonly) Class modelClass;
@property(nonatomic, copy, readonly) NSDictionary *userInfo;

@property(nonatomic, copy, readonly) NSURL *JSONFileURL;
@property(nonatomic, copy, readonly) NSString *JSONDictionaryKeyForArray;

@property(nonatomic, readonly) BOOL needsLoading;

@property(nonatomic, readonly) BOOL loading;
@property(nonatomic, readonly) BOOL finishedLoading;
//@property(nonatomic, readonly) BOOL hasMadeChangesSinceLoading;
@property(nonatomic, readonly) BOOL saving;
@property(nonatomic, readonly) BOOL finishedSaving;

- (NSArray *)copyChildren;
- (id<GLAArrayInspecting>)inspectArray;

- (void)editUsingBlock:(void (^)(id<GLAArrayEditing> arrayEditor))block handleAddedChildren:(void (^)(NSArray *addedChildren))addedBlock handleRemovedChildren:(void (^)(NSArray *removedChildren))removedBlock handleReplacedChildren:(void (^)(NSArray *originalChildren, NSArray *replacementChildren))replacedBlock;

- (BOOL)loadWithCompletionBlock:(dispatch_block_t)completionBlock;
- (BOOL)saveWithCompletionBlock:(dispatch_block_t)completionBlock;

- (NSArray *)background_processLoadedChildren:(NSArray *)children;

@end


@protocol GLAArrayEditorStoreDelegate <NSObject>

- (NSOperationQueue *)foregroundOperationQueueForArrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore;
- (NSOperationQueue *)backgroundOperationQueueForArrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore;

- (void)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore handleError:(NSError *)error fromMethodWithSelector:(SEL)storeMethodSelector;

@optional

- (NSArray *)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore processLoadedChildrenInBackground:(NSArray *)children;

- (void)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore didLoadChildren:(NSArray *)children;

- (void)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore didAddChildren:(NSArray *)addedChildren;
- (void)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore didRemoveChildren:(NSArray *)removedChildren;
- (void)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore didReplaceChildren:(NSArray *)replacedChildrenBefore with:(NSArray *)replacedChildrenAfter;

@end
