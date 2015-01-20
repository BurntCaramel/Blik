//
//  NSTableView+GLAActionHelpers.m
//  Blik
//
//  Created by Patrick Smith on 18/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "NSTableView+GLAActionHelpers.h"


@implementation NSTableView (GLAActionHelpers)

- (NSIndexSet *)gla_rowIndexesForActionFrom:(id)sender
{
	NSIndexSet *selectedIndexes = (self.selectedRowIndexes);
	
	BOOL isContextual = ((sender != nil) && [sender isKindOfClass:[NSMenuItem class]]);
	
	if (isContextual) {
		NSInteger clickedRow = (self.clickedRow);
		if (clickedRow == -1) {
			return [NSIndexSet indexSet];
		}
		
		if ([selectedIndexes containsIndex:clickedRow]) {
			return selectedIndexes;
		}
		else {
			return [NSIndexSet indexSetWithIndex:clickedRow];
		}
	}
	else {
		return selectedIndexes;
	}
}

@end
