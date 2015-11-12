//
//  GLAArrayEditorUser.m
//  Blik
//
//  Created by Patrick Smith on 13/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAArrayEditorUser.h"


@interface GLAArrayEditorUser ()

@property(copy, nonatomic) GLAArrayEditorUserLoadingBlock sourceLoadingBlock;
@property(copy, nonatomic) GLAArrayEditorUserMakeEditsBlock sourceMakeEditsBlock;

@property(copy, nonatomic) dispatch_group_t loadingDispatchGroup;
@property(nonatomic) BOOL hasEnteredLoadingGroup;

//@property(copy, nonatomic) dispatch_group_t savingDispatchGroup;

@end

@implementation GLAArrayEditorUser

@synthesize representedObject = _representedObject;
@synthesize changeCompletionBlock = _changeCompletionBlock;

- (instancetype)initWithLoadingBlock:(GLAArrayEditorUserLoadingBlock)loadingBlock makeEditsBlock:(GLAArrayEditorUserMakeEditsBlock)makeEditsBlock
{
	self = [super init];
	if (self) {
		_sourceLoadingBlock = [loadingBlock copy];
		_sourceMakeEditsBlock = [makeEditsBlock copy];
		
		_loadingDispatchGroup = dispatch_group_create();
		dispatch_group_enter(_loadingDispatchGroup);
		_hasEnteredLoadingGroup = YES;
		
		_foregroundQueue = dispatch_get_main_queue();
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}

- (void)makeObserverOfObject:(id)notifier forChangeNotificationWithName:(NSString *)changeNotificationName
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(didChangeNotification:) name:changeNotificationName object:notifier];
}

- (GLAArrayEditor *)arrayEditorCreatingAndLoadingIfNeeded:(BOOL)createAndLoadIfNeeded
{
	return (self.sourceLoadingBlock)(createAndLoadIfNeeded);
}

- (BOOL)finishedLoading
{
	GLAArrayEditor *arrayEditor = [self arrayEditorCreatingAndLoadingIfNeeded:NO];
	if (!arrayEditor) {
		return NO;
	}
	
	return (arrayEditor.finishedLoadingFromStore);
}

- (GLAArrayEditor *)loadArrayEditor
{
	if (! (self.dependenciesAreFulfilled) ) {
		return nil;
	}
	
	GLAArrayEditor *arrayEditor = [self arrayEditorCreatingAndLoadingIfNeeded:YES];
	if (! arrayEditor.finishedLoadingFromStore ) {
		return nil;
	}
	
	if (_hasEnteredLoadingGroup) {
		dispatch_group_leave(_loadingDispatchGroup);
		_hasEnteredLoadingGroup = NO;
	}
	
	return arrayEditor;
}

- (NSArray * _Nullable)copyChildrenLoadingIfNeeded
{
	GLAArrayEditor *arrayEditor = [self loadArrayEditor];
	if (!arrayEditor) {
		return nil;
	}
	
	return [arrayEditor copyChildren];
}

- (id<GLAArrayInspecting> _Nullable)inspectLoadingIfNeeded
{
	GLAArrayEditor *arrayEditor = [self loadArrayEditor];
	if (!arrayEditor) {
		return nil;
	}
	
	return arrayEditor;
}

- (void)whenLoaded:(void (^)(id<GLAArrayInspecting>))block
{
	[self inspectLoadingIfNeeded];
	dispatch_group_notify(_loadingDispatchGroup, (self.foregroundQueue), ^{
		block([self loadArrayEditor]);
	});
}

- (void)editChildrenUsingBlock:(void (^)(id<GLAArrayEditing>))block
{
	GLAArrayEditor *arrayEditor = [self arrayEditorCreatingAndLoadingIfNeeded:NO];
	NSAssert(arrayEditor != nil && (arrayEditor.finishedLoadingFromStore), @"Array editor must be loaded before editing");
	
	dispatch_async((self.foregroundQueue), ^{
		(self.sourceMakeEditsBlock)(block);
	});
}

- (void)didChangeNotification:(NSNotification *)note
{
	GLAArrayInspectingBlock changeCompletionBlock = (self.changeCompletionBlock);
	if (changeCompletionBlock) {
		GLAArrayEditor *arrayEditor = [self arrayEditorCreatingAndLoadingIfNeeded:YES];
		changeCompletionBlock(arrayEditor);
	}
	
	if (_hasEnteredLoadingGroup) {
		dispatch_group_leave(_loadingDispatchGroup);
		_hasEnteredLoadingGroup = NO;
	}
}

- (BOOL)dependenciesAreFulfilled
{
	GLAArrayEditorUserBooleanResultBlock dependenciesAreFulfilledBlock = (self.dependenciesAreFulfilledBlock);
	if (dependenciesAreFulfilledBlock == nil) {
		return YES;
	}
	else {
		return dependenciesAreFulfilledBlock();
	}
}

- (void)makeObserverOfObject:(id)notifier forDependencyFulfilledNotificationWithName:(NSString *)dependencyFulfilledNotificationName
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(dependencyFulfilledNotification:) name:dependencyFulfilledNotificationName object:notifier];
}

- (void)dependencyFulfilledNotification:(NSNotification *)note
{
	if ((self.dependenciesAreFulfilled)) {
		[self inspectLoadingIfNeeded];
	}
}

@end
