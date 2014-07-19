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

- (CGFloat)highlightOpacity
{
	return (self.cell.highlightOpacity);
}

- (void)setHighlightOpacity:(CGFloat)highlightOpacity
{
	GLANavigationButtonCell *cell = (self.cell);
	(cell.highlightOpacity) = highlightOpacity;
	
	[self setNeedsDisplayInRect:[cell highlightRectForBounds:[self bounds]]];
}

@end


@implementation GLANavigationButtonCell

- (NSRect)highlightRectForBounds:(NSRect)bounds
{
	return [self highlightRectForBounds:bounds fraction:1.0];
}

- (NSRect)highlightRectForBounds:(NSRect)bounds fraction:(CGFloat)fraction
{
	CGFloat height = 6.0 * fraction;
	NSRect topBarRect, elseRect;
	NSDivideRect(bounds, &topBarRect, &elseRect, height, CGRectMinYEdge);
	
	return topBarRect;
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	//if ((self.isOnAndShowsOnState)) {
	NSRect topBarRect = [self highlightRectForBounds:frame fraction:(self.highlightOpacity)];
	
	GLAUIStyle *uiStyle = [GLAUIStyle styleA];
	NSColor *barColor = (self.isEnabled) ? (uiStyle.activeButtonHighlightColor) : (uiStyle.activeButtonDisabledHighlightColor);
	barColor = [barColor colorWithAlphaComponent:(self.highlightOpacity) * (barColor.alphaComponent)];
	[barColor setFill];
	//[[([GLAUIStyle styleA].activeButtonHighlightColor) colorWithAlphaComponent:(self.highlightOpacity)] setFill];
	NSRectFill(topBarRect);
	//}
}

@end