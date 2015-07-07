//
//  GLAArrayEditorUser.h
//  Blik
//
//  Created by Patrick Smith on 13/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAArrayEditor.h"


typedef GLAArrayEditor *(^ GLAArrayEditorUserLoadingBlock)(BOOL createAndLoadIfNeeded);
typedef void (^ GLAArrayEditorUserMakeEditsBlock)(GLAArrayEditingBlock editingBlock);
typedef BOOL (^ GLAArrayEditorUserBooleanResultBlock)();


@interface GLAArrayEditorUser : NSObject <GLALoadableArrayUsing>

- (instancetype)initWithLoadingBlock:(GLAArrayEditorUserLoadingBlock)loadingBlock makeEditsBlock:(GLAArrayEditorUserMakeEditsBlock)makeEditsBlock NS_DESIGNATED_INITIALIZER;


@property (nonatomic) dispatch_queue_t foregroundQueue;


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
