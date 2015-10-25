//
//  GLAArrayEditorTableDraggingHelper.m
//  Blik
//
//  Created by Patrick Smith on 11/11/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAArrayTableDraggingHelper.h"


@interface GLAArrayTableDraggingHelper ()

@property(readwrite, weak, nonatomic) id<GLAArrayTableDraggingHelperDelegate> delegate;

@property(readwrite, copy, nonatomic) NSIndexSet *draggedRowIndexes;

@end

@implementation GLAArrayTableDraggingHelper

- (instancetype)initWithDelegate:(id<GLAArrayTableDraggingHelperDelegate>)delegate
{
	self = [super init];
	if (self) {
		_delegate = delegate;
		_animates = YES;
	}
	return self;
}

- (instancetype)init __unavailable
{
	@throw [NSException exceptionWithName:NSGenericException reason:@"GLAArrayEditorTableDraggingHelper must be initialised with a delegate. Use -initWithDelegate:" userInfo:nil];
	
	return nil;
}

- (BOOL)canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard
{
	id<GLAArrayTableDraggingHelperDelegate> delegate = (self.delegate);
	return [delegate arrayEditorTableDraggingHelper:self canUseDraggingPasteboard:draggingPasteboard];
}

- (void)makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock
{
	id<GLAArrayTableDraggingHelperDelegate> delegate = (self.delegate);
	[delegate arrayEditorTableDraggingHelper:self makeChangesUsingEditingBlock:editBlock];
}

- (NSIndexSet *)outputIndexesForTableRows:(NSIndexSet *)rowIndexes
{
	id<GLAArrayTableDraggingHelperDelegate> delegate = (self.delegate);
	if (![delegate respondsToSelector:@selector(arrayEditorTableDraggingHelper:outputIndexesForTableRows:)]) {
		return rowIndexes;
	}
	
	return [delegate arrayEditorTableDraggingHelper:self outputIndexesForTableRows:rowIndexes];
}

- (BOOL)canCopyObjects
{
	id<GLAArrayTableDraggingHelperDelegate> delegate = (self.delegate);
	if (![delegate respondsToSelector:@selector(arrayEditorTableDraggingHelper:makeCopiesOfObjects:)]) {
		return NO;
	}
	
	return YES;
}

- (NSArray *)makeCopiesOfObjects:(NSArray *)objectsToCopy
{
	id<GLAArrayTableDraggingHelperDelegate> delegate = (self.delegate);
	if (![delegate respondsToSelector:@selector(arrayEditorTableDraggingHelper:makeCopiesOfObjects:)]) {
		return nil;
	}
	
	return [delegate arrayEditorTableDraggingHelper:self makeCopiesOfObjects:objectsToCopy];
}

- (NSIndexSet *)modelIndexes
{
	return [self outputIndexesForTableRows:(self.draggedRowIndexes)];
}

- (void)clearDraggedIndexes
{
	(self.draggedRowIndexes) = nil;
}

#pragma mark <NSTableViewDataSource>

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes
{
	(self.draggedRowIndexes) = rowIndexes;
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	// Does not work for some reason, should be when items are dragged to the trash I think.
	if (operation == NSDragOperationDelete) {
		NSIndexSet *sourceIndexes = (self.modelIndexes);
		[self clearDraggedIndexes];
		
		[self makeChangesUsingEditingBlock:^(id<GLAArrayEditing> arrayEditor) {
			[arrayEditor removeChildrenAtIndexes:sourceIndexes];
		}];
	}
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	if ([info draggingSource] != tableView) {
		[self clearDraggedIndexes];
		return NSDragOperationNone;
	}
	
	NSPasteboard *pboard = (info.draggingPasteboard);
	if (![self canUseDraggingPasteboard:pboard]) {
		[self clearDraggedIndexes];
		return NSDragOperationNone;
	}
	
	if (dropOperation == NSTableViewDropOn) {
		[tableView setDropRow:row dropOperation:NSTableViewDropAbove];
	}
	
	NSDragOperation sourceOperation = (info.draggingSourceOperationMask);
	if (sourceOperation & NSDragOperationMove) {
		return NSDragOperationMove;
	}
	else if (sourceOperation & NSDragOperationCopy) {
		if ([self canCopyObjects]) {
			return NSDragOperationCopy;
		}
		else {
			return NSDragOperationNone;
		}
	}
	else if (sourceOperation & NSDragOperationDelete) {
		return NSDragOperationDelete;
	}
	else {
		return NSDragOperationNone;
	}
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	if ([info draggingSource] != tableView) {
		[self clearDraggedIndexes];
		return NO;
	}
	
	NSIndexSet *sourceIndexes = (self.modelIndexes);
	NSIndexSet *targetIndexes = [self outputIndexesForTableRows:[NSIndexSet indexSetWithIndex:row]];
	[self clearDraggedIndexes];
	
	if (targetIndexes.count == 0) {
		return NO;
	}
	NSInteger targetIndex = (targetIndexes.firstIndex);
	
	NSPasteboard *pboard = (info.draggingPasteboard);
	if (![self canUseDraggingPasteboard:pboard]) {
		return NO;
	}
	
	__block BOOL acceptDrop = YES;
	
	//[tableView beginUpdates];
	
	[self makeChangesUsingEditingBlock:^(id<GLAArrayEditing> arrayEditor) {
		NSDragOperation sourceOperation = (info.draggingSourceOperationMask);
		if (sourceOperation & NSDragOperationMove) {
			// The row index is the final destination, so reduce it by the number of rows being moved before it.
			NSInteger adjustedTargetIndex = targetIndex - [sourceIndexes countOfIndexesInRange:NSMakeRange(0, targetIndex)];
			
			//[tableView moveRowAtIndex:[sourceRowIndexes firstIndex] toIndex:adjustedRow];
			[arrayEditor moveChildrenAtIndexes:sourceIndexes toIndex:adjustedTargetIndex];
		}
		else if (sourceOperation & NSDragOperationCopy) {
			NSArray *childrenToCopy = [arrayEditor childrenAtIndexes:sourceIndexes];
			NSArray *copiedChildren = [self makeCopiesOfObjects:childrenToCopy];
			if (copiedChildren) {
				[arrayEditor insertChildren:copiedChildren atIndexes:[NSIndexSet indexSetWithIndex:targetIndex]];
			}
			else {
				acceptDrop = NO;
			}
		}
		else if (sourceOperation & NSDragOperationDelete) {
			[arrayEditor removeChildrenAtIndexes:sourceIndexes];
		}
		else {
			acceptDrop = NO;
		}
	}];
	
	//[tableView endUpdates];
	
	return acceptDrop;
}

@end
