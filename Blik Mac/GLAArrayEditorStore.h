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


@interface GLAArrayEditorStore : NSObject

- (instancetype)initWithDelegate:(id<GLAArrayEditorStoreDelegate>)delegate modelClass:(Class)modelClass JSONFileURL:(NSURL *)JSONFileURL JSONDictionaryKey:(NSString *)JSONKey arrayEditorOptions:(GLAArrayEditorOptions *)arrayEditorOptions;

@property(weak, readonly, nonatomic) id<GLAArrayEditorStoreDelegate> delegate;

- (void)setUpArrayEditorOptions:(GLAArrayEditorOptions *)options;

@property(readonly, nonatomic) Class modelClass;
@property(copy, readonly, nonatomic) NSURL *JSONFileURL;
@property(copy, readonly, nonatomic) NSString *JSONDictionaryKeyForArray;

@property(copy, nonatomic) NSDictionary *userInfo;

@property(readonly, nonatomic) BOOL needsLoading;

@property(readonly, nonatomic) BOOL loading;
@property(readonly, nonatomic) BOOL finishedLoading;

@property(readonly, nonatomic) BOOL saving;
@property(readonly, nonatomic) BOOL finishedSaving;

- (NSArray *)copyChildren;
- (id<GLAArrayInspecting>)inspectArray;

- (void)editUsingBlock:(void (^)(id<GLAArrayEditing> arrayEditor))block handleAddedChildren:(void (^)(NSArray *addedChildren))addedBlock handleRemovedChildren:(void (^)(NSArray *removedChildren))removedBlock handleReplacedChildren:(void (^)(NSArray *originalChildren, NSArray *replacementChildren))replacedBlock;

- (BOOL)loadWithCompletionBlock:(dispatch_block_t)completionBlock;
- (BOOL)saveWithCompletionBlock:(dispatch_block_t)completionBlock;

- (NSArray *)background_processLoadedChildren:(NSArray *)children;

@end

@interface GLAArrayEditorStore (Errors)

+ (NSString *)errorDomain;

typedef NS_ENUM(NSInteger, GLAArrayEditorStoreErrorCode)
{
	GLAArrayEditorStoreErrorCodeGeneral = 1,
	GLAArrayEditorStoreErrorCodeJSONMissingRequiredKey = 2,
	GLAArrayEditorStoreErrorCodeCannotMakeModelsFromJSONArray = 3
};

+ (NSError *)errorForMissingRequiredKey:(NSString *)dictionaryKey inJSONFileAtURL:(NSURL *)fileURL;
+ (NSError *)errorForCannotMakeModelsOfClass:(Class)modelClass fromJSONArray:(NSArray *)JSONArray loadedFromFileAtURL:(NSURL *)fileURL mantleError:(NSError *)error;

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
