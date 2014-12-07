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


- (BOOL)canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard;

- (void)makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock;

- (BOOL)canCopyObjects;
- (NSArray *)makeCopiesOfObjects:(NSArray *)objectsToCopy;

#pragma mark NSTableViewDelegate methods

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes;

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation;

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation;

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation;

@end


@protocol GLAArrayEditorTableDraggingHelperDelegate <NSObject>

- (BOOL)arrayEditorTableDraggingHelper:(GLAArrayEditorTableDraggingHelper *)tableDraggingHelper canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard;

- (void)arrayEditorTableDraggingHelper:(GLAArrayEditorTableDraggingHelper *)tableDraggingHelper makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock;

@optional

// Do not implement if you do not support copying.
- (NSArray *)arrayEditorTableDraggingHelper:(GLAArrayEditorTableDraggingHelper *)tableDraggingHelper makeCopiesOfObjects:(NSArray *)objectsToCopy;

@end


#if 0

/* Example implementation: */
 
- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
	// Return your model object.
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes
{
	return [(self.tableDraggingHelper) tableView:tableView draggingSession:session willBeginAtPoint:screenPoint forRowIndexes:rowIndexes];
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	return [(self.tableDraggingHelper) tableView:tableView draggingSession:session endedAtPoint:screenPoint operation:operation];
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	return [(self.tableDraggingHelper) tableView:tableView validateDrop:info proposedRow:row proposedDropOperation:dropOperation];
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	return [(self.tableDraggingHelper) tableView:tableView acceptDrop:info row:row dropOperation:dropOperation];
}

#endif
