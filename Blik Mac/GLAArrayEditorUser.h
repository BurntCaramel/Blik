//
//  GLAArrayEditorUser.h
//  Blik
//
//  Created by Patrick Smith on 13/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAArrayEditor.h"


typedef GLAArrayEditor *(^ GLAArrayEditorUserAccessingBlock)(BOOL createIfNeeded, BOOL loadIfNeeded);
typedef void (^ GLAArrayEditorUserLoadingBlock)(GLAArrayEditor *arrayEditor, dispatch_block_t callWhenLoaded);
typedef void (^ GLAArrayEditorUserEditBlock)(GLAArrayEditingBlock editingBlock);
typedef BOOL (^ GLAArrayEditorUserBooleanResultBlock)();


@interface GLAArrayEditorUser : NSObject <GLALoadableArrayUsing>

- (instancetype)initWithOwner:(id)owner accessingBlock:(GLAArrayEditorUserAccessingBlock)accessingBlock editBlock:(GLAArrayEditorUserEditBlock)editBlock;


// Change notification, add those particular to your object.
- (void)makeObserverOfObject:(id)notifier forChangeNotificationWithName:(NSString *)changeNotificationName;
- (void)didChangeNotification:(NSNotification *)note;


// Dependencies, will wait for this block to return true before loading.
@property(copy, nonatomic) GLAArrayEditorUserBooleanResultBlock dependenciesAreFulfilledBlock;
// Return true if dependenciesAreFulfilledBlock returns true, or if it not set.
@property(readonly, nonatomic) BOOL dependenciesAreFulfilled;

// Dependency notification, add those particular to your object.
- (void)makeObserverOfObject:(id)notifier forDependencyFulfilledNotificationWithName:(NSString *)dependencyFulfilledNotificationName;
- (void)dependencyFulfilledNotification:(NSNotification *)note;

@end
