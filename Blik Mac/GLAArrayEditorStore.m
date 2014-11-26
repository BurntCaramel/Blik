//
//  GLAArrayEditorStore.m
//  Blik
//
//  Created by Patrick Smith on 18/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAArrayEditorStore.h"


@interface GLAArrayEditorStore ()

@property(nonatomic) GLAArrayEditor *arrayEditor;
@property(nonatomic) GLAArrayEditorOptions *arrayEditorOptions;

@property(nonatomic, readwrite) BOOL loading;
@property(nonatomic, readwrite) BOOL finishedLoading;

@property(nonatomic, readwrite) BOOL saving;
@property(nonatomic, readwrite) BOOL finishedSaving;

@end

@implementation GLAArrayEditorStore

- (instancetype)initWithDelegate:(id<GLAArrayEditorStoreDelegate>)delegate modelClass:(Class)modelClass JSONFileURL:(NSURL *)JSONFileURL JSONDictionaryKey:(NSString *)JSONKey userInfo:(NSDictionary *)userInfo arrayEditorOptions:(GLAArrayEditorOptions *)arrayEditorOptions
{
	self = [super init];
	if (self) {
		_delegate = delegate;
		_modelClass = modelClass;
		_JSONFileURL = [JSONFileURL copy];
		_JSONDictionaryKeyForArray = [JSONKey copy];
		_userInfo = [userInfo copy];
		_arrayEditorOptions = arrayEditorOptions ? [arrayEditorOptions copy] : [GLAArrayEditorOptions new];
	}
	return self;
}

- (void)setUpArrayEditorOptions:(GLAArrayEditorOptions *)options
{
	
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
		error = [[self class] errorForMissingRequiredKey:JSONKey inJSONFileAtURL:fileURL];
		[self handleError:error fromMethodWithSelector:_cmd];
		return nil;
	}
	
	NSArray *models = [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:JSONArray error:&error];
	if (!models) {
		error = [[self class] errorForCannotMakeModelsOfClass:modelClass fromJSONArray:JSONArray loadedFromFileAtURL:fileURL mantleError:error];
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

- (NSArray *)copyChildren
{
	GLAArrayEditor *arrayEditor = (self.arrayEditor);
	if (!arrayEditor) {
		return nil;
	}
	
	return [arrayEditor copyChildren];
}

- (id<GLAArrayInspecting>)inspectArray
{
	GLAArrayEditor *arrayEditor = (self.arrayEditor);
	return arrayEditor;
}

#pragma mark -

- (NSArray *)background_processLoadedChildren:(NSArray *)children
{
	id<GLAArrayEditorStoreDelegate> delegate = (self.delegate);
	if ((delegate != nil) && [delegate respondsToSelector:@selector(arrayEditorStore:processLoadedChildrenInBackground:)]) {
		children = [delegate arrayEditorStore:self processLoadedChildrenInBackground:children];
		children = [children copy];
	}
	
	return children;
}

- (void)editUsingBlock:(void (^)(id<GLAArrayEditing> arrayEditor))block handleAddedChildren:(void (^)(NSArray *addedChildren))addedBlock handleRemovedChildren:(void (^)(NSArray *removedChildren))removedBlock handleReplacedChildren:(void (^)(NSArray *originalChildren, NSArray *replacementChildren))replacedBlock
{
	GLAArrayEditor *arrayEditor = (self.arrayEditor);
	NSAssert(arrayEditor != nil, @"Can't edit without having loaded.");
	
	id<GLAArrayEditorStoreDelegate> delegate = (self.delegate);
	
	GLAArrayEditorChanges *changes = [arrayEditor changesMadeInBlock:block];
	NSArray *addedChildren = (changes.addedChildren);
	NSArray *removedChildren = (changes.removedChildren);
	NSArray *replacedChildrenBefore = (changes.replacedChildrenBefore);
	NSArray *replacedChildrenAfter = (changes.replacedChildrenAfter);
	
	if ((addedChildren.count) > 0) {
		if ((delegate != nil) && [delegate respondsToSelector:@selector(arrayEditorStore:didAddChildren:)]) {
			[delegate arrayEditorStore:self didAddChildren:addedChildren];
		}
		
		if (addedBlock) {
			addedBlock(addedChildren);
		}
	}
	
	if ((removedChildren.count) > 0) {
		if ((delegate != nil) && [delegate respondsToSelector:@selector(arrayEditorStore:didRemoveChildren:)]) {
			[delegate arrayEditorStore:self didRemoveChildren:removedChildren];
		}
		
		if (removedBlock) {
			removedBlock(removedChildren);
		}
	}
	
	if ((replacedChildrenBefore.count) > 0) {
		if ((delegate != nil) && [delegate respondsToSelector:@selector(arrayEditorStore:didReplaceChildren:with:)]) {
			[delegate arrayEditorStore:self didReplaceChildren:replacedChildrenBefore with:replacedChildrenAfter];
		}
		
		if (replacedBlock) {
			replacedBlock(replacedChildrenBefore, replacedChildrenAfter);
		}
	}
	
	[self saveWithCompletionBlock:nil];
	
	//
	//[delegate arrayEditorStore:self didAddChildren:(changes.addedChildren)];
	//[delegate arrayEditorStore:self didRemoveChildren:(changes.removedChildren)];
}

- (BOOL)needsLoading
{
	if (self.loading) {
		return NO;
	}
	
	if (self.finishedLoading) {
		return NO;
	}
	
	return YES;
}

- (BOOL)loadWithCompletionBlock:(dispatch_block_t)completionBlock
{
	if ((self.loading) || (self.saving)) {
		return NO;
	}
	
	GLAArrayEditorOptions *arrayEditorOptions = (self.arrayEditorOptions);
	[self setUpArrayEditorOptions:arrayEditorOptions];
	
	(self.loading) = YES;
	(self.finishedLoading) = NO;
	[self runInBackground:^(GLAArrayEditorStore *store) {
		NSArray *loadedChildren = [store background_readModelsOfClass:(store.modelClass) atDictionaryKey:(store.JSONDictionaryKeyForArray) fromJSONFileURL:(store.JSONFileURL)];
		
		if (!loadedChildren) {
			loadedChildren = @[];
		}
		
		NSArray *processedChildren = [store background_processLoadedChildren:loadedChildren];
		
		[store runInForeground:^(GLAArrayEditorStore *store) {
			(store.arrayEditor) = [[GLAArrayEditor alloc] initWithObjects:processedChildren options:arrayEditorOptions];
			
			id<GLAArrayEditorStoreDelegate> delegate = (self.delegate);
			if ((delegate != nil) && [delegate respondsToSelector:@selector(arrayEditorStore:didLoadChildren:)]) {
				[delegate arrayEditorStore:self didLoadChildren:processedChildren];
			}
			
			(store.loading) = NO;
			(store.finishedLoading) = YES;
			
			if (completionBlock) {
				completionBlock();
			}
		}];
	}];
	
	return YES;
}

- (BOOL)saveWithCompletionBlock:(dispatch_block_t)completionBlock
{
	if ((self.loading) || (self.saving)) {
		return NO;
	}
	
	NSArray *array = [self copyChildren];
	
	(self.saving) = YES;
	(self.finishedSaving) = NO;
	
	[self runInBackground:^(GLAArrayEditorStore *store) {
		NSArray *JSONArray = [MTLJSONAdapter JSONArrayFromModels:array];
		NSString *JSONKey = (self.JSONDictionaryKeyForArray);
		
		NSDictionary *JSONDictionary =
		@{
		  JSONKey: JSONArray
		  };
		
		[store background_writeJSONDictionary:JSONDictionary toFileURL:(self.JSONFileURL)];
		
		[store runInForeground:^(GLAArrayEditorStore *store) {
			(self.saving) = NO;
			(self.finishedSaving) = YES;
			
			if (completionBlock) {
				completionBlock();
			}
		}];
	}];
	
	return YES;
}

@end


@implementation GLAArrayEditorStore (Errors)

+ (NSString *)errorDomain
{
	return @"GLAArrayEditorStore.errorDomain";
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
	
	return [NSError errorWithDomain:[self errorDomain] code:GLAArrayEditorStoreErrorCodeJSONMissingRequiredKey userInfo:errorInfo];
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
	
	return [NSError errorWithDomain:[self errorDomain] code:GLAArrayEditorStoreErrorCodeCannotMakeModelsFromJSONArray userInfo:errorInfo];
}

@end
