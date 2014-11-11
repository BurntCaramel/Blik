//
//  GLAArrayEditorTableDraggingHelper.h
//  Blik
//
//  Created by Patrick Smith on 11/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAArrayEditing.h"

@protocol GLAArrayEditorTableDraggingHelperDelegate;


@interface GLAArrayEditorTableDraggingHelper : NSObject

- (instancetype)initWithDelegate:(id<GLAArrayEditorTableDraggingHelperDelegate>)delegate;

@property(readonly, weak, nonatomic) id<GLAArrayEditorTableDraggingHelperDelegate> delegate;

@property(readonly, copy, nonatomic) NSIndexSet *draggedRowIndexes;

#pragma mark NSTableViewDelegate methods

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes;

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation;

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation;

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation;

@end


@protocol GLAArrayEditorTableDraggingHelperDelegate <NSObject>

- (void)arrayEditorTableDraggingHelper:(GLAArrayEditorTableDraggingHelper *)tableDraggingHelper makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock;

- (BOOL)arrayEditorTableDraggingHelper:(GLAArrayEditorTableDraggingHelper *)tableDraggingHelper canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard;

@optional

// Do not implement or return nil if you do not support copying.
- (NSArray *)arrayEditorTableDraggingHelper:(GLAArrayEditorTableDraggingHelper *)tableDraggingHelper makeCopiesOfObjects:(NSArray *)objectsToCopy;

@end