//
//  GLASplitView.m
//  Blik
//
//  Created by Patrick Smith on 5/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLASplitView.h"
#import "GLAUIStyle.h"


@implementation GLASplitView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (NSColor *)dividerColor
{
	return ([GLAUIStyle activeStyle].splitViewDividerColor);
}

@end
