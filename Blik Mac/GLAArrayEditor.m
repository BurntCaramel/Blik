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

- (void)notifyObserversArrayWasCreated;
- (void)notifyObserversDidMakeChanges:(GLAArrayEditorChanges *)changes;

- (NSArray *)useConstrainersToFilterPotentialChildren:(NSArray *)potentialChildren;

@end

@implementation GLAArrayEditor

- (instancetype)initWithObjects:(NSArray *)objects options:(GLAArrayEditorOptions *)options
{
	self = [super init];
	if (self) {
		_mutableChildren = [NSMutableArray arrayWithArray:objects];
		
		if (options) {
			_observers = [(options.observers) copy];
			_constrainers = [(options.constrainers) copy];
		}
		else {
			_observers = @[];
			_constrainers = @[];
		}
		
		[self notifyObserversArrayWasCreated];
	}
	return self;
}

- (instancetype)init
{
	return [self initWithObjects:@[] options:nil];
}

#pragma mark Observers

- (void)notifyObserversArrayWasCreated
{
	for (id<GLAArrayObserving> observer in (self.observers)) {
		[observer arrayWasCreated:self];
	}
}

- (void)notifyObserversDidMakeChanges:(GLAArrayEditorChanges *)changes
{
	for (id<GLAArrayObserving> observer in (self.observers)) {
		[observer array:self didMakeChanges:changes];
	}
}

#pragma mark -

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
	
	[self notifyObserversDidMakeChanges:changes];
	
	(self.currentChanges) = nil;
	
	return changes;
}

#pragma mark Constrainers

- (NSArray *)useConstrainersToFilterPotentialChildren:(NSArray *)potentialChildren
{
	for (id<GLAArrayConstraining> constrainer in (self.constrainers)) {
		potentialChildren = [constrainer array:self filterPotentialChildren:potentialChildren];
	}
	
	return potentialChildren;
}

#pragma mark - <GLAArrayEditing>

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


- (NSIndexSet *)indexesOfChildrenWhoseResultFromVisitor:(id (^)(id child))childVisitor hasValueContainedInSet:(NSSet *)valuesSet
{
	return [(self.mutableChildren) indexesOfObjectsPassingTest:^BOOL(id child, NSUInteger idx, BOOL *stop) {
		id objectValue = childVisitor(child);
		BOOL found = (objectValue != nil) && [valuesSet containsObject:objectValue];
		return found;
	}];
}

- (NSIndexSet *)indexesOfChildrenWhoseKey:(NSString *)keyPath hasValue:(id)value
{
	return [(self.mutableChildren) indexesOfObjectsPassingTest:^BOOL(id originalObject, NSUInteger idx, BOOL *stop) {
		id objectValue = [originalObject valueForKey:keyPath];
		BOOL found = (objectValue != nil) && [objectValue isEqual:value];
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

- (id)replaceFirstChildWhoseKeyPath:(NSString *)keyPath hasValue:(id)value usingChangeBlock:(id (^)(id originalObject))objectChanger
{
	NSIndexSet *indexes = [self indexesOfChildrenWhoseKey:keyPath hasValue:value];
	
	if (indexes.count == 0) {
		return nil;
	}
	
	indexes = [NSIndexSet indexSetWithIndex:(indexes.firstIndex)];
	NSArray *originalObject = [self childrenAtIndexes:indexes][0];
	
	id replacementObject = objectChanger(originalObject);
	[self replaceChildrenAtIndexes:indexes withObjects:@[replacementObject]];
	
	return replacementObject;
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

// These are only accessed after all changes have been made.
// So immutable copies are not necessary.

- (NSArray *)addedChildren
{
	return _mutableAddedChildren;
}

- (NSArray *)removedChildren
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

- (NSString *)description
{
	return [NSString stringWithFormat:@"[%@ %p; ADDED: %@ REMOVED: %@ REPLACED: %@ WITH: %@]", (self.className), self, (self.addedChildren), (self.removedChildren), (self.replacedChildrenBefore), (self.replacedChildrenAfter)];
}

@end


@interface GLAArrayEditorOptions ()

@property(nonatomic) NSMutableArray *mutableObservers;
@property(nonatomic) NSMutableArray *mutableConstrainers;

@end

@implementation GLAArrayEditorOptions

- (instancetype)init
{
	self = [super init];
	if (self) {
		_mutableObservers = [NSMutableArray new];
		_mutableConstrainers = [NSMutableArray new];
	}
	return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
	GLAArrayEditorOptions *copy = [[[self class] allocWithZone:zone] init];
	(copy.mutableObservers) = [(self.mutableObservers) mutableCopy];
	(copy.mutableConstrainers) = [(self.mutableConstrainers) mutableCopy];
	
	return copy;
}

- (void)addObserver:(id<GLAArrayObserving>)observer
{
	NSMutableArray *mutableObservers = (self.mutableObservers);
	[mutableObservers addObject:observer];
}

- (void)addConstrainer:(id<GLAArrayConstraining>)constrainer
{
	NSMutableArray *mutableConstrainers = (self.mutableConstrainers);
	[mutableConstrainers addObject:constrainer];
	
	NSMutableArray *mutableObservers = (self.mutableObservers);
	if ([mutableObservers indexOfObjectIdenticalTo:constrainer] == NSNotFound) {
		[mutableObservers addObject:constrainer];
	}
}

- (NSArray *)observers
{
	return [(self.mutableObservers) copy];
}

- (NSArray *)constrainers
{
	return [(self.mutableConstrainers) copy];
}

@end
