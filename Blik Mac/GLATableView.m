//
//  GLATableView.m
//  Blik
//
//  Created by Patrick Smith on 13/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLATableView.h"


@implementation GLATableView

- (void)performClick:(id)sender
{
	[NSApp sendAction:self.action to:self.target from:sender];
}

@end
