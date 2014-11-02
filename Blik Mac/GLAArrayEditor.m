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

- (void)includeAddedChildren:(NSArray *)addedChildren;
- (void)includeRemovedChildren:(NSArray *)removedChildren;
- (void)includeReplacedChildrenFrom:(NSArray *)originalChildren to:(NSArray *)replacementChildren;

@property(readwrite, nonatomic) BOOL hasChanges;
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
		[changes includeAddedChildren:objects];
	}
}

- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	
	GLAArrayEditorChanges *changes = (self.currentChanges);
	if (changes) {
		NSArray *removedChildren = [mutableChildren objectsAtIndexes:indexes];
		[changes includeRemovedChildren:removedChildren];
	}
	
	[mutableChildren removeObjectsAtIndexes:indexes];
}

- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	
	GLAArrayEditorChanges *changes = (self.currentChanges);
	if (changes) {
		NSArray *originalChildren = [mutableChildren objectsAtIndexes:indexes];
		[changes includeReplacedChildrenFrom:originalChildren to:objects];
	}
	
	[mutableChildren replaceObjectsAtIndexes:indexes withObjects:objects];
}

- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)toIndex
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	NSArray *objectsToMove = [mutableChildren objectsAtIndexes:indexes];
	[mutableChildren removeObjectsAtIndexes:indexes];
	[mutableChildren insertObjects:objectsToMove atIndexes:[NSIndexSet indexSetWithIndex:toIndex]];
	
	// No changes tracked, as objects are moved not actually added or removed.
}


- (NSIndexSet *)indexesOfChildrenWhoseKeyPath:(NSString *)keyPath hasValue:(id)value
{
	return [(self.mutableChildren) indexesOfObjectsPassingTest:^BOOL(id originalObject, NSUInteger idx, BOOL *stop) {
		id objectValue = [originalObject valueForKeyPath:keyPath];
		BOOL found = (objectValue != nil) && [objectValue isEqual:value];
		return found;
	}];
}

- (NSIndexSet *)indexesOfChildrenWhoseKeyPath:(NSString *)keyPath hasValueContainedInSet:(NSSet *)valuesSet
{
	return [(self.mutableChildren) indexesOfObjectsPassingTest:^BOOL(id originalObject, NSUInteger idx, BOOL *stop) {
		id objectValue = [originalObject valueForKeyPath:keyPath];
		BOOL found = (objectValue != nil) && [valuesSet containsObject:objectValue];
		return found;
	}];
}

- (NSArray *)filterArray:(NSArray *)objects whoseValuesIsNotPresentForKeyPath:(NSString *)keyPath
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	// Make a set of the childrens' property.
	NSSet *objectPropertyValues = [NSSet setWithArray:[mutableChildren valueForKeyPath:keyPath]];
	//
	NSIndexSet *indexes = [objects indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		id objectValue = [obj valueForKeyPath:keyPath];
		// We want the objects that aren't present.
		BOOL found = [objectPropertyValues containsObject:objectValue];
		return !found;
	}];
	return [objects objectsAtIndexes:indexes];
}

- (BOOL)replaceFirstChildWhoseKeyPath:(NSString *)keyPath hasValue:(id)value usingChangeBlock:(id (^)(id originalObject))objectChanger
{
	NSIndexSet *indexes = [self indexesOfChildrenWhoseKeyPath:keyPath hasValue:value];
	
	if (indexes.count == 0) {
		return NO;
	}
	
	indexes = [NSIndexSet indexSetWithIndex:(indexes.firstIndex)];
	NSArray *originalObject = [self childrenAtIndexes:indexes][0];
	
	id replacementObject = objectChanger(originalObject);
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

- (void)includeAddedChildren:(NSArray *)addedChildren
{
	[_mutableAddedChildren addObjectsFromArray:addedChildren];
	
	(self.hasChanges) = YES;
}

- (void)includeRemovedChildren:(NSArray *)removedChildren
{
	[_mutableRemovedChildren addObjectsFromArray:removedChildren];
	
	(self.hasChanges) = YES;
}

- (void)includeReplacedChildrenFrom:(NSArray *)originalChildren to:(NSArray *)replacementChildren
{
	[_mutableReplacedChildrenBefore addObjectsFromArray:originalChildren];
	[_mutableReplacedChildrenAfter addObjectsFromArray:replacementChildren];
	
	(self.hasChanges) = YES;
}

- (NSArray *)addedChildren
{
	return [_mutableAddedChildren copy];
}

- (NSArray *)removeChildren
{
	return [_mutableRemovedChildren copy];
}

- (NSArray *)replacedChildrenBefore
{
	return [_mutableReplacedChildrenBefore copy];
}

- (NSArray *)replacedChildrenAfter
{
	return [_mutableReplacedChildrenAfter copy];
}

@end
