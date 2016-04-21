//
//  GLAHighlightsTableCellView.m
//  Blik
//
//  Created by Patrick Smith on 28/10/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAHighlightsTableCellView.h"


@implementation GLAHighlightsTableCellView

- (void)mouseDown:(NSEvent *)theEvent
{
	NSMenuItem *menuItem = self.enclosingMenuItem;
	if (menuItem) {
		// Do not pass up to table view as normal
	}
	else {
		[self.nextResponder mouseDown:theEvent];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSMenuItem *menuItem = self.enclosingMenuItem;
	if (menuItem) {
		// Pass to performClick: handler, which GLATableView implements.
		[self.nextResponder tryToPerform:@selector(performClick:) with:self];
	}
	else {
		[self.nextResponder mouseUp:theEvent];
	}
}

@end
