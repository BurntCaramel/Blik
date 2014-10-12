//
//  GLAArrayEditor.m
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAArrayEditor.h"

// API based on PHCollectionListChangeRequest


NSString *GLAArrayEditorDidChangeNotification = @"GLAArrayEditorDidChangeNotification";

@interface GLAArrayEditor ()

@property(nonatomic) NSMutableArray *mutableChildren;

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

- (NSArray *)childrenAtIndexes:(NSIndexSet *)indexes
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	return [mutableChildren objectsAtIndexes:indexes];
}

- (NSArray *)copyChildren
{
	return [(self.mutableChildren) copy];
}

- (void)addChildren:(NSArray *)objects
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	[mutableChildren addObjectsFromArray:objects];
	
	[self enqueueChangeNotification];
}

- (void)insertChildren:(NSArray *)objects atIndexes:(NSIndexSet *)indexes
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	[mutableChildren insertObjects:objects atIndexes:indexes];
	
	[self enqueueChangeNotification];
}
/*
- (void)removeChildren:(NSArray *)objects
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	[mutableChildren removeObjectsInArray:objects];
	
	[self enqueueChangeNotification];
}
*/
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	[mutableChildren removeObjectsAtIndexes:indexes];
	
	[self enqueueChangeNotification];
}

- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	[mutableChildren replaceObjectsAtIndexes:indexes withObjects:objects];
	
	[self enqueueChangeNotification];
}

- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)toIndex
{
	NSMutableArray *mutableChildren = (self.mutableChildren);
	NSArray *objectsToMove = [mutableChildren objectsAtIndexes:indexes];
	[mutableChildren removeObjectsAtIndexes:indexes];
	[mutableChildren insertObjects:objectsToMove atIndexes:[NSIndexSet indexSetWithIndex:toIndex]];
	
	[self enqueueChangeNotification];
}

- (void)enqueueChangeNotification
{
	// Enqueue using NSNotificationQueue so multiple changes can get coalesced.
	NSNotificationQueue *noteQueue = [NSNotificationQueue defaultQueue];
	NSNotification *note = [NSNotification notificationWithName:GLAArrayEditorDidChangeNotification object:self];
	[noteQueue enqueueNotification:note postingStyle:NSPostASAP];
}


- (void)replaceChildWithValueForKey:(NSString *)key equalToValue:(id)value withObject:(id)object
{
	NSIndexSet *indexes = [(self.mutableChildren) indexesOfObjectsPassingTest:^BOOL(id originalObject, NSUInteger idx, BOOL *stop) {
		BOOL found = [[originalObject valueForKey:key] isEqual:value];
		if (found) {
			*stop = YES;
		}
		return found;
	}];
	
	[self replaceChildrenAtIndexes:indexes withObjects:@[object]];

}

@end
