//
//  GLAArrayEditing.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;


@protocol GLAArrayInspecting <NSObject>

- (NSArray *)copyChildren;
- (NSArray *)childrenAtIndexes:(NSIndexSet *)indexes;

// Working with unique children
- (NSIndexSet *)indexesOfChildrenWhoseResultFromVisitor:(id (^)(id child))childVisitor hasValueContainedInSet:(NSSet *)valuesSet;
- (NSIndexSet *)indexesOfChildrenWhoseKey:(NSString *)keyPath hasValue:(id)value;
- (NSArray *)filterArray:(NSArray *)objects whoseValuesIsNotPresentForKeyPath:(NSString *)keyPath;

@end


@protocol GLAArrayEditing <GLAArrayInspecting>

- (void)addChildren:(NSArray *)objects;
- (void)insertChildren:(NSArray *)objects atIndexes:(NSIndexSet *)indexes;
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects;
- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)toIndex;

- (id)replaceFirstChildWhoseKeyPath:(NSString *)key hasValue:(id)value usingChangeBlock:(id (^)(id originalObject))objectChanger;

@end

typedef void (^ GLAArrayEditingBlock)(id<GLAArrayEditing> arrayEditor);
