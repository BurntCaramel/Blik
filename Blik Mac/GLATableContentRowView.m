//
//  GLATableContentRowView.m
//  Blik
//
//  Created by Patrick Smith on 12/09/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLATableContentRowView.h"
#import "GLAUIStyle.h"


@implementation GLATableContentRowView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
    
    // Drawing code here.
}

/*- (void)drawBackgroundInRect:(NSRect)dirtyRect
{
}*/

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	GLAUIStyle *activeStyle = [GLAUIStyle activeStyle];
	NSColor *selectionColor = (activeStyle.contentTableSelectionColor);
	[selectionColor setFill];
	NSRectFill(dirtyRect);
}

@end
