//
//  GLATableCellView.m
//  Blik
//
//  Created by Patrick Smith on 13/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLATableCellView.h"


@implementation GLATableCellView

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSMenuItem *menuItem = self.enclosingMenuItem;
	if (menuItem) {
		// Do not pass up to table view as normal, as we want to do the tracking
	}
	else {
		[self.nextResponder mouseDown:theEvent];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSMenuItem *menuItem = self.enclosingMenuItem;
	if (menuItem) {
		// Perform performClick:, which GLATableView implements.
		[self.nextResponder tryToPerform:@selector(performClick:) with:self];
	}
	else {
		[self.nextResponder mouseUp:theEvent];
	}
}

@end
