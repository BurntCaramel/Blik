//
//  GLASimpleBezierPath.h
//  Blik
//
//  Created by Patrick Smith on 13/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;

// For PaintCode: mimics NSBezierPath’s API but creates a CGPath.

@interface GLASimpleBezierPath : NSObject

- (void)moveToPoint:(NSPoint)aPoint;
- (void)lineToPoint:(NSPoint)aPoint;
- (void)curveToPoint:(NSPoint)aPoint controlPoint1:(NSPoint)controlPoint1 controlPoint2:(NSPoint)controlPoint2;
- (void)closePath;

@property(readonly, nonatomic) CGMutablePathRef CGMutablePath;

@end
