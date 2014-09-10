//
//  GLAPrototypeBNavigationBar.m
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLANavigationBar.h"
#import "GLAUIStyle.h"


@interface GLANavigationBar ()

@property(nonatomic) CGFloat private_highlightAmount;

@end

@implementation GLANavigationBar

- (BOOL)isFlipped
{
	return YES;
}

- (void)awakeFromNib
{
	(self.wantsLayer) = YES;
	//CALayer *layer = (self.layer);
	//(layer.backgroundColor) = ([GLAUIStyle activeStyle].contentBackgroundColor.CGColor);
}

+ (id)defaultAnimationForKey:(NSString *)key
{
	if ([key isEqualToString:@"highlightAmount"]) {
		CABasicAnimation *animation = [CABasicAnimation animation];
		(animation.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		return animation;
	}
	else {
		return [super defaultAnimationForKey:key];
	}
}

- (CGFloat)highlightAmount
{
	return (self.private_highlightAmount);
}

- (void)setHighlightAmount:(CGFloat)highlightAmount
{
	(self.private_highlightAmount) = highlightAmount;
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	NSRect dirtyRect = [uiStyle drawingRectOfActiveHighlightForBounds:(self.bounds) time:1.0];
	[self setNeedsDisplayInRect:dirtyRect];
}

- (void)highlightWithColor:(NSColor *)color animate:(BOOL)animate
{
	if (color) {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 6.0 / 36.0;
			(self.animator.highlightAmount) = 1.0;
		} completionHandler:nil];
		
		(self.highlightColor) = color;
	}
	else { // color is nil
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 3.0 / 36.0;
			(self.animator.highlightAmount) = 0.0;
		} completionHandler:^ {
			(self.highlightColor) = nil;
		}];
	}
	
	//[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	NSColor *highlightColor = (self.highlightColor);
	if (highlightColor) {
		[uiStyle drawActiveHighlightForBounds:(self.bounds) withColor:highlightColor time:(self.highlightAmount)];
	}
	
	if (self.showBottomEdgeLine) {
		[(uiStyle.projectTableDividerColor) setFill];
		CGRect dividerRect, dividerElseRect;
		CGRectDivide((self.bounds), &dividerRect, &dividerElseRect, 0.5, CGRectMaxYEdge);
		NSRectFillUsingOperation(dividerRect, NSCompositeSourceOver);
	}
}

@end
