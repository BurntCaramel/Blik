//
//  GLAArrayEditing.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;

@protocol GLAArrayInspecting, GLAArrayEditing;

typedef void (^ GLAArrayInspectingBlock)(id<GLAArrayInspecting> arrayInspector);
typedef void (^ GLAArrayEditingBlock)(id<GLAArrayEditing> arrayEditor);
typedef id (^ GLAArrayChildVisitorBlock)(id child);


@protocol GLAArrayInspecting <NSObject>

@property(readonly, nonatomic) NSUInteger childrenCount;

- (NSArray *)copyChildren;
- (id)childAtIndex:(NSUInteger)index;
- (NSArray *)childrenAtIndexes:(NSIndexSet *)indexes;

- (NSArray *)resultsFromChildVisitor:(GLAArrayChildVisitorBlock)childVisitor;

// Working with unique children
- (id)firstChildWhoseKey:(NSString *)key hasValue:(id)value;
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

- (void)replaceAllChildrenWithObjects:(NSArray *)objects;

- (BOOL)removeFirstChildWhoseKey:(NSString *)key hasValue:(id)value;

- (id)replaceFirstChildWhoseKey:(NSString *)key hasValue:(id)value usingChangeBlock:(id (^)(id originalObject))objectChanger;

@end


@protocol GLALoadableArrayUsing <NSObject>

@property(copy, nonatomic) GLAArrayInspectingBlock changeCompletionBlock;

@property(readonly, nonatomic) BOOL finishedLoading;

- (NSArray *)copyChildrenLoadingIfNeeded;
- (id<GLAArrayInspecting>)inspectLoadingIfNeeded;
// finishedLoading must be true before calling this method:
- (void)editChildrenUsingBlock:(GLAArrayEditingBlock)block;

@property(nonatomic) id representedObject;

@end
