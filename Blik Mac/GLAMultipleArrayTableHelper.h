//
//  GLAMultipleArrayTableHelper.h
//  Blik
//
//  Created by Patrick Smith on 31/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAArrayEditing.h"

@protocol GLAMultipleArrayTableHelperDelegate;


@interface GLAMultipleArrayTableHelper : NSObject <NSTableViewDataSource>

- (instancetype)initWithDelegate:(id<GLAMultipleArrayTableHelperDelegate>)delegate;

@property(nonatomic) NSArray *groupIdentifiers;

@end


@protocol GLAMultipleArrayTableHelperDelegate <NSObject>

- (BOOL)multipleArrayTableDraggingHelper:(GLAMultipleArrayTableHelper *)helper hasRowForGroupWithIdentifier:(NSString *)groupIdentifier;

#pragma mark Editing

- (BOOL)multipleArrayTableDraggingHelper:(GLAMultipleArrayTableHelper *)helper canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard inGroupWithIdentifier:(NSString *)groupIdentifier;

- (void)multipleArrayTableDraggingHelper:(GLAMultipleArrayTableHelper *)helper makeChangesToGroupWithIdentifier:(NSString *)groupIdentifier usingEditingBlock:(GLAArrayEditingBlock)editBlock;

@optional

- (BOOL)multipleArrayTableDraggingHelper:(GLAMultipleArrayTableHelper *)helper canMoveObjects:(NSArray *)objectsToMove fromGroupWithIdentifier:(NSString *)sourceGroupIdentifier toGroupWithIdentifer:(NSString *)destinationGroupIdentifier;

// Only implement if you support copying.
- (NSArray *)multipleArrayTableDraggingHelper:(GLAMultipleArrayTableHelper *)helper makeCopiesOfObjects:(NSArray *)objectsToCopy fromGroupWithIdentifier:(NSString *)groupIdentifier;

@end
