//
//  GLAArrayMantleJSONStore.m
//  Blik
//
//  Created by Patrick Smith on 11/12/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAArrayMantleJSONStore.h"


@protocol GLAArrayMantleJSONStoreInternalProperties <NSObject>

@property(nonatomic) GLAArrayStoringLoadState internal_loadState;
@property(nonatomic) GLAArrayStoringSaveState internal_saveState;

@end

@interface GLAArrayMantleJSONStore ()
{
	GLAArrayStoringLoadState _internal_loadState;
	GLAArrayStoringSaveState _internal_saveState;
}

@property(nonatomic) dispatch_queue_t stateDispatchQueue;

@property(nonatomic) NSOperation *background_saveOperation;

@end

@interface GLAArrayMantleJSONStore (GLAArrayMantleJSONStoreInternalProperties) <GLAArrayMantleJSONStoreInternalProperties>

@end

@implementation GLAArrayMantleJSONStore

@synthesize freshlyMade = _freshlyMade;

@synthesize internal_loadState = _internal_loadState;
@synthesize internal_saveState = _internal_saveState;

- (instancetype)initWithModelClass:(Class)modelClass JSONFileURL:(NSURL *)JSONFileURL JSONDictionaryKey:(NSString *)JSONKey freshlyMade:(BOOL)freshlyMade operationQueue:(NSOperationQueue *)operationQueue errorHandler:(id<GLAArrayMantleJSONStoreErrorHandler>)errorHandler
{
	self = [super init];
	if (self) {
		_modelClass = modelClass;
		_JSONFileURL = [JSONFileURL copy];
		_JSONDictionaryKeyForArray = [JSONKey copy];
		
		_freshlyMade = freshlyMade;
		_internal_loadState = (freshlyMade) ? GLAArrayStoringLoadStateFinishedLoading : GLAArrayStoringLoadStateNeedsLoading;
		_internal_saveState = GLAArrayStoringSaveStateNeedsSaving;
		
		_operationQueue = operationQueue;
		
		_errorHandler = errorHandler;
		_stateDispatchQueue = dispatch_queue_create("com.burntcaramel.GLAArrayMantleJSONStore.input", DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

- (instancetype)init
{
	return nil;
}

#pragma mark GLAArrayObserving

- (void)arrayEditor:(GLAArrayEditor *)arrayEditor didMakeChanges:(GLAArrayEditorChanges *)changes
{
	[self saveChildren:[arrayEditor copyChildren]];
}

#pragma mark -

- (NSBlockOperation *)runInBackgroundAsync:(void (^)(GLAArrayMantleJSONStore *store))block
{
	__weak GLAArrayMantleJSONStore *weakSelf = self;
	
	NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
		GLAArrayMantleJSONStore *strongObject = weakSelf;
		if (strongObject) {
			block(strongObject);
		}
	}];
	[(self.operationQueue) addOperation:blockOperation];
	
	return blockOperation;
}

- (void)handleError:(NSError *)error fromMethodWithSelector:(SEL)methodSelector
{
	id<GLAArrayMantleJSONStoreErrorHandler> errorHandler = (self.errorHandler);
	if (!errorHandler) {
		return;
	}
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		[errorHandler arrayMantleJSONStore:self handleError:error];
	}];
}

- (NSDictionary *)background_readJSONDictionaryFromFile
{
	NSURL *fileURL = (self.JSONFileURL);
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

- (NSArray *)background_readModelsFromJSONFile
{
	Class modelClass = (self.modelClass);
	NSString *JSONKey = (self.JSONDictionaryKeyForArray);
	NSError *error = nil;
	
	NSDictionary *JSONDictionary = [self background_readJSONDictionaryFromFile];
	if (!JSONDictionary) {
		return nil;
	}
	
	NSArray *JSONArray = JSONDictionary[JSONKey];
	if (!JSONArray) {
		error = [[self class] errorForMissingRequiredKey:JSONKey inJSONFileAtURL:(self.JSONFileURL)];
		[self handleError:error fromMethodWithSelector:_cmd];
		return nil;
	}
	
	NSArray *models = [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:JSONArray error:&error];
	if (!models) {
		error = [[self class] errorForCannotMakeModelsOfClass:modelClass fromJSONArray:JSONArray loadedFromFileAtURL:(self.JSONFileURL) mantleError:error];
		[self handleError:error fromMethodWithSelector:_cmd];
		return nil;
	}
	
	return models;
}

- (BOOL)background_writeJSONDictionary:(NSDictionary *)JSONDictionary toFileURL:(NSURL *)fileURL
{
	NSError *error = nil;
	
	NSData *JSONData = nil;
	@try {
		JSONData = [NSJSONSerialization dataWithJSONObject:JSONDictionary options:0 error:&error];
		if (!JSONData) {
			[self handleError:error fromMethodWithSelector:_cmd];
			return NO;
		}
	}
	@catch (NSException *e) {
		NSLog(@"EXCEPTION converting to JSON %@", JSONDictionary);
		@throw e;
	}
	
	[JSONData writeToURL:fileURL atomically:YES];
	
	return YES;
}

#pragma mark -

- (GLAArrayStoringLoadState)loadState
{
	__block GLAArrayStoringLoadState loadState;
	dispatch_sync((self.stateDispatchQueue), ^{
		loadState = (self.internal_loadState);
	});
	return loadState;
}

- (GLAArrayStoringSaveState)saveState
{
	__block GLAArrayStoringSaveState saveState;
	dispatch_sync((self.stateDispatchQueue), ^{
		saveState = (self.internal_saveState);
	});
	return saveState;
}

- (void)useStateAsync:(void (^)(id<GLAArrayMantleJSONStoreInternalProperties> internalProperties))block
{
	NSParameterAssert(block != nil);
	
	__weak id weakSelf = self;
	dispatch_async((self.stateDispatchQueue), ^{
		__strong id strongSelf = weakSelf;
		if (!strongSelf) {
			return;
		}
		
		block(strongSelf);
	});
}

- (void)useStateSync:(void (^)(id<GLAArrayMantleJSONStoreInternalProperties> internalProperties))block
{
	NSParameterAssert(block != nil);
	
	dispatch_sync((self.stateDispatchQueue), ^{
		block(self);
	});
}

#pragma mark -

- (BOOL)loadIfNeededWithChildProcessor:(GLAArrayChildVisitorBlock)childProcessor completionBlock:(void (^)(NSArray *loadedItems))completionBlock;
{
	__block BOOL needsLoading;
	[self useStateSync:^(id<GLAArrayMantleJSONStoreInternalProperties> internalProperties) {
		needsLoading = ((self.internal_loadState) == GLAArrayStoringLoadStateNeedsLoading);
		
		if (needsLoading) {
			(internalProperties.internal_loadState) = GLAArrayStoringLoadStateCurrentlyLoading;
		}
	}];
	// Don't allow loading to be queued multiple times.
	if ( ! needsLoading ) {
		return NO;
	}
	
	[self runInBackgroundAsync:^(GLAArrayMantleJSONStore *store) {
		NSArray *loadedChildren = [store background_readModelsFromJSONFile];
		if (loadedChildren) {
			if (childProcessor) {
				NSMutableArray *processedChildren = [NSMutableArray arrayWithCapacity:(loadedChildren.count)];
				for (id child in loadedChildren) {
					id processedChild = childProcessor(child);
					[processedChildren addObject:processedChild];
				}
				loadedChildren = processedChildren;
			}
		}
		else {
			loadedChildren = @[];
		}
		
		[store useStateAsync:^(id<GLAArrayMantleJSONStoreInternalProperties> internalProperties) {
			(internalProperties.internal_loadState) = GLAArrayStoringLoadStateFinishedLoading;
		}];
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			NSDictionary *notificationInfo =
			@{
			  GLAArrayStoringDidLoadNotificationUserInfoLoadedChildren: loadedChildren
			  };
			[[NSNotificationCenter defaultCenter] postNotificationName:GLAArrayStoringDidLoadNotification object:store userInfo:notificationInfo];
			
			// Completion block is not guaranteed to run on main queue,
			// it's just that it needs to be called after the notification
			// has been sent.
			completionBlock(loadedChildren);
		}];
	}];
	
	return YES;
}

- (BOOL)saveIfNeededWithCompletionBlock:(dispatch_block_t)completionBlock
{
	// Saving is automatically queued as changes occur.
	return NO;
}

- (void)saveChildren:(NSArray *)childrenToSave
{
	__block BOOL wasAlreadySaving;
	[self useStateSync:^(id<GLAArrayMantleJSONStoreInternalProperties> internalProperties) {
		wasAlreadySaving = ((self.internal_saveState) == GLAArrayStoringSaveStateCurrentlySaving);
		
		(self.internal_saveState) = GLAArrayStoringSaveStateCurrentlySaving;
	}];
	
	if (wasAlreadySaving) {
		[(self.background_saveOperation) cancel];
	}
	
	NSArray *array = childrenToSave;
	NSString *JSONKey = (self.JSONDictionaryKeyForArray);
	NSURL *JSONFileURL = (self.JSONFileURL);
	
	NSOperation *saveOperation = [self runInBackgroundAsync:^(GLAArrayMantleJSONStore *store) {
		if (saveOperation.cancelled) {
			return;
		}
		
		NSArray *JSONArray = [MTLJSONAdapter JSONArrayFromModels:array];
		
		NSDictionary *JSONDictionary =
		@{
		  JSONKey: JSONArray
		  };
		
		[store background_writeJSONDictionary:JSONDictionary toFileURL:JSONFileURL];
		
		[store useStateAsync:^(id<GLAArrayMantleJSONStoreInternalProperties> internalProperties) {
			(internalProperties.internal_saveState) = GLAArrayStoringSaveStateFinishedSaving;
		}];
	}];
	(self.background_saveOperation) = saveOperation;
}

@end

@implementation GLAArrayMantleJSONStore (Errors)

+ (NSString *)errorDomain
{
	return @"GLAArrayMantleJSONStore.errorDomain";
}

+ (NSError *)errorForMissingRequiredKey:(NSString *)dictionaryKey inJSONFileAtURL:(NSURL *)fileURL
{
	NSString *descriptionFilledOut = NSLocalizedString(@"Saved file is missing essential information.", @"Error description for JSON file not containing required key");
	
	NSString *failureReasonPlaceholder = NSLocalizedString(@"JSON file (%@) does not contain required key (%@).", @"Error failure reason for JSON file not containing required key");
	NSString *failureReasonFilledOut = [NSString localizedStringWithFormat:failureReasonPlaceholder, (fileURL.path), dictionaryKey];
	
	NSDictionary *errorInfo =
	@{
	  NSLocalizedDescriptionKey: descriptionFilledOut,
	  NSLocalizedFailureReasonErrorKey: failureReasonFilledOut
	  };
	
	return [NSError errorWithDomain:[self errorDomain] code:GLAArrayMantleJSONEditorStoreErrorCodeJSONMissingRequiredKey userInfo:errorInfo];
}

+ (NSError *)errorForCannotMakeModelsOfClass:(Class)modelClass fromJSONArray:(NSArray *)JSONArray loadedFromFileAtURL:(NSURL *)fileURL mantleError:(NSError *)error
{
	NSString *descriptionFilledOut = NSLocalizedString(@"Saved JSON file is invalid.", @"Error description for JSON file is invalid");
	
	NSString *failureReasonPlaceholder = NSLocalizedString(@"JSON array from file (%@) cannot be made into instances of %@.", @"Error failure reason for JSON file not containing required key");
	NSString *failureReasonFilledOut = [NSString localizedStringWithFormat:failureReasonPlaceholder, (fileURL.path), NSStringFromClass(modelClass)];
	
	NSDictionary *errorInfo =
	@{
	  NSLocalizedDescriptionKey: descriptionFilledOut,
	  NSLocalizedFailureReasonErrorKey: failureReasonFilledOut,
	  NSURLErrorKey: fileURL,
	  NSUnderlyingErrorKey: error
	  };
	
	return [NSError errorWithDomain:[self errorDomain] code:GLAArrayMantleJSONEditorStoreErrorCodeCannotMakeModelsFromJSONArray userInfo:errorInfo];
}

@end
