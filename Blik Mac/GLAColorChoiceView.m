//
//  GLAColorChoiceView.m
//  Blik
//
//  Created by Patrick Smith on 16/09/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAColorChoiceView.h"
#import "pop/POP.h"
@import QuartzCore;


@interface GLAColorChoiceView ()

@property(nonatomic) NSTrackingArea *mainTrackingArea;
@property(nonatomic) BOOL mouseInside;

@end

@implementation GLAColorChoiceView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		(self.wantsLayer) = YES;
		(self.togglesOnAndOff) = YES;
    }
    return self;
}

 - (BOOL)wantsUpdateLayer
{
	return YES;
}

- (void)updateTrackingAreas
{
	NSTrackingArea *mainTrackingArea = (self.mainTrackingArea);
	if ( ! mainTrackingArea ) {
		mainTrackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:( NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited | NSTrackingInVisibleRect ) owner:self userInfo:nil];
		[self addTrackingArea:mainTrackingArea];
	}
}

- (NSSize)dotSize
{
	return NSMakeSize(32.0, 32.0);
}

- (CGFloat)scaleWhenOn
{
	return 1.35;
}

- (CGFloat)scaleWhenHovering
{
	return 1.122;
}

- (void)updateLayer
{
	CALayer *layer = (self.layer);
	CALayer *dotLayer = (self.dotLayer);
	if (!dotLayer) {
		//(self.dotLayer) = dotLayer = [GLAColorChoiceDotLayer new];
		(self.dotLayer) = dotLayer = [CALayer new];
		[layer addSublayer:dotLayer];
	}
	
	NSColor *color = (self.color);
	BOOL on = (self.on);
	BOOL mouseInside = (self.mouseInside);
	
	if (color) {
		[CATransaction begin];
		{
			[CATransaction setAnimationDuration:0.21];
			[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
			
			(dotLayer.backgroundColor) = (color.CGColor);
		}
		[CATransaction commit];
	}
	
	CGRect layerBounds = (layer.bounds);
	NSSize dotSize = (self.dotSize);
	(dotLayer.bounds) = CGRectMake(0.0, 0.0, dotSize.width, dotSize.height);
	(dotLayer.anchorPoint) = CGPointMake(0.5, 0.5);
	(dotLayer.position) = CGPointMake(NSWidth(layerBounds) / 2.0, NSHeight(layerBounds) / 2.0);
	
	(dotLayer.cornerRadius) = dotSize.width / 2.0;
	
	[CATransaction begin];
	{
		[CATransaction setAnimationDuration:0.03];
		
		(dotLayer.borderColor) = on ? [NSColor whiteColor].CGColor : [[NSColor whiteColor] colorWithAlphaComponent:0.0].CGColor;
		(dotLayer.borderWidth) = on ? 4.0 : 4.0;
	}
	[CATransaction commit];
	
	
	[CATransaction begin];
	{
		//[CATransaction setDisableActions:YES];
		[CATransaction setAnimationDuration:0.136];
		[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName: (on ? kCAMediaTimingFunctionEaseIn : kCAMediaTimingFunctionEaseOut) ]];
		
		CGFloat scale = on ? (self.scaleWhenOn) : ( mouseInside ? (self.scaleWhenHovering) : 1.0 );
		(dotLayer.transform) = CATransform3DMakeScale(scale, scale, 1.0);
	}
	[CATransaction commit];
}

@synthesize color = _color;

- (void)setColor:(NSColor *)color
{
	_color = color;
	(self.needsDisplay) = YES;
}

@synthesize on = _on;

- (void)setOn:(BOOL)on animate:(BOOL)animate
{
	if (_on == on) {
		return;
	}
	
	_on = on;
	
	(self.needsDisplay) = YES;
	
	if (animate) {
#if 0
		CALayer *dotLayer = (self.dotLayer);
		
		CGFloat scaleWhenOff = 1.0;
		CGFloat scaleWhenOn = (self.scaleWhenOn);
		
		[CATransaction begin];
		
		CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
		
		NSValue *offTransformValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(scaleWhenOff, scaleWhenOff, 1.0)];
		NSValue *onTransformValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(scaleWhenOn, scaleWhenOn, 1.0)];
		
		if (on) {
			(animation.fromValue) = offTransformValue;
			(animation.toValue) = onTransformValue;
			(animation.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		}
		else {
			(animation.fromValue) = onTransformValue;
			(animation.toValue) = offTransformValue;
			(animation.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		}
		
		(animation.duration) = 0.14;
		
		[dotLayer addAnimation:animation forKey:@"scale"];
		
		[CATransaction commit];
#endif
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAColorChoiceViewOnDidChangeNotification object:self];
}

- (void)setOn:(BOOL)on
{
	[self setOn:on animate:YES];
}

- (void)mouseDown:(NSEvent *)theEvent
{
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (self.togglesOnAndOff) {
		if (!(self.on)) {
			[self setOn:YES animate:YES];
		}
	}
	else {
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAColorChoiceViewDidClickNotification object:self];
	}
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	(self.mouseInside) = YES;
	
	(self.needsDisplay) = YES;
}

- (void)mouseExited:(NSEvent *)theEvent
{
	(self.mouseInside) = NO;
	
	(self.needsDisplay) = YES;
}

@end


NSString *GLAColorChoiceViewOnDidChangeNotification = @"GLAColorChoiceViewOnDidChangeNotification";
NSString *GLAColorChoiceViewDidClickNotification = @"GLAColorChoiceViewDidClickNotification";
