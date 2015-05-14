//
//  GLASimpleBezierPath.m
//  Blik
//
//  Created by Patrick Smith on 13/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLASimpleBezierPath.h"


@implementation GLASimpleBezierPath

- (instancetype)init
{
	self = [super init];
	if (self) {
		_CGMutablePath = CGPathCreateMutable();
	}
	return self;
}

- (void)moveToPoint:(NSPoint)aPoint
{
	CGPathMoveToPoint(_CGMutablePath, NULL, aPoint.x, aPoint.y);
}

- (void)lineToPoint:(NSPoint)aPoint
{
	CGPathAddLineToPoint(_CGMutablePath, NULL, aPoint.x, aPoint.y);
}

- (void)curveToPoint:(NSPoint)aPoint controlPoint1:(NSPoint)controlPoint1 controlPoint2:(NSPoint)controlPoint2
{
	CGPathAddCurveToPoint(_CGMutablePath, NULL, controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, aPoint.x, aPoint.y);
}

- (void)closePath
{
	CGPathCloseSubpath(_CGMutablePath);
}

@end
