//
//  GLAMantleObjectJSONStore.m
//  Blik
//
//  Created by Patrick Smith on 17/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAMantleObjectJSONStore.h"
#import "GLAJSONStore.h"


@interface GLAMantleObjectJSONStore ()

@property(readonly, nonatomic) GLAJSONStore *JSONStore;

@end

@implementation GLAMantleObjectJSONStore

- (instancetype)initLoadingFromFileURL:(NSURL *)fileURL modelClass:(Class)modelClass operationQueue:(NSOperationQueue *)operationQueue loadCompletionHandler:(dispatch_block_t)loadCompletionHandler
{
	self = [super init];
	if (self) {
		_fileURL = [fileURL copy];
		_modelClass = modelClass;
		_operationQueue = operationQueue;
		
		GLAJSONStore *JSONStore = [GLAJSONStore new];
		_JSONStore = JSONStore;
		[self setUpJSONStoreWithLoadCompletionHandler:loadCompletionHandler];
		
		[self load];
	}
	return self;
}

- (void)setUpJSONStoreWithLoadCompletionHandler:(dispatch_block_t)loadCompletionHandler
{
	GLAJSONStore *JSONStore = (self.JSONStore);
	(JSONStore.backgroundOperationQueue) = (self.operationQueue);
	
	__weak GLAMantleObjectJSONStore *weakSelf = self;
	
	Class modelClass = (self.modelClass);
	
	(JSONStore.loadCompletionBlock) = ^(NSDictionary *JSON, NSError *error) {
		__strong GLAMantleObjectJSONStore *self = weakSelf;
		if (!self) {
			return;
		}
		
		MTLModel<MTLJSONSerializing> *object = [MTLJSONAdapter modelOfClass:modelClass fromJSONDictionary:JSON error:&error];
		(self.object) = object;
		
		loadCompletionHandler();
	};
}

- (GLAStoringLoadState)loadState
{
	return (self.JSONStore.loadState);
}

- (GLAStoringSaveState)saveState
{
	return (self.JSONStore.saveState);
}

- (void)load
{
	[(self.JSONStore) loadIfNeeded];
}

- (MTLModel<MTLJSONSerializing> *)object
{
	return (self.JSONStore.representedObject);
}

- (void)setObject:(MTLModel<MTLJSONSerializing> *)object
{
	GLAJSONStore *JSONStore = (self.JSONStore);
	
	(JSONStore.representedObject) = object;
	
	// Do this synchronously, as object may be mutable.
	NSDictionary *JSON = [MTLJSONAdapter JSONDictionaryFromModel:object];
	// Then save using JSON store, which is asynchronous.
	[JSONStore saveJSONDictionary:JSON];
}

@end
