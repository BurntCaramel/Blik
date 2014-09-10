//
//  GLAPrototypeBNavigationItem.m
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLANavigationButton.h"
#import "GLAUIStyle.h"


@implementation GLANavigationButton

- (GLANavigationButtonCell *)cell
{
	return (id)[super cell];
}

- (void)setCell:(GLANavigationButtonCell *)cell
{
	[super setCell:cell];
}

- (CGFloat)highlightAmount
{
	return (self.cell.highlightAmount);
}

- (void)setHighlightAmount:(CGFloat)highlightAmount
{
	GLANavigationButtonCell *cell = (self.cell);
	(cell.highlightAmount) = highlightAmount;
	
	[self setNeedsDisplayInRect:[cell highlightRectForBounds:[self bounds]]];
}

@end


@implementation GLANavigationButtonCell

- (NSRect)highlightRectForBounds:(NSRect)bounds
{
	return [self highlightRectForBounds:bounds time:1.0];
}

- (NSRect)highlightRectForBounds:(NSRect)bounds time:(CGFloat)t
{
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	return [uiStyle drawingRectOfActiveHighlightForBounds:bounds time:t];
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	NSColor *barColor = (self.isEnabled) ? (uiStyle.activeButtonHighlightColor) : (uiStyle.activeButtonDisabledHighlightColor);
	[uiStyle drawActiveHighlightForBounds:frame withColor:barColor time:(self.highlightAmount)];
	//}
}

@end