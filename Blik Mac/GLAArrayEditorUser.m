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
- (void)didChangeNotification:(NSNotification *)note;

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

- (void)makeObserverOfObject:(id)notifier forLoadNotificationWithName:(NSString *)loadNotificationName changeNotificationWithName:(NSString *)changeNotificationName
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	if (loadNotificationName) {
		[nc addObserver:self selector:@selector(didLoadNotification:) name:loadNotificationName object:notifier];
	}
	
	if (changeNotificationName) {
		[nc addObserver:self selector:@selector(didChangeNotification:) name:changeNotificationName object:notifier];
	}
}

- (void)makeObserverOfOwnerForLoadNotificationWithName:(NSString *)loadNotificationName changeNotificationWithName:(NSString *)changeNotificationName
{
	id owner = (self.owner);
	[self makeObserverOfObject:owner forLoadNotificationWithName:loadNotificationName changeNotificationWithName:changeNotificationName];
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

- (NSArray *)copyChildrenLoadingIfNeeded
{
	GLAArrayEditor *arrayEditor = [self arrayEditorCreatingIfNeeded:YES LoadingIfNeeded:YES];
	if (!arrayEditor.finishedLoadingFromStore) {
		return nil;
	}
	
	return [arrayEditor copyChildren];
}

- (id<GLAArrayInspecting>)inspectLoadingIfNeeded
{
	GLAArrayEditor *arrayEditor = [self arrayEditorCreatingIfNeeded:YES LoadingIfNeeded:YES];
	if (!arrayEditor.finishedLoadingFromStore) {
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
	GLAArrayEditor *arrayEditor = [self arrayEditorCreatingIfNeeded:YES LoadingIfNeeded:YES];
	(self.changeCompletionBlock)(arrayEditor);
}

@end
