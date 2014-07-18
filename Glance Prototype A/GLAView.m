//
//  GLAView.m
//  Blik
//
//  Created by Patrick Smith on 11/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAView.h"

@implementation GLAView

+ (BOOL)requiresConstraintBasedLayout
{
	return YES;
}

- (void)updateConstraints
{
	id<GLAViewDelegate> delegate = (self.delegate);
	if (delegate && [delegate respondsToSelector:@selector(viewUpdateConstraints:)]) {
		[delegate viewUpdateConstraints:self];
	}
	
	[super updateConstraints];
}

@end
