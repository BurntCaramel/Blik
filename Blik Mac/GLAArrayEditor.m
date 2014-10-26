//
//  GLAArrayEditor.m
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAArrayEditor.h"

// API partially inspired by PHCollectionListChangeRequest


@interface GLAArrayEditorChanges ()

@property(nonatomic) NSMutableArray *mutableAddedChildren;
@property(nonatomic) NSMutableArray *mutableRemovedChildren;
@property(nonatomic) NSMutableArray *mutableReplacedChildrenBefore;
@property(nonatomic) NSMutableArray *mutableReplacedChildrenAfter;

@end


@interface GLAArrayEditor ()

@property(nonatomic) NSMutableArray *mutableChildren;

@property(nonatomic) GLAArrayEditorChanges *currentChanges;

@end

@implementation GLAArrayEditor

- (instancetype)initWithObjects:(NSArray *)objects
{
    self = [super init];
    if (self) {
        _mutableChildren = [NSMutableArray arrayWithArray:objects];
    }
    return self;
}

- (instancetype)init
{
	return [self initWithObjects:@[]];
}

- (NSArray *)childrenAtIndexes:(NSIndexSet *)indexes
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	return [mutableChildren objectsAtIndexes:indexes];
}

- (NSArray *)copyChildren
{
	return [(self.mutableChildren) copy];
}

- (GLAArrayEditorChanges *)changesMadeInBlock:(void (^)(id<GLAArrayEditing> arrayEditor))editorBlock
{
	GLAArrayEditorChanges *changes = [GLAArrayEditorChanges new];
	(self.currentChanges) = changes;
	
	editorBlock(self);
	
	(self.currentChanges) = nil;
	
	return changes;
}

- (void)addChildren:(NSArray *)objects
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	[mutableChildren addObjectsFromArray:objects];
	
	GLAArrayEditorChanges *changes = (self.currentChanges);
	if (changes) {
		[(changes.mutableAddedChildren) addObjectsFromArray:objects];
	}
}

- (void)insertChildren:(NSArray *)objects atIndexes:(NSIndexSet *)indexes
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	[mutableChildren insertObjects:objects atIndexes:indexes];
	
	GLAArrayEditorChanges *changes = (self.currentChanges);
	if (changes) {
		[(changes.mutableAddedChildren) addObjectsFromArray:objects];
	}
}

- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	
	GLAArrayEditorChanges *changes = (self.currentChanges);
	if (changes) {
		NSArray *removedChildren = [mutableChildren objectsAtIndexes:indexes];
		[(changes.mutableRemovedChildren) addObjectsFromArray:removedChildren];
	}
	
	[mutableChildren removeObjectsAtIndexes:indexes];
}

- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	
	GLAArrayEditorChanges *changes = (self.currentChanges);
	if (changes) {
		NSArray *originalChildren = [mutableChildren objectsAtIndexes:indexes];
		[(changes.mutableReplacedChildrenBefore) addObjectsFromArray:originalChildren];
		[(changes.mutableReplacedChildrenAfter) addObjectsFromArray:objects];
	}
	
	[mutableChildren replaceObjectsAtIndexes:indexes withObjects:objects];
}

- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)toIndex
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	NSArray *objectsToMove = [mutableChildren objectsAtIndexes:indexes];
	[mutableChildren removeObjectsAtIndexes:indexes];
	[mutableChildren insertObjects:objectsToMove atIndexes:[NSIndexSet indexSetWithIndex:toIndex]];
}


- (NSIndexSet *)indexesOfChildrenWhoseKey:(NSString *)key isEqualToValue:(id)value
{
	return [(self.mutableChildren) indexesOfObjectsPassingTest:^BOOL(id originalObject, NSUInteger idx, BOOL *stop) {
		id objectValue = [originalObject valueForKey:key];
		BOOL found = (objectValue != nil) && [objectValue isEqual:value];
		return found;
	}];
}

- (BOOL)replaceFirstChildWhoseKey:(NSString *)key isEqualToValue:(id)value withTransformer:(id (^)(id originalObject))objectTransformer
{
	NSIndexSet *indexes = [self indexesOfChildrenWhoseKey:key isEqualToValue:value];
	
	if (indexes.count == 0) {
		return NO;
	}
	
	indexes = [NSIndexSet indexSetWithIndex:(indexes.firstIndex)];
	
	NSArray *originalObject = [self childrenAtIndexes:indexes][0];
	id replacementObject = objectTransformer(originalObject);
	[self replaceChildrenAtIndexes:indexes withObjects:@[replacementObject]];
	
	return YES;
}

@end


@implementation GLAArrayEditorChanges

- (instancetype)init
{
	self = [super init];
	if (self) {
		_mutableAddedChildren = [NSMutableArray new];
		_mutableRemovedChildren = [NSMutableArray new];
		_mutableReplacedChildrenBefore = [NSMutableArray new];
		_mutableReplacedChildrenAfter = [NSMutableArray new];
	}
	return self;
}

- (NSArray *)addedChildren
{
	return _mutableAddedChildren;
}

- (NSArray *)removeChildren
{
	return _mutableRemovedChildren;
}

- (NSArray *)replacedChildrenBefore
{
	return _mutableReplacedChildrenBefore;
}

- (NSArray *)replacedChildrenAfter
{
	return _mutableReplacedChildrenAfter;
}

@end
