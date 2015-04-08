//
//  GLAOverlaidBarView.m
//  Blik
//
//  Created by Patrick Smith on 7/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAOverlaidBarView.h"
#import "GLAUIStyle.h"


@implementation GLAOverlaidBarView

- (BOOL)wantsUpdateLayer
{
	return YES;
}

- (void)updateLayer
{
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	CALayer *layer = (self.layer);
	
	(layer.backgroundColor) = (style.overlaidBarBackgroundColor.CGColor);
}

@end
