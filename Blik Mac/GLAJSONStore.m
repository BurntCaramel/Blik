//
//  GLAJSONStore.m
//  Blik
//
//  Created by Patrick Smith on 17/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAJSONStore.h"
#import "PGWSQueuedBlockConvenience.h"


@interface GLAJSONStore ()

@property(nonatomic) dispatch_queue_t inputDispatchQueue;

@end

@implementation GLAJSONStore

- (instancetype)initWithFileURL:(NSURL *)fileURL backgroundOperationQueue:(NSOperationQueue *)operationQueue freshlyMade:(BOOL)freshlyMade
{
	self = [super init];
	if (self) {
		_fileURL = fileURL;
		_backgroundOperationQueue = operationQueue;
		
		_inputDispatchQueue = dispatch_queue_create("com.burntcaramel.GLAJSONStore.input", DISPATCH_QUEUE_SERIAL);
		
		_saveState = GLAStoringSaveStateNeedsSaving;
		_freshlyMade = freshlyMade;
		
		if (freshlyMade) {
			_loadState = GLAStoringLoadStateFinishedLoading;
		}
		else {
			_loadState = GLAStoringLoadStateNeedsLoading;
		}
	}
	return self;
}

- (instancetype)init __unavailable
{
	return nil;
}

@synthesize loadState = _loadState;

- (GLAStoringLoadState)loadState
{
	__block GLAStoringLoadState loadState;
	dispatch_sync((self.inputDispatchQueue), ^{
		loadState = self->_loadState;
	});
	
	return loadState;
}

- (void)setLoadState:(GLAStoringLoadState)loadState
{
	[self pgws_useReceiverAsyncOnDispatchQueue:(self.inputDispatchQueue) block:^(GLAJSONStore *self) {
		self->_loadState = loadState;
	}];
}

@synthesize saveState = _saveState;

- (GLAStoringSaveState)saveState
{
	__block GLAStoringSaveState saveState;
	dispatch_sync((self.inputDispatchQueue), ^{
		saveState = self->_saveState;
	});
	
	return saveState;
}

- (void)setSaveState:(GLAStoringSaveState)saveState
{
	[self pgws_useReceiverAsyncOnDispatchQueue:(self.inputDispatchQueue) block:^(GLAJSONStore *self) {
		self->_saveState = saveState;
	}];
}

@synthesize representedObject = _representedObject;

- (id)representedObject
{
	__block id representedObject;
	dispatch_sync((self.inputDispatchQueue), ^{
		representedObject = self->_representedObject;
	});
	
	return representedObject;
}

- (void)setRepresentedObject:(id)representedObject
{
	[self pgws_useReceiverAsyncOnDispatchQueue:(self.inputDispatchQueue) block:^(GLAJSONStore *self) {
		self->_representedObject = representedObject;
	}];
}

#pragma mark Loading

- (BOOL)loadIfNeeded
{
	GLAStoringLoadState loadState = (self.loadState);
	if (loadState != GLAStoringLoadStateNeedsLoading) {
		return NO;
	}
	
	(self.loadState) = GLAStoringLoadStateCurrentlyLoading;
	
	NSURL *fileURL = (self.fileURL);
	GLAJSONStoreLoadCompletionBlock loadCompletionBlock = (self.loadCompletionBlock);
	
	[(self.backgroundOperationQueue) pgws_useObject:self inAddedOperationBlock:^(GLAJSONStore *self) {
		[self background_readJSONDictionaryFromFileURL:fileURL completionBlock:loadCompletionBlock];
		
		(self.loadState) = GLAStoringLoadStateFinishedLoading;
	}];
	
	return YES;
}

- (void)background_readJSONDictionaryFromFileURL:(NSURL *)fileURL completionBlock:(GLAJSONStoreLoadCompletionBlock)block
{
	NSError *error = nil;
	
	NSData *JSONData = [NSData dataWithContentsOfURL:fileURL options:0 error:&error];
	if (!JSONData) {
		block(nil, error);
	}
	
	NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
	if (!JSONDictionary) {
		block(nil, error);
	}
	
	block(JSONDictionary, nil);
}

#pragma mark Saving

- (void)saveJSONDictionary:(NSDictionary *)dictionary
{
#if DEBUG
	NSLog(@"SAVING JSON DICTIONARY %@", dictionary);
#endif
	
	GLAStoringSaveState saveState = (self.saveState);
	if (saveState != GLAStoringSaveStateNeedsSaving) {
#if DEBUG
		NSLog(@"NO NEED TO SAVE");
#endif
		return;
	}
	
#if DEBUG
	NSLog(@"NEEDS TO SAVE %@", (self.backgroundOperationQueue));
#endif
	
	(self.saveState) = GLAStoringSaveStateCurrentlySaving;
	
	NSURL *fileURL = (self.fileURL);
	GLAJSONStoreSaveCompletionBlock saveCompletionBlock = (self.saveCompletionBlock);
	
	[(self.backgroundOperationQueue) pgws_useObject:self inAddedOperationBlock:^(GLAJSONStore *self) {
#if DEBUG
		NSLog(@"WRITING JSON DICTIONARY");
#endif
		[self background_writeJSONDictionary:dictionary toFileURL:fileURL completionBlock:saveCompletionBlock];
		
		(self.saveState) = GLAStoringSaveStateFinishedSaving;
	}];
}

- (void)background_writeJSONDictionary:(NSDictionary *)JSONDictionary toFileURL:(NSURL *)fileURL completionBlock:(GLAJSONStoreSaveCompletionBlock)block
{
	NSError *error = nil;
	
	NSData *JSONData = nil;
	@try {
		JSONData = [NSJSONSerialization dataWithJSONObject:JSONDictionary options:0 error:&error];
		if (!JSONData) {
#if DEBUG
			NSLog(@"ERROR %@ SAVING JSON to %@", error, fileURL);
#endif
			if (block) {
				block(NO, error);
			}
		}
		
#if DEBUG
		NSLog(@"SAVED JSON DATA %@ to %@", @(JSONData.length), fileURL);
#endif
	}
	@catch (NSException *e) {
		NSLog(@"EXCEPTION converting to JSON %@", JSONDictionary);
		@throw e;
	}
	
	[JSONData writeToURL:fileURL atomically:YES];
	
	if (block) {
		block(YES, nil);
	}
}

@end
