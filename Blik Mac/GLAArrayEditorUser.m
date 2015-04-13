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
	GLAArrayEditor *arrayEditor = [self arrayEditorCreatingAndLoadingIfNeeded:NO];
	NSAssert(arrayEditor != nil && (arrayEditor.finishedLoadingFromStore), @"Array editor must be loaded before editing");
	
	(self.sourceMakeEditsBlock)(block);
}

- (void)didChangeNotification:(NSNotification *)note
{
#if DEBUG
	NSLog(@"didChangeNotification");
#endif
	GLAArrayInspectingBlock changeCompletionBlock = (self.changeCompletionBlock);
	if (changeCompletionBlock) {
		GLAArrayEditor *arrayEditor = [self arrayEditorCreatingAndLoadingIfNeeded:YES];
		changeCompletionBlock(arrayEditor);
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
#if DEBUG
	NSLog(@"dependencyFulfilledNotification %@", @(self.dependenciesAreFulfilled));
#endif
	if ((self.dependenciesAreFulfilled)) {
		[self inspectLoadingIfNeeded];
	}
}

@end
