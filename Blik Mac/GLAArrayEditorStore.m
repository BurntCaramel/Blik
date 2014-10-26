//
//  GLAArrayEditorStore.m
//  Blik
//
//  Created by Patrick Smith on 18/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAArrayEditorStore.h"
#import "GLAModelErrors.h"


@interface GLAArrayEditorStore ()

@property(nonatomic) GLAArrayEditor *arrayEditor;

@property(nonatomic) NSBlockOperation *loadOperation;
@property(nonatomic) NSBlockOperation *saveOperation;

@end

@implementation GLAArrayEditorStore

- (instancetype)initWithDelegate:(id<GLAArrayEditorStoreDelegate>)delegate modelClass:(Class)modelClass JSONFileURL:(NSURL *)JSONFileURL JSONDictionaryKey:(NSString *)JSONKey userInfo:(NSDictionary *)userInfo
{
	self = [super init];
	if (self) {
		_delegate = delegate;
		_modelClass = modelClass;
		_JSONFileURL = [JSONFileURL copy];
		_JSONDictionaryKeyForArray = [JSONKey copy];
		_userInfo = [userInfo copy];
	}
	return self;
}

- (NSOperationQueue *)foregroundOperationQueue
{
	id<GLAArrayEditorStoreDelegate> delegate = (self.delegate);
	NSAssert(delegate != nil, @"GLAArrayEditorStore must have an delegate.");
	
	return [delegate foregroundOperationQueueForArrayEditorStore:self];
}

- (NSOperationQueue *)backgroundOperationQueue
{
	id<GLAArrayEditorStoreDelegate> delegate = (self.delegate);
	NSAssert(delegate != nil, @"GLAArrayEditorStore must have an delegate.");
	
	return [delegate backgroundOperationQueueForArrayEditorStore:self];
}

- (NSBlockOperation *)runInBackground:(void (^)(GLAArrayEditorStore *store))block
{
	__weak GLAArrayEditorStore *weakStore = self;
	
	NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
		GLAArrayEditorStore *store = weakStore;
		
		block(store);
	}];
	[(self.backgroundOperationQueue) addOperation:blockOperation];
	
	return blockOperation;
}

- (void)runInForeground:(void (^)(GLAArrayEditorStore *store))block
{
	__weak GLAArrayEditorStore *weakStore = self;
	
	[(self.foregroundOperationQueue) addOperationWithBlock:^{
		GLAArrayEditorStore *store = weakStore;
		
		block(store);
	}];
}

- (void)handleError:(NSError *)error fromMethodWithSelector:(SEL)methodSelector
{
	id<GLAArrayEditorStoreDelegate> delegate = (self.delegate);
	if (!delegate) {
		return;
	}
	
	[delegate arrayEditorStore:self handleError:error fromMethodWithSelector:methodSelector];
}

- (NSDictionary *)background_readJSONDictionaryFromFileURL:(NSURL *)fileURL
{
	NSError *error = nil;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:(fileURL.path)]) {
		return nil;
	}
	
	NSData *JSONData = [NSData dataWithContentsOfURL:fileURL options:0 error:&error];
	if (!JSONData) {
		[self handleError:error fromMethodWithSelector:_cmd];
		return nil;
	}
	
	NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
	if (!JSONDictionary) {
		[self handleError:error fromMethodWithSelector:_cmd];
		return nil;
	}
	
	return JSONDictionary;
}

- (NSArray *)background_readModelsOfClass:(Class)modelClass atDictionaryKey:(NSString *)JSONKey fromJSONFileURL:(NSURL *)fileURL
{
	NSError *error = nil;
	
	NSDictionary *JSONDictionary = [self background_readJSONDictionaryFromFileURL:fileURL];
	if (!JSONDictionary) {
		return nil;
	}
	
	NSArray *JSONArray = JSONDictionary[JSONKey];
	if (!JSONArray) {
		error = [GLAModelErrors errorForMissingRequiredKey:JSONKey inJSONFileAtURL:fileURL];
		[self handleError:error fromMethodWithSelector:_cmd];
		return nil;
	}
	
	NSArray *models = [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:JSONArray error:&error];
	if (!models) {
		[self handleError:error fromMethodWithSelector:_cmd];
		return nil;
	}
	
	return models;
}

- (BOOL)background_writeJSONDictionary:(NSDictionary *)JSONDictionary toFileURL:(NSURL *)fileURL
{
	NSError *error = nil;
	
	NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONDictionary options:0 error:&error];
	if (!JSONData) {
		[self handleError:error fromMethodWithSelector:_cmd];
		return NO;
	}
	
	[JSONData writeToURL:fileURL atomically:YES];
	
	return YES;
}

#pragma mark -

- (NSArray *)copyChildren
{
	GLAArrayEditor *arrayEditor = (self.arrayEditor);
	if (!arrayEditor) {
		return nil;
	}
	
	return [arrayEditor copyChildren];
}

#pragma mark -

- (NSArray *)processAddedChildren:(NSArray *)children childrenWereLoaded:(BOOL)loaded
{
	id<GLAArrayEditorStoreDelegate> delegate = (self.delegate);
	if ((delegate == nil) || ![delegate respondsToSelector:@selector(arrayEditorStore:processAddedChildren:childrenWereLoaded:)]) {
		return children;
	}
	
	return [delegate arrayEditorStore:self processAddedChildren:children childrenWereLoaded:loaded];
}

- (void)editUsingBlock:(void (^)(id<GLAArrayEditing> arrayEditor))block handleAddedChildren:(void (^)(NSArray *addedChildren))addedBlock handleRemovedChildren:(void (^)(NSArray *removedChildren))removedBlock handleReplacedChildren:(void (^)(NSArray *originalChildren, NSArray *replacementChildren))replacedBlock
{
	GLAArrayEditor *arrayEditor = (self.arrayEditor);
	NSAssert(arrayEditor != nil, @"Can't edit without having loaded.");
	
	GLAArrayEditorChanges *changes = [arrayEditor changesMadeInBlock:block];
	NSArray *addedChildren = (changes.addedChildren);
	NSArray *removedChildren = (changes.removedChildren);
	NSArray *replacedChildrenBefore = (changes.replacedChildrenBefore);
	NSArray *replacedChildrenAfter = (changes.replacedChildrenAfter);
	
	if ((addedChildren.count) > 0) {
		addedChildren = [self processAddedChildren:addedChildren childrenWereLoaded:NO];
		
		if (addedBlock) {
			addedBlock(addedChildren);
		}
	}
	
	if ((removedChildren.count) > 0 && (removedBlock != nil)) {
		removedBlock(removedChildren);
	}
	
	if ((replacedChildrenBefore.count) > 0 && (replacedBlock != nil)) {
		replacedBlock(replacedChildrenBefore, replacedChildrenAfter);
	}
	
	[self saveWithCompletionBlock:nil];
	
	//
	//[delegate arrayEditorStore:self didAddChildren:(changes.addedChildren)];
	//[delegate arrayEditorStore:self didRemoveChildren:(changes.removedChildren)];
}

- (BOOL)loadWithCompletionBlock:(dispatch_block_t)completionBlock
{
	if ((self.loading) || (self.saving)) {
		return NO;
	}
	
	(self.loadOperation) = [self runInBackground:^(GLAArrayEditorStore *store) {
		NSArray *loadedChildren = [store background_readModelsOfClass:(store.modelClass) atDictionaryKey:(store.JSONDictionaryKeyForArray) fromJSONFileURL:(store.JSONFileURL)];
		
		if (!loadedChildren) {
			loadedChildren = @[];
		}
		
		[store runInForeground:^(GLAArrayEditorStore *store) {
			NSArray *processedChildren = [store processAddedChildren:loadedChildren childrenWereLoaded:YES];
			
			(store.arrayEditor) = [[GLAArrayEditor alloc] initWithObjects:processedChildren];
			
			if (completionBlock) {
				completionBlock();
			}
		}];
	}];
	
	return YES;
}

- (BOOL)loading
{
	NSBlockOperation *loadOperation = (self.loadOperation);
	if (!loadOperation) {
		return NO;
	}
	
	return (loadOperation.isExecuting);
}

- (BOOL)saveWithCompletionBlock:(dispatch_block_t)completionBlock
{
	if ((self.loading) || (self.saving)) {
		return NO;
	}
	
	NSArray *array = [self copyChildren];
	
	(self.saveOperation) = [self runInBackground:^(GLAArrayEditorStore *store) {
		NSArray *JSONArray = [MTLJSONAdapter JSONArrayFromModels:array];
		NSString *JSONKey = (self.JSONDictionaryKeyForArray);
		
		NSDictionary *JSONDictionary =
		@{
		  JSONKey: JSONArray
		  };
		
		[store background_writeJSONDictionary:JSONDictionary toFileURL:(self.JSONFileURL)];
		
		[store runInForeground:^(GLAArrayEditorStore *store) {
			if (completionBlock) {
				completionBlock();
			}
		}];
	}];
	
	return YES;
}

- (BOOL)saving
{
	NSBlockOperation *saveOperation = (self.saveOperation);
	if (!saveOperation) {
		return NO;
	}
	
	return (saveOperation.isExecuting);
}

@end
