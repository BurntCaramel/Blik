//
//  GLACollectionIndicationView.m
//  Blik
//
//  Created by Patrick Smith on 28/10/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectionIndicationButton.h"
#import "GLAUIStyle.h"
#import "GLASimpleBezierPath.h"


@interface GLACollectionIndicationButton ()

@property(nonatomic) CALayer *dotLayer;
@property(nonatomic) CAShapeLayer *folderShapeLayer;

@end

@implementation GLACollectionIndicationButton

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		(self.wantsLayer) = YES;
	}
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	(self.wantsLayer) = YES;
	
	//(self.needsLayout) = YES; // Required by OS X Yosemite, otherwise height is zero.
}

- (BOOL)wantsUpdateLayer
{
	return YES;
}

@synthesize collection = _collection;

- (void)setCollection:(GLACollection *)collection
{
	if (_collection == collection) {
		return;
	}
	
	_collection = collection;
	
	(self.needsLayout) = YES; // Required by OS X Yosemite, otherwise height is zero.
	(self.needsDisplay) = YES;
}

- (NSColor *)colorForDrawing
{
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	GLACollection *collection = (self.collection);
	
	return [uiStyle colorForCollectionColor:(collection.color)];
}

- (CAShapeLayer *)newFolderShapeLayer
{
	CAShapeLayer *folderShapeLayer = [CAShapeLayer new];
	
	GLASimpleBezierPath *folderPath = [GLASimpleBezierPath new];
	[folderPath moveToPoint: NSMakePoint(1, 9)];
	[folderPath curveToPoint: NSMakePoint(0, 8) controlPoint1: NSMakePoint(0.5, 9) controlPoint2: NSMakePoint(0, 8.5)];
	[folderPath lineToPoint: NSMakePoint(0, 2)];
	[folderPath curveToPoint: NSMakePoint(1, 1) controlPoint1: NSMakePoint(0, 1.5) controlPoint2: NSMakePoint(0.5, 1)];
	[folderPath lineToPoint: NSMakePoint(2.5, 1)];
	[folderPath curveToPoint: NSMakePoint(3, 1) controlPoint1: NSMakePoint(2.63, 1) controlPoint2: NSMakePoint(3, 1)];
	[folderPath lineToPoint: NSMakePoint(4, 2)];
	[folderPath lineToPoint: NSMakePoint(9, 2)];
	[folderPath curveToPoint: NSMakePoint(10, 3) controlPoint1: NSMakePoint(9.5, 2) controlPoint2: NSMakePoint(10, 2.5)];
	[folderPath lineToPoint: NSMakePoint(10, 8)];
	[folderPath curveToPoint: NSMakePoint(9, 9) controlPoint1: NSMakePoint(10, 8.5) controlPoint2: NSMakePoint(9.5, 9)];
	[folderPath lineToPoint: NSMakePoint(1, 9)];
	[folderPath closePath];
	
	(folderShapeLayer.path) = (folderPath.CGMutablePath);
	
	return folderShapeLayer;
}

- (void)updateLayer
{
	CALayer *layer = (self.layer);
	
	NSColor *color = (self.colorForDrawing);
	
	CGRect viewBounds = (self.bounds);
	CGFloat diameter = (self.diameter);
	
	CAShapeLayer *folderShapeLayer = (self.folderShapeLayer);
	CALayer *dotLayer = (self.dotLayer);
	
	CALayer *usedLayer;
	
	if (self.isFolder) {
		if (!folderShapeLayer) {
			(self.folderShapeLayer) = folderShapeLayer = [self newFolderShapeLayer];
			(folderShapeLayer.delegate) = self;
		}
		
		if (color) {
			
			//(folderShapeLayer.backgroundColor) = (color.CGColor);
			(folderShapeLayer.fillColor) = (color.CGColor);
		}
		
		usedLayer = folderShapeLayer;
		
		if (dotLayer) {
			[dotLayer removeFromSuperlayer];
		}
	}
	else {
		if (!dotLayer) {
			(self.dotLayer) = dotLayer = [CALayer new];
		}
		
		if (color) {
			(dotLayer.backgroundColor) = (color.CGColor);
		}
		
		usedLayer = dotLayer;
		
		(dotLayer.cornerRadius) = diameter / 2.0;
		
		if (folderShapeLayer) {
			[folderShapeLayer removeFromSuperlayer];
		}
	}
	
	(usedLayer.bounds) = CGRectMake(0.0, 0.0, diameter, diameter);
	
	(usedLayer.position) = CGPointMake((NSWidth(viewBounds) - diameter) / 2.0, (NSHeight(viewBounds) - diameter) / 2.0 + (self.verticalOffsetDown));
	(usedLayer.anchorPoint) = CGPointMake(0.0, 0.0);
	
	if (!usedLayer.superlayer) {
		[layer addSublayer:usedLayer];
	}
}

- (void)drawRect:(NSRect)dirtyRect
{
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
	CAAnimation *animation = [CAAnimation animation];
	//(animation.duration) = 1.0;
	return animation;
}

@end
