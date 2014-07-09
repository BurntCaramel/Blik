//
//  GLAPrototypeBNavigationBar.m
//  Glance Prototype A
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAPrototypeBNavigationBar.h"
#import "GLAUIStyle.h"

@implementation GLAPrototypeBNavigationBar

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)awakeFromNib
{
	(self.wantsLayer) = YES;
	CALayer *layer = (self.layer);
	(layer.backgroundColor) = ([GLAUIStyle styleA].barBackgroundColor.CGColor);
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
