//
//  GLAView.m
//  Blik
//
//  Created by Patrick Smith on 11/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
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

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p '%@'>", [self class], self, (self.identifier)];
}

@end
