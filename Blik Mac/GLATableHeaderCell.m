//
//  GLATableHeaderCell.m
//  Blik
//
//  Created by Patrick Smith on 13/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLATableHeaderCell.h"


@implementation GLATableHeaderCell

- (instancetype)initWithCell:(NSTableHeaderCell *)cell
{
	self = [self initTextCell:(cell.stringValue)];
	if (self) {
		//(self.stringValue) = (cell.stringValue);
		(self.image) = (cell.image);
	}
	return self;
}

#if 1
- (void)drawSortIndicatorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView ascending:(BOOL)ascending priority:(NSInteger)priority
{
	CGFloat lineWidth = 1.5;
	NSRect rectForPath = NSInsetRect([self sortIndicatorRectForBounds:cellFrame], lineWidth, lineWidth);
	
	if (ascending) {
		rectForPath.origin.y -= NSWidth(rectForPath) / 4.0;
	}
	else {
		rectForPath.origin.y += NSWidth(rectForPath) / 4.0;
	}
	
	NSBezierPath *path = [NSBezierPath new];
	[path moveToPoint:NSMakePoint(NSMinX(rectForPath), NSMidY(rectForPath))];
	if (ascending) {
		[path lineToPoint:NSMakePoint(NSMidX(rectForPath), NSMaxY(rectForPath))];
	}
	else {
		[path lineToPoint:NSMakePoint(NSMidX(rectForPath), NSMinY(rectForPath))];
	}
	[path lineToPoint:NSMakePoint(NSMaxX(rectForPath), NSMidY(rectForPath))];
	
	(path.lineWidth) = lineWidth;
	(path.lineJoinStyle) = NSRoundLineJoinStyle;
	(path.lineCapStyle) = NSRoundLineCapStyle;
	
	GLAUIStyle *activeStyle = [GLAUIStyle activeStyle];
	[(activeStyle.lightTextColor) setStroke];
	[path stroke];
}
#endif

- (void)drawWithFrame:(NSRect)cellFrame highlighted:(BOOL)highlighted inView:(NSView *)controlView
{
	GLAUIStyle *activeStyle = [GLAUIStyle activeStyle];
	
	NSColor *backgroundColor = (activeStyle.contentTableHeaderBackgroundColor);
	
	[backgroundColor setFill];
	NSRectFill(cellFrame);
	
	NSTableHeaderView *headerView = [controlView isKindOfClass:[NSTableHeaderView class]] ? (id)controlView : nil;
	if (headerView && [headerView columnAtPoint:cellFrame.origin] > 0) {
		NSRect dividerRect = cellFrame;
		dividerRect.size.width = 1.0;
		NSColor *dividerColor = (activeStyle.splitViewDividerColor);
		[dividerColor setFill];
		NSRectFillUsingOperation(dividerRect, NSCompositeSourceOver);
	}
	
	NSRect interiorFrame = NSInsetRect(cellFrame, 2.0, 1.0);
	//NSRect interiorFrame = NSInsetRect(cellFrame, 0.0, 0.0);
	
	(self.backgroundStyle) = NSBackgroundStyleDark;
	//(self.textColor) = (activeStyle.lightTextColor);
	(self.textColor) = [NSColor clearColor];
	
	NSFont *font = (activeStyle.tableHeaderFont);
	(self.font) = font;
	
	
	[self drawInteriorWithFrame:interiorFrame inView:controlView];
	
	interiorFrame.origin.y += [activeStyle verticalOffsetDownForFontWithKey:@"tableHeaderFont"];
	[(self.stringValue) drawInRect:interiorFrame withAttributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: (activeStyle.lightTextColor)}];
}

- (NSRect)drawingRectForBounds:(NSRect)theRect
{
	NSRect drawingRect = [super drawingRectForBounds:theRect];
	//drawingRect.origin.y -= 4.0;
	return drawingRect;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[self drawWithFrame:cellFrame highlighted:NO inView:controlView];
}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[self drawWithFrame:cellFrame highlighted:flag inView:controlView];
}

@end

@implementation GLAUIStyle (GLATableHeaderCell)

- (void)prepareContentTableColumn:(NSTableColumn *)tableColumn
{
#if 1
	NSTableHeaderCell *oldHeaderCell = (tableColumn.headerCell);
	GLATableHeaderCell *newHeaderCell = [[GLATableHeaderCell alloc] initWithCell:oldHeaderCell];
	//(newHeaderCell.font) =
	[tableColumn setHeaderCell:newHeaderCell];
#endif
}

@end