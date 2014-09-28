//
//  GLAArrayEditing.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;

@protocol GLAArrayEditing <NSObject>

- (void)addChildren:(NSArray *)objects;
- (void)insertChildren:(NSArray *)objects atIndexes:(NSIndexSet *)indexes;
//- (void)removeChildren:(NSArray *)objects;
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects;
- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)toIndex;

- (void)replaceChildWithValueForKey:(NSString *)key equalToValue:(id)value withObject:(id)object;

- (NSArray *)copyChildren;
- (NSArray *)childrenAtIndexes:(NSIndexSet *)indexes;

@end