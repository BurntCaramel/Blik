//
//  GLAProjectCollectionListEditor.m
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAProjectCollectionListEditor.h"


NSString *const GLAProjectCollectionListEditorDidChangeNotification = @"GLAProjectCollectionListEditorDidChangeNotification";


@implementation GLAProjectCollectionListEditor

- (instancetype)initWithCollections:(NSArray *)collections
{
    self = [super init];
    if (self) {
        _mutableCollections = [NSMutableArray arrayWithArray:collections];
    }
    return self;
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
	[mutableCollections insertObjects:collectionsToMove atIndexes:[NSIndexSet indexSetWithIndex:toIndex]];
	
	[self postChangeNotification];
}

- (void)postChangeNotification
{
	//[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectCollectionListEditorDidChangeNotification object:self];
}

@end
