//
//  GLAProjectCollectionListEditor.m
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAProjectCollectionListEditor.h"


NSString *const GLAProjectCollectionListEditorDidChangeNotification = @"GLAProjectCollectionListEditorDidChangeNotification";


@interface GLAProjectCollectionListEditor ()

@property(nonatomic) NSMutableArray *mutableCollections;

@end

@implementation GLAProjectCollectionListEditor

- (instancetype)initWithCollections:(NSArray *)collections
{
    self = [super init];
    if (self) {
        _mutableCollections = [NSMutableArray arrayWithArray:collections];
    }
    return self;
}

- (NSArray *)childCollectionsAtIndexes:(NSIndexSet *)indexes
{
	NSMutableArray *mutableCollections = (self.mutableCollections);
	return [mutableCollections objectsAtIndexes:indexes];
}

- (NSArray *)copyCollections
{
	return [(self.mutableCollections) copy];
}

- (void)addChildCollections:(NSArray *)collections
{
	NSMutableArray *mutableCollections = (self.mutableCollections);
	[mutableCollections addObjectsFromArray:collections];
	
	[self postChangeNotification];
}

- (void)insertChildCollections:(NSArray *)collections atIndexes:(NSIndexSet *)indexes
{
	NSMutableArray *mutableCollections = (self.mutableCollections);
	[mutableCollections insertObjects:collections atIndexes:indexes];
	
	[self postChangeNotification];
}

- (void)removeChildCollections:(NSArray *)collections
{
	NSMutableArray *mutableCollections = (self.mutableCollections);
	[mutableCollections removeObjectsInArray:collections];
	
	[self postChangeNotification];
}

- (void)removeChildCollectionsAtIndexes:(NSIndexSet *)indexes
{
	NSMutableArray *mutableCollections = (self.mutableCollections);
	[mutableCollections removeObjectsAtIndexes:indexes];
	
	[self postChangeNotification];
}

- (void)replaceChildCollectionsAtIndexes:(NSIndexSet *)indexes withChildCollections:(NSArray *)collections
{
	NSMutableArray *mutableCollections = (self.mutableCollections);
	[mutableCollections replaceObjectsAtIndexes:indexes withObjects:collections];
	
	[self postChangeNotification];
}

- (void)moveChildCollectionsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)toIndex
{
	NSMutableArray *mutableCollections = (self.mutableCollections);
	NSArray *collectionsToMove = [mutableCollections objectsAtIndexes:indexes];
	[mutableCollections removeObjectsAtIndexes:indexes];
	[mutableCollections insertObjects:collectionsToMove atIndexes:[NSIndexSet indexSetWithIndex:toIndex]];
	
	[self postChangeNotification];
}

- (void)postChangeNotification
{
	//[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectCollectionListEditorDidChangeNotification object:self];
}
/*
- (id)addObserverForAnyChanges:(void (^)(void))block
{
	return [[NSNotificationCenter defaultCenter] addObserverForName:GLAProjectCollectionListEditorDidChangeNotification object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		block();
	}];
}
*/
@end
