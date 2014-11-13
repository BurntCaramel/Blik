//
//  GLAArrayEditorTableDraggingHelper.m
//  Blik
//
//  Created by Patrick Smith on 11/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAArrayEditorTableDraggingHelper.h"


@interface GLAArrayEditorTableDraggingHelper ()

@property(readwrite, weak, nonatomic) id<GLAArrayEditorTableDraggingHelperDelegate> delegate;

@property(readwrite, copy, nonatomic) NSIndexSet *draggedRowIndexes;

@end

@implementation GLAArrayEditorTableDraggingHelper

- (instancetype)initWithDelegate:(id<GLAArrayEditorTableDraggingHelperDelegate>)delegate
{
	self = [super init];
	if (self) {
		_delegate = delegate;
	}
	return self;
}

- (instancetype)init
{
	@throw [NSException exceptionWithName:NSGenericException reason:@"GLAArrayEditorTableDraggingHelper must be initialised with a delegate. Use -initWithDelegate:" userInfo:nil];
	
	return nil;
}

- (BOOL)canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard
{
	id<GLAArrayEditorTableDraggingHelperDelegate> delegate = (self.delegate);
	return [delegate arrayEditorTableDraggingHelper:self canUseDraggingPasteboard:draggingPasteboard];
}

- (void)makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock
{
	id<GLAArrayEditorTableDraggingHelperDelegate> delegate = (self.delegate);
	[delegate arrayEditorTableDraggingHelper:self makeChangesUsingEditingBlock:editBlock];
}

- (BOOL)canCopyObjects
{
	id<GLAArrayEditorTableDraggingHelperDelegate> delegate = (self.delegate);
	if (![delegate respondsToSelector:@selector(arrayEditorTableDraggingHelper:makeCopiesOfObjects:)]) {
		return NO;
	}
	
	return YES;
}

- (NSArray *)makeCopiesOfObjects:(NSArray *)objectsToCopy
{
	id<GLAArrayEditorTableDraggingHelperDelegate> delegate = (self.delegate);
	if (![delegate respondsToSelector:@selector(arrayEditorTableDraggingHelper:makeCopiesOfObjects:)]) {
		return nil;
	}
	
	return [delegate arrayEditorTableDraggingHelper:self makeCopiesOfObjects:objectsToCopy];
}

#pragma mark <NSTableViewDelegate>

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes
{
	(self.draggedRowIndexes) = rowIndexes;
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	// Does not work for some reason.
	if (operation == NSDragOperationDelete) {
		NSIndexSet *sourceRowIndexes = (self.draggedRowIndexes);
		(self.draggedRowIndexes) = nil;
		
		[self makeChangesUsingEditingBlock:^(id<GLAArrayEditing> arrayEditor) {
			[arrayEditor removeChildrenAtIndexes:sourceRowIndexes];
		}];
	}
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	if ([info draggingSource] != tableView) {
		(self.draggedRowIndexes) = nil;
		return NSDragOperationNone;
	}
	
	NSPasteboard *pboard = (info.draggingPasteboard);
	if (![self canUseDraggingPasteboard:pboard]) {
		(self.draggedRowIndexes) = nil;
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
		(self.draggedRowIndexes) = nil;
		return NO;
	}
	
	NSIndexSet *sourceRowIndexes = (self.draggedRowIndexes);
	(self.draggedRowIndexes) = nil;
	
	NSPasteboard *pboard = (info.draggingPasteboard);
	if (![self canUseDraggingPasteboard:pboard]) {
		return NO;
	}
	
	__block BOOL acceptDrop = YES;
	
	[self makeChangesUsingEditingBlock:^(id<GLAArrayEditing> arrayEditor) {
		NSDragOperation sourceOperation = (info.draggingSourceOperationMask);
		if (sourceOperation & NSDragOperationMove) {
			// The row index is the final destination, so reduce it by the number of rows being moved before it.
			NSInteger adjustedRow = row - [sourceRowIndexes countOfIndexesInRange:NSMakeRange(0, row)];
			
			[arrayEditor moveChildrenAtIndexes:sourceRowIndexes toIndex:adjustedRow];
		}
		else if (sourceOperation & NSDragOperationCopy) {
			NSArray *childrenToCopy = [arrayEditor childrenAtIndexes:sourceRowIndexes];
			NSArray *copiedChildren = [self makeCopiesOfObjects:childrenToCopy];
			if (copiedChildren) {
				[arrayEditor insertChildren:copiedChildren atIndexes:[NSIndexSet indexSetWithIndex:row]];
			}
			else {
				acceptDrop = NO;
			}
		}
		else if (sourceOperation & NSDragOperationDelete) {
			[arrayEditor removeChildrenAtIndexes:sourceRowIndexes];
		}
		else {
			acceptDrop = NO;
		}
	}];
	
	return acceptDrop;
}

@end
