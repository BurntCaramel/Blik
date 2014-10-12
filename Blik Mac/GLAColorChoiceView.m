//
//  GLAColorChoiceView.m
//  Blik
//
//  Created by Patrick Smith on 16/09/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAColorChoiceView.h"
#import "pop/POP.h"
@import QuartzCore;


@interface GLAColorChoiceView ()

@property(nonatomic) NSColor *private_color;
@property(nonatomic) BOOL private_on;

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

- (void)updateLayer
{
	CALayer *layer = (self.layer);
	NSColor *color = (self.color);
	BOOL on = (self.on);
	
	if (color) {
		(layer.backgroundColor) = (color.CGColor);
	}
	
	(layer.borderColor) = on ? [NSColor whiteColor].CGColor : [[NSColor whiteColor] colorWithAlphaComponent:0.0].CGColor;
	//(layer.borderWidth) = on ? 4.0 : 0.0;
	(layer.borderWidth) = on ? 4.0 : 4.0;
	
	(layer.cornerRadius) = NSWidth(layer.bounds) / 2.0;
	
	//(layer.contentsScale) = on ? 1.0 : 0.8;
	
	//POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:@"contentsScale"];
#if 0
	POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
	(animation.fromValue) = @(0.8);
	(animation.toValue) = @(0.4);
	[layer pop_addAnimation:animation forKey:@"scaleSpring"];
#elseif 0
	(layer.contentsGravity) = kCAGravityCenter;
	//(layer.anchorPoint) = CGPointMake(0.5, 0.5);
	CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
	(scaleAnimation.values) =
	@[
	  @(0.6),
	  @(1.1),
	  @(1.2)
	  ];
	(scaleAnimation.keyTimes) =
	@[
	  @(0.3),
	  @(0.7),
	  @(1.0)
	  ];
	(scaleAnimation.duration) = 6.0 / 12.0;
	
	[CATransaction begin];
	[layer addAnimation:scaleAnimation forKey:@"pop"];
	//[layer setValue:@(1.2) forKeyPath:@"transform.scale"];
	[CATransaction commit];
#endif
}

- (NSColor *)color
{
	return (self.private_color);
}

- (void)setColor:(NSColor *)color
{
	(self.private_color) = color;
	(self.needsDisplay) = YES;
}

- (BOOL)on
{
	return (self.private_on);
}

- (void)setOn:(BOOL)on
{
	if ((self.private_on) == on) {
		return;
	}
	
	(self.private_on) = on;
	(self.needsDisplay) = YES;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAColorChoiceViewOnDidChangeNotification object:self];
}

- (void)mouseDown:(NSEvent *)theEvent
{
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (self.togglesOnAndOff) {
		if (!(self.on)) {
			(self.on) = YES;
		}
	}
	else {
		[[NSNotificationCenter defaultCenter] postNotificationName:GLAColorChoiceViewDidClickNotification object:self];
	}
}

@end

NSString *GLAColorChoiceViewOnDidChangeNotification = @"GLAColorChoiceViewOnDidChangeNotification";
NSString *GLAColorChoiceViewDidClickNotification = @"GLAColorChoiceViewDidClickNotification";
