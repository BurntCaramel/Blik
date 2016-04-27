//
//  GLAPopUpButton.m
//  Blik
//
//  Created by Patrick Smith on 8/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAPopUpButton.h"
#import "GLAUIStyle.h"


@interface GLAPopUpButton ()

@property(nonatomic) NSTrackingArea *mainTrackingArea;

@end

@implementation GLAPopUpButton

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		self.cell = [GLAPopUpButtonCell new];
	}
	return self;
}

- (GLAPopUpButtonCell *)cell
{
	return (GLAPopUpButtonCell *)[super cell];
}

- (void)setCell:(GLAPopUpButtonCell *)cell
{
	NSAssert([cell isKindOfClass:[GLAPopUpButtonCell class]], @"Cell of a GLAPopUpButton must be GLAPopUpButtonCell instance");
	[super setCell:cell];
}

#pragma mark -

- (CGFloat)leftSpacing
{
	return (self.cell.leftSpacing);
}

- (void)setLeftSpacing:(CGFloat)leftSpacing
{
	(self.cell.leftSpacing) = leftSpacing;
	
	(self.needsDisplay) = YES;
}

- (CGFloat)rightSpacing
{
	return (self.cell.rightSpacing);
}

- (void)setRightSpacing:(CGFloat)rightSpacing
{
	(self.cell.rightSpacing) = rightSpacing;
	
	(self.needsDisplay) = YES;
}

- (CGFloat)verticalOffsetDown
{
	return (self.cell.verticalOffsetDown);
}

- (void)setVerticalOffsetDown:(CGFloat)verticalOffsetDown
{
	(self.cell.verticalOffsetDown) = verticalOffsetDown;
	
	(self.needsDisplay) = YES;
}

- (BOOL)isAlwaysHighlighted
{
	return (self.cell.isAlwaysHighlighted);
}

- (void)setAlwaysHighlighted:(BOOL)alwaysHighlighted
{
	(self.cell.alwaysHighlighted) = alwaysHighlighted;
	
	(self.needsDisplay) = YES;
}

- (NSColor *)textHighlightColor
{
	return (self.cell.textHighlightColor);
}

- (void)setTextHighlightColor:(NSColor *)textHighlightColor
{
	(self.cell.textHighlightColor) = textHighlightColor;
	
	(self.needsDisplay) = YES;
}

- (NSColor *)backgroundColor
{
	return (self.cell.backgroundColor);
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
	(self.cell.backgroundColor) = backgroundColor;
	
	(self.needsDisplay) = YES;
}

- (CGFloat)highlightAmount
{
	return (self.cell.highlightAmount);
}

- (void)setHighlightAmount:(CGFloat)highlightAmount
{
	(self.cell.highlightAmount) = highlightAmount;
	
	(self.needsDisplay) = YES;
}

- (CGFloat)backgroundInsetAmount
{
	return (self.cell.backgroundInsetAmount);
}

- (void)setBackgroundInsetAmount:(CGFloat)backgroundInsetAmount
{
	(self.cell.backgroundInsetAmount) = backgroundInsetAmount;
	
	(self.needsDisplay) = YES;
}

- (CGFloat)backgroundInsetXAmount
{
	return (self.cell.backgroundInsetAmount);
}

- (void)setBackgroundInsetXAmount:(CGFloat)backgroundInsetXAmount
{
	(self.cell.backgroundInsetXAmount) = backgroundInsetXAmount;
	
	(self.needsDisplay) = YES;
}

- (CGFloat)backgroundInsetYAmount
{
	return (self.cell.backgroundInsetYAmount);
}

- (void)setBackgroundInsetYAmount:(CGFloat)backgroundInsetYAmount
{
	(self.cell.backgroundInsetYAmount) = backgroundInsetYAmount;
	
	(self.needsDisplay) = YES;
}

- (BOOL)hasPrimaryStyle
{
	return (self.cell.hasPrimaryStyle);
}

- (void)setHasPrimaryStyle:(BOOL)hasPrimaryStyle
{
	(self.cell.hasPrimaryStyle) = hasPrimaryStyle;
	
	(self.needsDisplay) = YES;
}

- (BOOL)hasSecondaryStyle
{
	return (self.cell.hasSecondaryStyle);
}

- (void)setHasSecondaryStyle:(BOOL)hasSecondaryStyle
{
	(self.cell.hasSecondaryStyle) = hasSecondaryStyle;
	
	(self.needsDisplay) = YES;
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

- (void)setState:(NSInteger)newState
{
	if (newState == NSOnState) {
		[self gla_animateHighlightForOn:YES];
	}
	else if (newState == NSOffState) {
		[self gla_animateHighlightForOn:NO];
	}
	
	[super setState:newState];
}

- (BOOL)isOnAndShowsOnState
{
	return (self.cell.isOnAndShowsOnState);
}

#pragma mark -

- (CGFloat)baselineOffsetFromBottom
{
	return 5.0;
}

#pragma mark -

- (void)updateTrackingAreas
{
	if (self.mainTrackingArea) {
		[self removeTrackingArea:(self.mainTrackingArea)];
	}
	
	NSTrackingArea *mainTrackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
	[self addTrackingArea:mainTrackingArea];
	(self.mainTrackingArea) = mainTrackingArea;
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	if ((self.isEnabled) && (self.state) == NSOffState) {
		[self gla_animateHighlightForHovered:YES];
	}
}

- (void)mouseExited:(NSEvent *)theEvent
{
	if ((self.isEnabled) && (self.state) == NSOffState) {
		[self gla_animateHighlightForHovered:NO];
	}
}

@end


#pragma mark -

@implementation GLAPopUpButtonCell

@synthesize leftSpacing = _leftSpacing;
@synthesize rightSpacing = _rightSpacing;
@synthesize verticalOffsetDown = _verticalOffsetDown;

@synthesize  alwaysHighlighted = _alwaysHighlighted;

@synthesize textHighlightColor = _textHighlightColor;
@synthesize backgroundColor = _backgroundColor;
@synthesize highlightAmount = _highlightAmount;

@synthesize hasPrimaryStyle = _hasPrimaryStyle;
@synthesize hasSecondaryStyle = _hasSecondaryStyle;

@synthesize backgroundInsetXAmount = _backgroundInsetXAmount;
@synthesize backgroundInsetYAmount = _backgroundInsetYAmount;

- (CGFloat)backgroundInsetAmount
{
	return (self.backgroundInsetXAmount);
}

- (void)setBackgroundInsetAmount:(CGFloat)backgroundInsetAmount
{
	(self.backgroundInsetXAmount) = backgroundInsetAmount;
	(self.backgroundInsetYAmount) = backgroundInsetAmount;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
	GLAPopUpButtonCell *copy = [super copyWithZone:zone];
	
	(copy.leftSpacing) = (self.leftSpacing);
	(copy.rightSpacing) = (self.rightSpacing);
	(copy.verticalOffsetDown) = (self.verticalOffsetDown);
	
	(copy.alwaysHighlighted) = (self.alwaysHighlighted);
	
	(copy.textHighlightColor) = (self.textHighlightColor);
	(copy.backgroundColor) = (self.backgroundColor);
	(copy.backgroundInsetAmount) = (self.backgroundInsetAmount);
	(copy.highlightAmount) = (self.highlightAmount);
	
	(copy.hasPrimaryStyle) = (self.hasPrimaryStyle);
	(copy.hasSecondaryStyle) = (self.hasSecondaryStyle);
	
	return copy;
}

- (NSSize)cellSizeForBounds:(NSRect)aRect
{
	NSSize cellSize = [super cellSizeForBounds:aRect];
	cellSize.width += (self.leftSpacing) + (self.rightSpacing);
	return cellSize;
}

- (BOOL)isOnAndShowsOnState
{
	if ((self.state) == NSOnState && (((self.showsStateBy) & NSChangeGrayCellMask) == NSChangeGrayCellMask)) {
		return YES;
	}
	
	return NO;
}

- (void)drawBorderAndBackgroundWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[NSButton GLAStyledCell:self drawBezelWithFrame:cellFrame inView:controlView];
}

- (NSRect)titleRectForBounds:(NSRect)bounds
{
	NSRect titleRect = [super titleRectForBounds:bounds];
	titleRect = [NSButton GLAStyledCell:self adjustTitleRect:titleRect];
	return titleRect;
}

#if 1

- (void)drawTitleWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSCellImagePosition imagePosition = (self.imagePosition);
	if (imagePosition == NSImageOnly) {
		return;
	}
#if 0
	NSString *title = (self.titleOfSelectedItem);
	if (!title) {
		title = (self.title);
	}
	if (!title) {
		return;
	}
#endif
	
	NSAttributedString *attrTitle = (self.attributedTitle);
	attrTitle = [NSButton GLAStyledCell:self adjustAttributedTitle:attrTitle];
	
#if 1
	NSRect adjustedFrame = cellFrame;
	//if (imagePosition == NSImageLeft) {
		adjustedFrame = [self titleRectForBounds:adjustedFrame];
	//}
	
	adjustedFrame.origin.y += (self.verticalOffsetDown);
	
	adjustedFrame.origin.x += (self.leftSpacing);
	
	[super drawTitle:attrTitle withFrame:adjustedFrame inView:controlView];
	//[NSButton GLAStyledCell:self drawTitle:attrTitle withFrame:cellFrame inView:controlView];
#else
	
	NSRange fullRange = NSMakeRange(0, (attrString.length));
	
	NSColor *color = nil;
	
	if (self.isAlwaysHighlighted) {
		color = ([GLAUIStyle activeStyle].activeTextColor);
	}
	else {
		color = ([GLAUIStyle activeStyle].lightTextColor);
	}
	
	[attrString addAttribute:NSForegroundColorAttributeName value:color range:fullRange];
	[attrString addAttribute:NSFontAttributeName value:(self.font) range:fullRange];
	
	//NSRect alignmentRect = [controlView alignmentRectForFrame:cellFrame];
	//cellFrame.origin.y += (controlView.baselineOffsetFromBottom);
	cellFrame = CGRectInset(cellFrame, 10.0, 0.0);
	[attrString drawWithRect:cellFrame options:NSStringDrawingUsesLineFragmentOrigin];
	//[self drawTitle:attrString withFrame:cellFrame inView:controlView];
#endif
}

- (void)drawImageWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSCellImagePosition imagePosition = (self.imagePosition);
	if (imagePosition == NSImageOnly) {
		NSImage *image = (self.image);
		
		NSRect holdingRect = NSInsetRect(cellFrame, (self.backgroundInsetXAmount), (self.backgroundInsetYAmount));
		NSSize imageSize = (image.size);
		// How does the width scale?
		CGFloat widthScale = NSWidth(holdingRect) / imageSize.width;
		// How does the height scale?
		CGFloat heightScale = NSHeight(holdingRect) / imageSize.height;
		// Find the smaller of the two, and clamp to 1.0 so it isn't scaling up at all.
		CGFloat scale = fmin(fmin(widthScale, heightScale), 1.0);
		
		NSSize destSize = NSMakeSize(imageSize.width * scale, imageSize.height * scale);
		NSRect destRect = NSMakeRect
		(
		 (NSWidth(cellFrame) - destSize.width) / 2.0,
		 (NSHeight(cellFrame) - destSize.height) / 2.0,
		 destSize.width,
		 destSize.height
		 );
		
		destRect = [controlView backingAlignedRect:destRect options:NSAlignAllEdgesNearest];
		
		[image drawInRect:destRect];
	}
	else {
		//if (imagePosition == NSImageLeft) {
			(cellFrame.origin.x) += (self.leftSpacing);
		//}
		
		[super drawImageWithFrame:cellFrame inView:controlView];
	}
}

#endif

@end