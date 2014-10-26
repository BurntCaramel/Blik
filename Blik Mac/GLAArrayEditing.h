//
//  GLAArrayEditing.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;


@protocol GLAArrayEditing <NSObject>

- (void)addChildren:(NSArray *)objects;
- (void)insertChildren:(NSArray *)objects atIndexes:(NSIndexSet *)indexes;
//- (void)removeChildren:(NSArray *)objects;
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects;
- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)toIndex;

- (NSIndexSet *)indexesOfChildrenWhoseKey:(NSString *)key isEqualToValue:(id)value;
- (BOOL)replaceFirstChildWhoseKey:(NSString *)key isEqualToValue:(id)value withTransformer:(id (^)(id originalObject))objectTransformer;

- (NSArray *)copyChildren;
- (NSArray *)childrenAtIndexes:(NSIndexSet *)indexes;

@end