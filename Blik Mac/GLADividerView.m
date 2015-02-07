//
//  GLADividerView.m
//  Blik
//
//  Created by Patrick Smith on 18/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLADividerView.h"
#import "GLAUIStyle.h"


@implementation GLADividerView

- (void)drawRect:(NSRect)dirtyRect
{
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	
	NSColor *dividerColor = (style.mainDividerColor);
	[dividerColor setFill];
	NSRectFill(dirtyRect);
}

@end
