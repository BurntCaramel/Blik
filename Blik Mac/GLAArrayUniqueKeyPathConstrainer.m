//
//  GLAArrayUniquePropertyContrainer.m
//  Blik
//
//  Created by Patrick on 9/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAArrayUniqueKeyPathConstrainer.h"


@interface GLAArrayUniqueKeyPathConstrainer ()

@property(readonly, nonatomic) NSMutableDictionary *valueToChildDictionary;

@end

@implementation GLAArrayUniqueKeyPathConstrainer

- (instancetype)init
{
	self = [super init];
	if (self) {
		_valueToChildDictionary = [NSMutableDictionary new];
	}
	return self;
}

- (id)childWhoseKeyPath:(NSString *)keyPath hasValue:(id)value
{
	NSMutableDictionary *valueToChildDictionary = (self.valueToChildDictionary);
	id child = valueToChildDictionary[value];
	return child;
}

#pragma mark -

- (void)addChildrenToIndex:(NSArray *)addedChildren
{
	NSMutableDictionary *valueToChildDictionary = (self.valueToChildDictionary);
	NSString *keyPath = (self.keyPath);
	
	for (id child in addedChildren) {
		id value = [child valueForKeyPath:keyPath];
		valueToChildDictionary[value] = child;
	}
}

- (void)removeChildrenFromIndex:(NSArray *)removedChildren
{
	NSMutableDictionary *valueToChildDictionary = (self.valueToChildDictionary);
	NSString *keyPath = (self.keyPath);
	
	for (id child in removedChildren) {
		id value = [child valueForKeyPath:keyPath];
		[valueToChildDictionary removeObjectForKey:value];
	}
}

#pragma mark -

- (void)arrayWasCreated:(id<GLAArrayInspecting>)array
{
	NSArray *children = [array copyChildren];
	[self addChildrenToIndex:children];
}

- (void)array:(id<GLAArrayInspecting>)array didMakeChanges:(GLAArrayEditorChanges *)changes
{
	[self removeChildrenFromIndex:(changes.removedChildren)];
	[self removeChildrenFromIndex:(changes.replacedChildrenBefore)];
	
	[self addChildrenToIndex:(changes.addedChildren)];
	[self addChildrenToIndex:(changes.replacedChildrenAfter)];
}

- (NSArray *)array:(id<GLAArrayInspecting>)array filterPotentialChildren:(NSArray *)potentialChildren
{
	NSMutableDictionary *valueToChildDictionary = (self.valueToChildDictionary);
	NSString *keyPath = (self.keyPath);
	
	NSMutableArray *filteredChildren = [NSMutableArray array];
	for (id obj in potentialChildren) {
		id objectValue = [obj valueForKeyPath:keyPath];
		// We want the objects that aren't present.
		BOOL notPresent = (valueToChildDictionary[objectValue] == nil);
		if (notPresent) {
			[filteredChildren addObject:obj];
		}
	}
	return filteredChildren;
}

@end
