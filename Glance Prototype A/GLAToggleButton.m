//
//  GLAToggleButton.m
//  Blik
//
//  Created by Patrick Smith on 17/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAToggleButton.h"
#import "GLAUIStyle.h"

@implementation GLAToggleButton

@end


@implementation GLAToggleButtonCell

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
#if 0
	[[NSColor redColor] setFill];
	NSRectFill(frame);
#endif
	
	
	CGFloat ellipseDimension = 16.0;
	NSPoint offset = NSMakePoint((NSWidth(frame) - ellipseDimension) / 2.0, (NSHeight(frame) - ellipseDimension) / 2.0);
	NSRect ellipseRect = NSMakeRect(NSMinX(frame) + offset.x, NSMinY(frame) + offset.y, ellipseDimension, ellipseDimension);
	
	GLAUIStyle *uiStyle = [GLAUIStyle styleA];
	[(uiStyle.toggleBorderColor) setStroke];
	[[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(ellipseRect, 0.5, 0.5)] stroke];
	
	if (self.isOnAndShowsOnState) {
		NSRect insideEllipseRect = NSInsetRect(ellipseRect, 3.0, 3.0);
		[(uiStyle.toggleInsideColor) setFill];
		[[NSBezierPath bezierPathWithOvalInRect:insideEllipseRect] fill];
	}
}

@end