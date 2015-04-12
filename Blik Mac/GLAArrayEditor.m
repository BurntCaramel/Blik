//
//  GLAArrayEditor.m
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAArrayEditor.h"

// API partially inspired by PHCollectionListChangeRequest


@interface GLAArrayEditorOptions ()

@property(readonly, nonatomic) id<GLAArrayStoring> store;

@property(readonly, nonatomic) id<GLAArrayEditorIndexing> primaryIndexer;

@property(readonly, copy, nonatomic) NSArray *observers;
@property(readonly, copy, nonatomic) NSArray *indexers;
@property(readonly, copy, nonatomic) NSArray *constrainers;

@property(nonatomic) NSMutableArray *mutableObservers;
@property(nonatomic) NSMutableArray *mutableIndexers;
@property(nonatomic) NSMutableArray *mutableConstrainers;

@end


@interface GLAArrayEditorChanges ()

- (void)includeAddedChildren:(NSArray *)addedChildren;
- (void)includeRemovedChildren:(NSArray *)removedChildren;
- (void)includeReplacedChildrenFrom:(NSArray *)originalChildren to:(NSArray *)replacementChildren;
- (void)includeMovedChildrenFromIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)toIndex;

@property(readwrite, nonatomic) BOOL hasChanges;
@property(nonatomic) NSMutableArray *mutableAddedChildren;
@property(nonatomic) NSMutableArray *mutableRemovedChildren;
@property(nonatomic) NSMutableArray *mutableReplacedChildrenBefore;
@property(nonatomic) NSMutableArray *mutableReplacedChildrenAfter;

@end


@interface GLAArrayEditor (GLAArrayEditing) <GLAArrayEditing>

@end


@interface GLAArrayEditor ()

@property(nonatomic) NSMutableArray *mutableChildren;

//TODO: change observers to weak relationship?
@property(readonly, copy, nonatomic) NSArray *observers;

@property(readonly, copy, nonatomic) NSArray *indexers;
@property(readonly, nonatomic) id<GLAArrayEditorIndexing> primaryIndexer;

@property(readonly, copy, nonatomic) NSArray *constrainers;

@property(nonatomic) GLAArrayEditorChanges *currentChanges;

- (void)notifyObserversArrayWasCreated;
- (void)notifyObserversDidLoad;
- (void)notifyObserversDidMakeChanges:(GLAArrayEditorChanges *)changes;

@end

@implementation GLAArrayEditor

- (instancetype)initWithObjects:(NSArray *)objects options:(GLAArrayEditorOptions *)options
{
	NSParameterAssert(objects != nil);
	
	self = [super init];
	if (self) {
		_mutableChildren = [NSMutableArray arrayWithArray:objects];
		
		if (options) {
			_observers = [(options.observers) copy];
			_indexers = [(options.indexers) copy];
			_primaryIndexer = (options.primaryIndexer);
			_constrainers = [(options.constrainers) copy];
			
			id<GLAArrayStoring> store = _store = (options.store);
			if (store && (store.loadState) != GLAArrayStoringLoadStateFinishedLoading) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeDidLoadNotification:) name:GLAArrayStoringDidLoadNotification object:store];
			}
			else {
				_readyForEditing = YES;
			}
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

#pragma mark - <GLAArrayInspecting>

- (NSArray *)copyChildren
{
	return [(self.mutableChildren) copy];
}

- (id)childAtIndex:(NSUInteger)index
{
	NSParameterAssert(index != NSNotFound);
	
	NSMutableArray *mutableChildren = (self.mutableChildren);
	return mutableChildren[index];
}

- (NSArray *)childrenAtIndexes:(NSIndexSet *)indexes
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	return [mutableChildren objectsAtIndexes:indexes];
}

- (NSUInteger)childrenCount
{
	return (self.mutableChildren.count);
}

- (NSArray *)resultsFromChildVisitor:(GLAArrayChildVisitorBlock)childVisitor
{
	NSParameterAssert(childVisitor != nil);
	
	NSMutableArray *results = [NSMutableArray new];
	NSMutableArray *mutableChildren = (self.mutableChildren);
	
	for (id child in mutableChildren) {
		id result = childVisitor(child);
		if (result) {
			[results addObject:result];
		}
	}
	
	return results;
}

- (id)firstChildWhoseKey:(NSString *)key hasValue:(id)value
{
#if 1
	NSArray *indexers = (self.indexers);
	if (indexers) {
		for (id<GLAArrayEditorIndexing> indexer in indexers) {
			id child = [indexer arrayEditor:self firstIndexedChildWhoseKey:key hasValue:value];
			if (child) {
				return child;
			}
		}
	}
#endif
	
	NSUInteger childIndex = [self indexOfFirstChildWhoseKey:key hasValue:value];
	if (childIndex != NSNotFound) {
		return [self childAtIndex:childIndex];
	}
	
	return nil;
}

- (NSUInteger)indexOfFirstChildWhoseKey:(NSString *)key hasValue:(id)value
{
	NSParameterAssert(key != nil);
	NSParameterAssert(value != nil);
	
	NSMutableArray *mutableChildren = (self.mutableChildren);
	
	NSUInteger i = 0;
	for (id child in mutableChildren) {
		id objectValue = [child valueForKey:key];
		BOOL found = (objectValue != nil) && [objectValue isEqual:value];
		if (found) {
			return i;
		}
		i++;
	}
	
	return NSNotFound;
}

- (NSIndexSet *)indexesOfChildrenWhoseResultFromVisitor:(id (^)(id child))childVisitor hasValueContainedInSet:(NSSet *)valuesSet
{
	NSParameterAssert(childVisitor != nil);
	NSParameterAssert(valuesSet != nil);
	
	return [(self.mutableChildren) indexesOfObjectsPassingTest:^BOOL(id child, NSUInteger idx, BOOL *stop) {
		id objectValue = childVisitor(child);
		BOOL found = (objectValue != nil) && [valuesSet containsObject:objectValue];
		return found;
	}];
}

- (NSArray *)filterArray:(NSArray *)objects whoseResultFromVisitorIsNotAlreadyPresent:(GLAArrayChildVisitorBlock)childVisitor
{
	NSParameterAssert(objects != nil);
	NSParameterAssert(childVisitor != nil);
	
	NSMutableArray *mutableChildren = (self.mutableChildren);
	
	NSMutableSet *childResults = [NSMutableSet new];
	for (id child in mutableChildren) {
		id childResult = childVisitor(child);
		if (childResult) {
			[childResults addObject:childResult];
		}
	}
	
	NSMutableArray *filteredObjects = [NSMutableArray new];
	for (id object in objects) {
		id objectResult = childVisitor(object);
		if (!objectResult) {
			continue;
		}
		
		if (![childResults containsObject:objectResult]) {
			[filteredObjects addObject:object];
		}
	}
	
	return filteredObjects;
}

#pragma mark -

- (id)objectForKeyedSubscript:(id <NSCopying>)key
{
	id<GLAArrayEditorIndexing> primaryIndexer = (self.primaryIndexer);
	if (primaryIndexer) {
		return primaryIndexer[key];
	}
	else {
		return nil;
	}
}

#pragma mark Observers

- (void)notifyObserversArrayWasCreated
{
	for (id<GLAArrayEditorObserving> observer in (self.observers)) {
		if ([observer respondsToSelector:@selector(arrayEditorWasCreated:)]) {
			[observer arrayEditorWasCreated:self];
		}
	}
}

- (void)notifyObserversDidLoad
{
	for (id<GLAArrayEditorObserving> observer in (self.observers)) {
		if ([observer respondsToSelector:@selector(arrayEditorDidLoad:)]) {
			[observer arrayEditorDidLoad:self];
		}
	}
}

- (void)notifyObserversDidMakeChanges:(GLAArrayEditorChanges *)changes
{
	for (id<GLAArrayEditorObserving> observer in (self.observers)) {
		if ([observer respondsToSelector:@selector(arrayEditor:didMakeChanges:)]) {
			[observer arrayEditor:self didMakeChanges:changes];
		}
	}
}

- (void)storeDidLoadNotification:(NSNotification *)note
{
	NSDictionary *info = (note.userInfo);
	NSArray *loadedChildren = info[GLAArrayStoringDidLoadNotificationUserInfoLoadedChildren];
	//TODO: decide whether this should be in a change block.
	// Currently isn't as observers will get different notifications
	// if this is called in change block.
	[self addChildren:loadedChildren];
	
	[self notifyObserversDidLoad];
	
	_readyForEditing = YES;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAArrayEditorWithStoreIsReadyForEditingNotification object:self];
}

#pragma mark -

- (GLAArrayEditorChanges *)changesMadeInBlock:(GLAArrayEditingBlock)editorBlock
{
	NSAssert((self.needsLoadingFromStore) ? (self.finishedLoadingFromStore) : YES, @"Array editor must have finished loading to make changes.");
	
	GLAArrayEditorChanges *changes = [GLAArrayEditorChanges new];
	(self.currentChanges) = changes;
	
	editorBlock(self);
	
	[self notifyObserversDidMakeChanges:changes];
	
	(self.currentChanges) = nil;
	
	return changes;
}

- (BOOL)needsLoadingFromStore
{
	id<GLAArrayStoring> store = (self.store);
	if (store) {
		return (store.loadState) == GLAArrayStoringLoadStateNeedsLoading;
	}
	else {
		return NO;
	}
}

- (BOOL)finishedLoadingFromStore
{
	id<GLAArrayStoring> store = (self.store);
	if (store) {
		return (store.loadState) == GLAArrayStoringLoadStateFinishedLoading;
	}
	else {
		return YES;
	}
}

- (NSArray *)constrainPotentialChildren:(NSArray *)potentialChildren
{
	for (id<GLAArrayEditorConstraining> constrainer in (self.constrainers)) {
		potentialChildren = [constrainer arrayEditor:self filterPotentialChildren:potentialChildren];
	}
	
	return potentialChildren;
}

@end


@implementation GLAArrayEditor (GLAArrayEditing)

- (void)addChildren:(NSArray *)objects
{
	NSParameterAssert(objects != nil);
	
	if ((objects.count) == 0) {
		return;
	}
	
	NSMutableArray *mutableChildren = (self.mutableChildren);
	[mutableChildren addObjectsFromArray:objects];
	
	GLAArrayEditorChanges *changes = (self.currentChanges);
	if (changes) {
		[changes includeAddedChildren:objects];
	}
}

- (void)insertChildren:(NSArray *)objects atIndexes:(NSIndexSet *)indexes
{
	NSParameterAssert(objects != nil);
	NSParameterAssert(indexes != nil);
	NSParameterAssert((indexes.count) == (objects.count));
	
	if ((objects.count) == 0) {
		return;
	}
	
	NSMutableArray *mutableChildren = (self.mutableChildren);
	[mutableChildren insertObjects:objects atIndexes:indexes];
	
	GLAArrayEditorChanges *changes = (self.currentChanges);
	if (changes) {
		[changes includeAddedChildren:objects];
	}
}

- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes
{
	NSParameterAssert(indexes != nil);
	
	if ((indexes.count) == 0) {
		return;
	}
	
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
	NSParameterAssert(indexes != nil);
	NSParameterAssert(objects != nil);
	NSParameterAssert((indexes.count) == (objects.count));
	
	if ((indexes.count) == 0) {
		return;
	}
	
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
	NSParameterAssert(indexes != nil);
	NSParameterAssert((indexes.count) > 0);
	NSParameterAssert(toIndex != NSNotFound);
	
	NSMutableArray *mutableChildren = (self.mutableChildren);
	
	GLAArrayEditorChanges *changes = (self.currentChanges);
	if (changes) {
		[changes includeMovedChildrenFromIndexes:indexes toIndex:toIndex];
	}
	
	NSArray *objectsToMove = [mutableChildren objectsAtIndexes:indexes];
	[mutableChildren removeObjectsAtIndexes:indexes];
	[mutableChildren insertObjects:objectsToMove atIndexes:[NSIndexSet indexSetWithIndex:toIndex]];
}

- (void)replaceAllChildrenWithObjects:(NSArray *)objects
{
	NSRange entireRange = NSMakeRange(0, (self.childrenCount));
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:entireRange];
	[self removeChildrenAtIndexes:indexes];
	[self addChildren:objects];
}

- (BOOL)removeFirstChildWhoseKey:(NSString *)key hasValue:(id)value
{
	NSUInteger index = [self indexOfFirstChildWhoseKey:key hasValue:value];
	if (index == NSNotFound) {
		return NO;
	}
	
	[self removeChildrenAtIndexes:[NSIndexSet indexSetWithIndex:index]];
	
	return YES;
}

- (id)replaceFirstChildWhoseKey:(NSString *)key hasValue:(id)value usingChangeBlock:(id (^)(id originalObject))objectChanger
{
	NSParameterAssert(key != nil);
	NSParameterAssert(value != nil);
	NSParameterAssert(objectChanger != nil);
	
	NSUInteger index = [self indexOfFirstChildWhoseKey:key hasValue:value];
	if (index == NSNotFound) {
		return NO;
	}
	
	id originalObject = [self childAtIndex:index];
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:index];
	
	id replacementObject = objectChanger(originalObject);
	[self replaceChildrenAtIndexes:indexes withObjects:@[replacementObject]];
	
	return replacementObject;
}

@end

NSString *GLAArrayEditorWithStoreIsReadyForEditingNotification = @"GLAArrayEditorWithStoreIsReadyForEditingNotification";


#pragma mark -


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
	
	_hasChanges = YES;
}

- (void)includeRemovedChildren:(NSArray *)removedChildren
{
	[_mutableRemovedChildren addObjectsFromArray:removedChildren];
	
	_hasChanges = YES;
}

- (void)includeReplacedChildrenFrom:(NSArray *)originalChildren to:(NSArray *)replacementChildren
{
	[_mutableReplacedChildrenBefore addObjectsFromArray:originalChildren];
	[_mutableReplacedChildrenAfter addObjectsFromArray:replacementChildren];
	
	_hasChanges = YES;
}

- (void)includeMovedChildrenFromIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)toIndex
{
	_didMoveChildren = YES;
	
	_hasChanges = YES;
}

#pragma mark -

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
	if (self.hasChanges) {
		return [NSString stringWithFormat:@"[%@ %p; ADDED: %@ REMOVED: %@ REPLACED: %@ WITH: %@]", (self.className), self, (self.addedChildren), (self.removedChildren), (self.replacedChildrenBefore), (self.replacedChildrenAfter)];
	}
	else {
		return [super description];
	}
}

@end


#pragma mark -


@implementation GLAArrayEditorOptions

- (instancetype)init
{
	self = [super init];
	if (self) {
		_mutableObservers = [NSMutableArray new];
		_mutableIndexers = [NSMutableArray new];
		_mutableConstrainers = [NSMutableArray new];
	}
	return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
	GLAArrayEditorOptions *copy = [[[self class] allocWithZone:zone] init];
	(copy.mutableObservers) = [(self.mutableObservers) mutableCopy];
	(copy.mutableIndexers) = [(self.mutableIndexers) mutableCopy];
	(copy.mutableConstrainers) = [(self.mutableConstrainers) mutableCopy];
	(copy.store) = (self.store);
	
	return copy;
}

- (void)addObserver:(id<GLAArrayEditorObserving>)observer
{
	NSParameterAssert(observer != nil);
	
	NSMutableArray *mutableObservers = (self.mutableObservers);
	if ([mutableObservers indexOfObjectIdenticalTo:observer] == NSNotFound) {
		[mutableObservers addObject:observer];
	}
}

- (void)addIndexer:(id<GLAArrayEditorIndexing>)indexer
{
	NSParameterAssert(indexer != nil);
	
	NSMutableArray *mutableIndexers = (self.mutableIndexers);
	[mutableIndexers addObject:indexer];
	
	[self addObserver:indexer];
}

- (void)setPrimaryIndexer:(id<GLAArrayEditorIndexing>)indexer
{
	NSAssert(_primaryIndexer == nil, @"Store can only be set once.");
	
	_primaryIndexer = indexer;
	
	[self addIndexer:indexer];
}

- (void)addConstrainer:(id<GLAArrayEditorConstraining>)constrainer
{
	NSParameterAssert(constrainer != nil);
	
	NSMutableArray *mutableConstrainers = (self.mutableConstrainers);
	[mutableConstrainers addObject:constrainer];
	
	[self addObserver:constrainer];
}

@synthesize store = _store;

- (void)setStore:(id<GLAArrayStoring>)store
{
	NSAssert(_store == nil, @"Store can only be set once.");
	
	_store = store;
	if (store) {
		[self addObserver:store];
	}
}

- (NSArray *)observers
{
	return [(self.mutableObservers) copy];
}

- (NSArray *)indexers
{
	return [(self.mutableIndexers) copy];
}

- (NSArray *)constrainers
{
	return [(self.mutableConstrainers) copy];
}

@end

NSString *GLAArrayStoringDidLoadNotification = @"GLAArrayStoringDidLoadNotification";
NSString *GLAArrayStoringDidLoadNotificationUserInfoLoadedChildren = @"GLAArrayStoringDidLoadNotificationUserInfoLoadedChildren";
