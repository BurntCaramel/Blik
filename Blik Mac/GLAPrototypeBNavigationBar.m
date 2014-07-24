//
//  GLAPrototypeBNavigationBar.m
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAPrototypeBNavigationBar.h"
#import "GLAUIStyle.h"

@implementation GLAPrototypeBNavigationBar

- (void)awakeFromNib
{
	(self.wantsLayer) = YES;
	//CALayer *layer = (self.layer);
	//(layer.backgroundColor) = ([GLAUIStyle styleA].contentBackgroundColor.CGColor);
}

@end
