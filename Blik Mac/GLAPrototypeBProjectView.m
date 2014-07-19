//
//  GLAPrototypeBProjectView.m
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAPrototypeBProjectView.h"
#import "GLAUIStyle.h"

@interface GLAPrototypeBProjectView ()

@end

@implementation GLAPrototypeBProjectView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		(self.wantsLayer) = YES;
		CALayer *layer = (self.layer);
		(layer.backgroundColor) = ([GLAUIStyle styleA].contentBackgroundColor.CGColor);
    }
    return self;
}

@end
