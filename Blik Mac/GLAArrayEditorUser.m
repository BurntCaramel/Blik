//
//  GLAArrayEditorUser.m
//  Blik
//
//  Created by Patrick Smith on 13/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAArrayEditorUser.h"


@interface GLAArrayEditorUser ()

@property(nonatomic) id owner;

@property(copy, nonatomic) GLAArrayEditorUserAccessingBlock sourceAccessingBlock;
@property(copy, nonatomic) GLAArrayEditorUserEditBlock sourceEditBlock;

- (void)didLoadNotification:(NSNotification *)note;

@end

@implementation GLAArrayEditorUser

@synthesize representedObject = _representedObject;
@synthesize changeCompletionBlock = _changeCompletionBlock;

- (instancetype)initWithOwner:(id)owner accessingBlock:(GLAArrayEditorUserAccessingBlock)accessingBlock editBlock:(GLAArrayEditorUserEditBlock)editBlock
{
	self = [super init];
	if (self) {
		_owner = owner;
		_sourceAccessingBlock = [accessingBlock copy];
		_sourceEditBlock = [editBlock copy];
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

- (GLAArrayEditor *)arrayEditorCreatingIfNeeded:(BOOL)createIfNeeded LoadingIfNeeded:(BOOL)loadIfNeeded
{
	return (self.sourceAccessingBlock)(createIfNeeded, loadIfNeeded);
}

- (BOOL)finishedLoading
{
	GLAArrayEditor *arrayEditor = [self arrayEditorCreatingIfNeeded:NO LoadingIfNeeded:NO];
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
	
	GLAArrayEditor *arrayEditor = [self arrayEditorCreatingIfNeeded:YES LoadingIfNeeded:YES];
	if (! arrayEditor.finishedLoadingFromStore ) {
		return nil;
	}
	
	return arrayEditor;
}

- (NSArray *)copyChildrenLoadingIfNeeded
{
	GLAArrayEditor *arrayEditor = [self loadArrayEditor];
	if (!arrayEditor) {
		return nil;
	}
	
	return [arrayEditor copyChildren];
}

- (id<GLAArrayInspecting>)inspectLoadingIfNeeded
{
	GLAArrayEditor *arrayEditor = [self loadArrayEditor];
	if (!arrayEditor) {
		return nil;
	}
	
	return arrayEditor;
}

- (void)editChildrenUsingBlock:(void (^)(id<GLAArrayEditing>))block
{
	GLAArrayEditor *arrayEditor = [self arrayEditorCreatingIfNeeded:NO LoadingIfNeeded:NO];
	NSAssert(arrayEditor != nil && (arrayEditor.finishedLoadingFromStore), @"Array editor must be loaded before editing");
	
	(self.sourceEditBlock)(block);
}

- (void)didLoadNotification:(NSNotification *)note
{
	//(self.loadCompletionBlock)();
}

- (void)didChangeNotification:(NSNotification *)note
{
	GLAArrayInspectingBlock changeCompletionBlock = (self.changeCompletionBlock);
	if (changeCompletionBlock) {
		GLAArrayEditor *arrayEditor = [self arrayEditorCreatingIfNeeded:YES LoadingIfNeeded:YES];
		changeCompletionBlock(arrayEditor);
	}
}

- (BOOL)dependenciesAreFulfilled
{
	GLAArrayEditorUserBooleanResultBlock dependenciesAreFulfilledBlock = (self.dependenciesAreFulfilledBlock);
	if (!dependenciesAreFulfilledBlock) {
		return YES;
	}
	
	return dependenciesAreFulfilledBlock();
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
