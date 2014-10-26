//
//  GLAPrototypeBProjectView.m
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAProjectView.h"
#import "GLAUIStyle.h"

@interface GLAProjectView ()

@end

@implementation GLAProjectView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		(self.wantsLayer) = YES;
		CALayer *layer = (self.layer);
		(layer.backgroundColor) = ([GLAUIStyle activeStyle].contentBackgroundColor.CGColor);
		//(layer.backgroundColor) = ([GLAUIStyle activeStyle].activeButtonHighlightColor.CGColor);
    }
    return self;
}

@end
