//
//  GLASegmentedControl.m
//  Blik
//
//  Created by Patrick Smith on 1/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLASegmentedControl.h"
#import "GLAUIStyle.h"


@implementation GLASegmentedCell

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

- (BOOL)isOnAndShowsOnState
{
	return NO;
}

#if 1

- (NSBackgroundStyle)interiorBackgroundStyleForSegment:(NSInteger)segment
{
	BOOL isSelected = [self isSelectedForSegment:segment];
	if (isSelected) {
		return NSBackgroundStyleLight;
	}
	else {
		return NSBackgroundStyleDark;
	}
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	NSColor *offBackgroundColor = (style.secondaryButtonBackgroundColor);
	NSColor *onBackgroundColor = (style.secondaryButtonTextColor);
	
	NSRect segmentFrame = cellFrame;
	segmentFrame.size.width = 0;
	
	CGFloat backgroundInsetXAmount = (self.backgroundInsetXAmount);
	CGFloat backgroundInsetYAmount = (self.backgroundInsetYAmount);
	CGRect backgroundRect = CGRectInset(cellFrame, backgroundInsetXAmount, backgroundInsetYAmount);
	
	NSEdgeInsets alignmentRectInsets = controlView.alignmentRectInsets;
	backgroundRect.origin.y += alignmentRectInsets.top;
	backgroundRect.size.height -= alignmentRectInsets.top + alignmentRectInsets.bottom;
	backgroundRect.origin.x += alignmentRectInsets.left;
	backgroundRect.size.width -= alignmentRectInsets.left + alignmentRectInsets.right;
	
	NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:backgroundRect xRadius:4.0 yRadius:4.0];
	
	NSArray *accessibilityChildren = [self accessibilityChildren];
	
	for (NSInteger segment = 0; segment < (self.segmentCount); segment++) {
		[NSGraphicsContext saveGraphicsState];
		
		id<NSAccessibilityElement> accessibilitySegment = accessibilityChildren[segment];
		//segmentFrame = (accessibilitySegment.accessibilityFrame);
		
		segmentFrame.origin.x += segmentFrame.size.width;
		//segmentFrame.size.width = [self widthForSegment:segment];
		segmentFrame.size.width = NSWidth(accessibilitySegment.accessibilityFrame);
		
		BOOL isSelected = [self isSelectedForSegment:segment];
		NSColor *backgroundColor = isSelected ? onBackgroundColor : offBackgroundColor;
		
		NSRectClip(segmentFrame);
		[backgroundColor setFill];
		[bezierPath fill];
		
		//[self accessibilitySizeOfChild]
		
		[NSGraphicsContext restoreGraphicsState];
	}
	
	
	// Standard system inset of 3.0
	CGRect standardInsetCellFrame = CGRectInset(cellFrame, 3.0, 3.0);
	// Specified adjustment for text (for making non-system fonts look right)
	standardInsetCellFrame = CGRectOffset(standardInsetCellFrame, 0.0, (self.verticalOffsetDown));
	
	[self drawInteriorWithFrame:standardInsetCellFrame inView:controlView];
}

#endif

#if 0
- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSView *)controlView
{
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	NSColor *textColor = (style.secondaryButtonTextColor);
	
	[NSGraphicsContext saveGraphicsState];
	
	NSRectClip(frame);
	[NSButton GLAStyledCell:self drawBezelWithFrame:(controlView.bounds) inView:controlView];
	
	NSString *label = [self labelForSegment:segment];
	NSAttributedString *attributedLabel = [[NSAttributedString alloc] initWithString:label attributes:
	@{
	  NSFontAttributeName: (self.font),
	  NSForegroundColorAttributeName: textColor
	  }];
	
	[NSButton GLAStyledCell:self drawTitle:attributedLabel withFrame:frame inView:controlView];
	
	[NSGraphicsContext restoreGraphicsState];
}
#endif

@end


@implementation GLASegmentedControl

+ (Class)cellClass
{
	return [GLASegmentedCell class];
}

- (GLASegmentedCell *)cell
{
	return [super cell];
}

- (void)setCell:(GLASegmentedCell *)cell
{
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

- (NSRect)insetBounds
{
	return [NSButton insetBoundsForGLAStyledCell:(self.cell) withBounds:(self.bounds) inView:self];
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

@end
