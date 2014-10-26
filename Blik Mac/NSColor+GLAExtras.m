//
//  NSColor+GLAExtras.m
//  Blik
//
//  Created by Patrick Smith on 19/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "NSColor+GLAExtras.h"


@implementation NSColor (GLAExtras)

+ (instancetype)gla_colorWithSRGBGray:(CGFloat)gray alpha:(CGFloat)alpha
{
	return [self colorWithSRGBRed:gray green:gray blue:gray alpha:alpha];
}

@end
