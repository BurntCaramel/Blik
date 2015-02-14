//
//  GLAModelUUIDMap.m
//  Blik
//
//  Created by Patrick Smith on 29/10/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAModelUUIDMap.h"


@interface GLAModelUUIDMap ()

@property(nonatomic) NSMutableDictionary *mutableDictionary;

@end

@implementation GLAModelUUIDMap

- (instancetype)init
{
	self = [super init];
	if (self) {
		_mutableDictionary = [NSMutableDictionary new];
	}
	return self;
}

- (GLAModel *)objectWithUUID:(NSUUID *)UUID
{
	return (self.mutableDictionary)[UUID];
}

- (GLAModel *)objectForKeyedSubscript:(NSUUID *)UUID
{
	return [self objectWithUUID:UUID];
}

- (NSArray *)allObjects
{
	return (self.mutableDictionary.allValues);
}

#pragma mark -

- (void)addObjects:(NSArray *)objects
{
	NSMutableDictionary *mutableDictionary = (self.mutableDictionary);
	for (GLAModel *model in objects) {
		mutableDictionary[model.UUID] = model;
	}
}

- (void)setObjects:(NSArray *)objects additionsAndRemovalsBlock:(void(^)(NSArray *additions, NSArray *removals))block;
{
	NSMutableDictionary *mutableDictionary = (self.mutableDictionary);
	NSMutableDictionary *objectsBefore = [mutableDictionary mutableCopy];
	NSMutableArray *additions = [NSMutableArray new];
	
	[mutableDictionary removeAllObjects];
	
	for (GLAModel *model in objects) {
		NSUUID *UUID = (model.UUID);
		
		mutableDictionary[UUID] = model;
		
		if (objectsBefore[UUID]) {
			// Remove existing objects, to leave only the remainders.
			[objectsBefore removeObjectForKey:UUID];
		}
		else {
			// If object wasn't present before, include it in the additions.
			[additions addObject:model];
		}
	}
	
	NSArray *removals = [objectsBefore allValues];
	
	block(additions, removals);
}

- (void)removeObjects:(NSArray *)objects
{
	NSMutableDictionary *mutableDictionary = (self.mutableDictionary);
	for (GLAModel *model in objects) {
		[mutableDictionary removeObjectForKey:(model.UUID)];
	}
}

- (void)removeAllObjects
{
	[(self.mutableDictionary) removeAllObjects];
}

#pragma mark <GLAArrayObserving>

- (void)arrayEditorWasCreated:(GLAArrayEditor *)arrayEditor
{
	NSArray *children = [arrayEditor copyChildren];
	[self addObjects:children];
}

- (void)arrayEditorDidLoad:(GLAArrayEditor *)arrayEditor
{
	NSArray *children = [arrayEditor copyChildren];
	[self addObjects:children];
}

- (void)arrayEditor:(GLAArrayEditor *)arrayEditor didMakeChanges:(GLAArrayEditorChanges *)changes
{
	[self removeObjects:(changes.removedChildren)];
	[self removeObjects:(changes.replacedChildrenBefore)];
	
	[self addObjects:(changes.addedChildren)];
	[self addObjects:(changes.replacedChildrenAfter)];
}

#pragma mark <GLAArrayIndexing>

- (id)arrayEditor:(GLAArrayEditor *)arrayEditor firstIndexedChildWhoseKey:(NSString *)key hasValue:(id)value
{
	if ([key isEqualToString:@"UUID"] && [value isKindOfClass:[NSUUID class]]) {
		NSUUID *UUID = (id)value;
		return [self objectWithUUID:UUID];
	}
	
	return nil;
}

@end
