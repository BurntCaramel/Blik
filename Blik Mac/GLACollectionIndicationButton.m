//
//  GLACollectionIndicationView.m
//  Blik
//
//  Created by Patrick Smith on 28/10/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectionIndicationButton.h"
#import "GLAUIStyle.h"


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
	
	(self.needsDisplay) = YES;
}

- (NSColor *)colorForDrawing
{
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	GLACollection *collection = (self.collection);
	
	return [uiStyle colorForCollectionColor:(collection.color)];
}

- (void)updateLayer
{
	CALayer *layer = (self.layer);
	CALayer *dotLayer = (self.dotLayer);
	if (!dotLayer) {
		(self.dotLayer) = dotLayer = [CALayer new];
		[layer addSublayer:dotLayer];
	}
	
	NSColor *color = (self.colorForDrawing);
	if (color) {
		(dotLayer.backgroundColor) = (color.CGColor);
	}
	
	CGRect viewBounds = (self.bounds);
	CGFloat diameter = (self.diameter);
	//(dotLayer.bounds) = CGRectMake((NSWidth(viewBounds) - diameter) / 2.0, (NSHeight(viewBounds) - diameter) / 2.0, diameter, diameter);
	(dotLayer.bounds) = CGRectMake(0.0, 0.0, diameter, diameter);
	
	(dotLayer.position) = CGPointMake((NSWidth(viewBounds) - diameter) / 2.0, (NSHeight(viewBounds) - diameter) / 2.0 + (self.verticalOffsetDown));
	(dotLayer.anchorPoint) = CGPointMake(0.0, 0.0);
	
	(dotLayer.cornerRadius) = diameter / 2.0;
	//(layer.anchorPoint) = CGPointMake(0.5, 0.5);
	
#if 0
	(layer.backgroundColor) = [NSColor redColor].CGColor;
#endif
}

- (void)drawRect:(NSRect)dirtyRect
{
}

@end
