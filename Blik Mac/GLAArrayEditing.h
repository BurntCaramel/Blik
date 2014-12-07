//
//  GLAArrayEditing.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;

@protocol GLAArrayEditing;

typedef void (^ GLAArrayEditingBlock)(id<GLAArrayEditing> arrayEditor);
typedef id (^ GLAArrayChildVisitorBlock)(id child);


@protocol GLAArrayInspecting <NSObject>

- (NSArray *)copyChildren;
- (id)childAtIndex:(NSUInteger)index;
- (NSArray *)childrenAtIndexes:(NSIndexSet *)indexes;

// Working with unique children
- (NSUInteger)indexOfFirstChildWhoseKey:(NSString *)key hasValue:(id)value;
- (NSIndexSet *)indexesOfChildrenWhoseResultFromVisitor:(GLAArrayChildVisitorBlock)childVisitor hasValueContainedInSet:(NSSet *)valuesSet;

- (NSArray *)filterArray:(NSArray *)objects whoseResultFromVisitorIsNotAlreadyPresent:(GLAArrayChildVisitorBlock)childVisitor;

@end


@protocol GLAArrayEditing <GLAArrayInspecting>

- (void)addChildren:(NSArray *)objects;
- (void)insertChildren:(NSArray *)objects atIndexes:(NSIndexSet *)indexes;
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects;
- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)toIndex;

- (BOOL)removeFirstChildWhoseKey:(NSString *)key hasValue:(id)value;

- (id)replaceFirstChildWhoseKey:(NSString *)key hasValue:(id)value usingChangeBlock:(id (^)(id originalObject))objectChanger;

@end
