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

- (void)addObjectsReplacing:(NSArray *)objects
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
			[objectsBefore removeObjectForKey:UUID];
		}
		else {
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

- (GLAModel *)objectWithUUID:(NSUUID *)UUID
{
	return (self.mutableDictionary)[UUID];
}

- (BOOL)containsObjectWithUUID:(NSUUID *)UUID
{
	return [self objectWithUUID:UUID] != nil;
}

- (id)objectForKeyedSubscript:(NSUUID *)UUID
{
	return [self objectWithUUID:UUID];
}

#pragma mark <GLAArrayObserving>

- (void)arrayWasCreated:(id<GLAArrayInspecting>)array
{
	NSArray *children = [array copyChildren];
	[self addObjectsReplacing:children];
}

- (void)array:(id<GLAArrayInspecting>)array didMakeChanges:(GLAArrayEditorChanges *)changes
{
	[self removeObjects:(changes.removedChildren)];
	[self removeObjects:(changes.replacedChildrenBefore)];
	
	[self addObjectsReplacing:(changes.addedChildren)];
	[self addObjectsReplacing:(changes.replacedChildrenAfter)];

}

@end
