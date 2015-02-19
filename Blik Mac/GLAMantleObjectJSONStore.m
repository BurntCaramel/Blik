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

@property(readwrite, nonatomic) NSError *errorLoading;
@property(readwrite, nonatomic) NSError *errorSaving;

@end

@implementation GLAMantleObjectJSONStore

- (instancetype)initWithFileURL:(NSURL *)fileURL modelClass:(Class)modelClass freshlyMade:(BOOL)freshlyMade operationQueue:(NSOperationQueue *)operationQueue loadCompletionHandler:(dispatch_block_t)loadCompletionHandler
{
	self = [super init];
	if (self) {
		_modelClass = modelClass;
		
		_JSONStore = [[GLAJSONStore alloc] initWithFileURL:fileURL backgroundOperationQueue:operationQueue freshlyMade:freshlyMade];
		[self setUpJSONStoreWithLoadCompletionHandler:loadCompletionHandler];
		
		if (!freshlyMade) {
			[self load];
		}
	}
	return self;
}

- (instancetype)initWithFileURL:(NSURL *)fileURL modelClass:(Class)modelClass modelObject:(MTLModel<MTLJSONSerializing> *)modelObject operationQueue:(NSOperationQueue *)operationQueue loadCompletionHandler:(dispatch_block_t)loadCompletionHandler
{
	self = [self initWithFileURL:fileURL modelClass:modelClass freshlyMade:(modelObject != nil) operationQueue:operationQueue loadCompletionHandler:loadCompletionHandler];
	if (self) {
		if (modelObject) {
			(self.object) = modelObject;
		}
	}
	return self;
}

- (void)setUpJSONStoreWithLoadCompletionHandler:(dispatch_block_t)loadCompletionHandler
{
	GLAJSONStore *JSONStore = (self.JSONStore);
	
	__weak GLAMantleObjectJSONStore *weakSelf = self;
	
	Class modelClass = (self.modelClass);
	
	(JSONStore.loadCompletionBlock) = ^(NSDictionary *JSON, NSError *error) {
		__strong GLAMantleObjectJSONStore *self = weakSelf;
		if (!self) {
			return;
		}
		
		MTLModel<MTLJSONSerializing> *object = nil;
		if (JSON) {
			object = [MTLJSONAdapter modelOfClass:modelClass fromJSONDictionary:JSON error:&error];
		}
		
		(self.object) = object;
		
		if (!object) {
			(self.errorLoading) = error;
		}
		
		loadCompletionHandler();
	};
	
	(JSONStore.saveCompletionBlock) = ^(BOOL success, NSError *error) {
		__strong GLAMantleObjectJSONStore *self = weakSelf;
		if (!self) {
			return;
		}
		
		if (!success) {
			(self.errorSaving) = error;
		}
	};
}

- (NSURL *)fileURL
{
	return (self.JSONStore.fileURL);
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
	MTLModel<MTLJSONSerializing> *object = (self.JSONStore.representedObject);
	
	NSAssert((self.freshlyMade) ? (object != nil) : YES, @"Freshly made store must have its object set first before using it.");
	
	return object;
}

- (void)setObject:(MTLModel<MTLJSONSerializing> *)object
{
	GLAJSONStore *JSONStore = (self.JSONStore);
	
	(JSONStore.representedObject) = object;
	
	// Do this synchronously, as object may be mutable.
	NSDictionary *JSON = [MTLJSONAdapter JSONDictionaryFromModel:object];
	NSAssert(JSON != nil, @"Model object must be able to be turned into JSON.");
	// Then save using JSON store, which is asynchronous.
	[JSONStore saveJSONDictionary:JSON];
}

@end
