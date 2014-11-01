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
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects;
- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)toIndex;

- (NSArray *)copyChildren;
- (NSArray *)childrenAtIndexes:(NSIndexSet *)indexes;

// Working with unique children
- (NSIndexSet *)indexesOfChildrenWhoseKeyPath:(NSString *)keyPath hasValue:(id)value;
- (NSIndexSet *)indexesOfChildrenWhoseKeyPath:(NSString *)keyPath hasValueContainedInSet:(NSSet *)valuesSet;
- (NSArray *)filterArray:(NSArray *)objects whoseValuesIsNotPresentForKeyPath:(NSString *)keyPath;
- (BOOL)replaceFirstChildWhoseKey:(NSString *)key hasValue:(id)value usingChangeBlock:(id (^)(id originalObject))objectChanger;

@end