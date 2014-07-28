//
//  GLAPrototypeBNavigationBar.m
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLANavigationBar.h"
#import "GLAUIStyle.h"


@interface GLANavigationBar ()

@end

@implementation GLANavigationBar

- (BOOL)isFlipped
{
	return YES;
}

- (void)awakeFromNib
{
	(self.wantsLayer) = YES;
	//CALayer *layer = (self.layer);
	//(layer.backgroundColor) = ([GLAUIStyle activeStyle].contentBackgroundColor.CGColor);
}

- (void)highlightWithColor:(NSColor *)color animate:(BOOL)animate
{
	(self.highlightColor) = color;
	
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSColor *highlightColor = (self.highlightColor);
	if (highlightColor) {
		GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
		[uiStyle drawActiveHighlightForBounds:(self.bounds) withColor:highlightColor time:1.0];
	}
}

@end
