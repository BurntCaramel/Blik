//
//  GLAButton.m
//  
//
//  Created by Patrick Smith on 14/07/2014.
//
//

@import QuartzCore;
#import "GLAButton.h"
#import "GLAUIStyle.h"
#import "NSColor+GLAExtras.h"


@implementation NSButton (GLAButtonStyling)

+ (NSColor *)backgroundColorForDrawingGLAStyledButton:(NSButtonCell<GLAButtonStyling> *)button highlighted:(BOOL)highlighted
{
	if (!(button.isEnabled)) {
		return nil;
	}
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	NSColor *backgroundColor = (button.backgroundColor);
	if (!backgroundColor) {
		if (button.hasPrimaryStyle) {
			backgroundColor = (uiStyle.primaryButtonBackgroundColor);
		}
		else if (button.hasSecondaryStyle) {
			backgroundColor = (uiStyle.secondaryButtonBackgroundColor);
		}
	}
	
	if (backgroundColor) {
		CGFloat highlightAmount = (button.highlightAmount);
		
		if (highlighted || (highlightAmount > 0.0)) {
			NSColor *highlightColor = [NSColor gla_colorWithSRGBGray:1.0 alpha:fmin(( backgroundColor.alphaComponent) * 10.0, 1.0 )];
			CGFloat highlightColorFraction = ( 2.2 / 16.0 ) * highlightAmount;
			
			if (button.hasPrimaryStyle) {
				highlightColorFraction *= 2.2;
			}
			
			return [backgroundColor blendedColorWithFraction:highlightColorFraction ofColor:highlightColor];
		}
		else {
			return backgroundColor;
		}
	}
	
	return nil;
}

+ (NSColor *)textColorForDrawingGLAStyledButton:(NSButtonCell<GLAButtonStyling> *)button
{
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	if (!(button.isEnabled)) {
		return (uiStyle.lightTextDisabledColor);
	}
	else if ((button.isOnAndShowsOnState) || (button.alwaysHighlighted) || (button.textHighlightColor) /*|| ((button.mouseDownFlags & NSMouseEnteredMask) == NSMouseEnteredMask)*/ ) {
		if ((button.isEnabled) || (button.alwaysHighlighted)) {
			NSColor *color = (button.textHighlightColor);
			if (color) {
				return color;
			}
			
			return (uiStyle.activeTextColor);
		}
		else {
			return (uiStyle.activeTextDisabledColor);
		}
	}
	else if (button.hasPrimaryStyle) {
		return (uiStyle.primaryButtonTextColor);
	}
	else if (button.hasSecondaryStyle) {
		return (uiStyle.secondaryButtonTextColor);
	}
	else {
		return (uiStyle.lightTextColor);
	}
}

+ (void)GLAStyledCell:(NSButtonCell<GLAButtonStyling> *)buttonCell drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	[self GLAStyledCell:buttonCell drawBezelWithFrame:frame inView:controlView highlighted:NO];
}

+ (void)GLAStyledCell:(NSButtonCell<GLAButtonStyling> *)buttonCell drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView highlighted:(BOOL)highlighted
{
	//NSLog(@"HIGHGHGH %@", @(buttonCell.isHighlighted));
	NSColor *backgroundColor = [self backgroundColorForDrawingGLAStyledButton:buttonCell highlighted:highlighted];
	
	if (backgroundColor) {
		CGFloat backgroundInsetXAmount = (buttonCell.backgroundInsetXAmount);
		CGFloat backgroundInsetYAmount = (buttonCell.backgroundInsetYAmount);
		CGRect backgroundRect = CGRectInset(frame, backgroundInsetXAmount, backgroundInsetYAmount);
		
		[backgroundColor setFill];
		NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:backgroundRect xRadius:4.0 yRadius:4.0];
		[bezierPath fill];
	}
}

+ (NSRect)GLAStyledCell:(NSButtonCell<GLAButtonStyling> *)buttonCell adjustTitleRect:(NSRect)titleRect
{
#if 0
	NSRect remainder;
	
	NSDivideRect(titleRect, &remainder, &titleRect, (buttonCell.leftSpacing), NSMinXEdge);
	NSDivideRect(titleRect, &remainder, &titleRect, (buttonCell.rightSpacing), NSMaxXEdge);
#endif
	
	titleRect.origin.y += (buttonCell.verticalOffsetDown);
	
	return titleRect;
}

+ (NSAttributedString *)GLAStyledCell:(NSButtonCell<GLAButtonStyling> *)buttonCell adjustAttributedTitle:(NSAttributedString *)title
{
	NSMutableAttributedString *coloredTitle = [NSMutableAttributedString new];
	[coloredTitle appendAttributedString:title];
	NSRange entireStringRange = NSMakeRange(0, (coloredTitle.length));
	
	NSColor *textColor = [self textColorForDrawingGLAStyledButton:buttonCell];
	// Replace text color.
	if (textColor) {
		[coloredTitle addAttribute:NSForegroundColorAttributeName value:textColor range:entireStringRange];
	}
	
	return coloredTitle;
}

+ (NSRect)GLAStyledCell:(NSButtonCell<GLAButtonStyling> *)buttonCell drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
	NSMutableAttributedString *coloredTitle = [NSMutableAttributedString new];
	[coloredTitle appendAttributedString:title];
	NSRange entireStringRange = NSMakeRange(0, (coloredTitle.length));
	
	NSColor *textColor = [self textColorForDrawingGLAStyledButton:buttonCell];
	// Replace text color.
	if (textColor) {
		[coloredTitle addAttribute:NSForegroundColorAttributeName value:textColor range:entireStringRange];
	}
	
	//NSRect adjustedFrame = [buttonCell titleRectForBounds:frame];
	NSRect adjustedFrame = frame;
	
	[title drawWithRect:adjustedFrame options:0];
	
	return adjustedFrame;
}

- (void)gla_animateHighlightTo:(CGFloat)highlightAmount
{
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 36.0;
		id<GLAButtonStyling> animator = (id)(self.animator);
		(animator.highlightAmount) = highlightAmount;
	} completionHandler:nil];
}

- (void)gla_animateHighlightForHovered:(BOOL)hovered
{
	CGFloat highlightAmount = hovered ? (3.0 / 6.0) : 0.0;
	[self gla_animateHighlightTo:highlightAmount];
}

- (void)gla_animateHighlightForPressed:(BOOL)pressed
{
	CGFloat highlightAmount = pressed ? (3.0 / 6.0) : 0.0;
	[self gla_animateHighlightTo:highlightAmount];
}

- (void)gla_animateHighlightForOn:(BOOL)on
{
	CGFloat highlightAmount = on ? (6.0 / 6.0) : 0.0;
	[self gla_animateHighlightTo:highlightAmount];
}

@end


@interface GLAButton ()

@property(nonatomic) NSTrackingArea *mainTrackingArea;

@end

@implementation GLAButton

/*+ (BOOL)requiresConstraintBasedLayout
 {
 return YES;
 }*/

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		(self.cell) = [GLAButtonCell new];
		//(self.layer.delegate) = self;
    }
    return self;
}

- (void)awakeFromNib
{
	if ((self.state) == NSOnState) {
		(self.highlightAmount) = 1.0;
	}
}

- (GLAButtonCell *)cell
{
	return [super cell];
}

- (void)setCell:(GLAButtonCell *)cell
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

#pragma mark -

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

- (void)updateTrackingAreas
{
	if (self.mainTrackingArea) {
		[self removeTrackingArea:(self.mainTrackingArea)];
	}
	
	NSTrackingArea *mainTrackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
	[self addTrackingArea:mainTrackingArea];
	(self.mainTrackingArea) = mainTrackingArea;
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

+ (Class)cellClass
{
	return [GLAButtonCell class];
}

@end


@implementation GLAButtonCell

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
	GLAButtonCell *copy = [super copyWithZone:zone];
	
	(copy.leftSpacing) = (self.leftSpacing);
	(copy.rightSpacing) = (self.rightSpacing);
	(copy.verticalOffsetDown) = (self.verticalOffsetDown);
	
	(copy.alwaysHighlighted) = (self.alwaysHighlighted);
	
	(copy.textHighlightColor) = (self.textHighlightColor);
	(copy.backgroundColor) = (self.backgroundColor);
	(copy.backgroundInsetXAmount) = (self.backgroundInsetXAmount);
	(copy.backgroundInsetYAmount) = (self.backgroundInsetYAmount);
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

#if 0
- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
{
	return [super startTrackingAt:startPoint inView:controlView];
	
	//return NO;
}
#endif

- (NSColor *)textColorForDrawing
{
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	if (!(self.isEnabled)) {
		return (uiStyle.lightTextDisabledColor);
	}
	else if ((self.isOnAndShowsOnState) || (self.alwaysHighlighted) || (self.textHighlightColor) /*|| ((self.mouseDownFlags & NSMouseEnteredMask) == NSMouseEnteredMask)*/ ) {
		if ((self.isEnabled) || (self.alwaysHighlighted)) {
			NSColor *color = (self.textHighlightColor);
			if (color) {
				return color;
			}
			
			return (uiStyle.activeTextColor);
		}
		else {
			return (uiStyle.activeTextDisabledColor);
		}
	}
	else if (self.hasPrimaryStyle) {
		return (uiStyle.primaryButtonTextColor);
	}
	else if (self.hasSecondaryStyle) {
		return (uiStyle.secondaryButtonTextColor);
	}
	else {
		return (uiStyle.lightTextColor);
	}
	
	return nil;
}

- (NSColor *)backgroundColorForDrawing
{
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	NSColor *backgroundColor = (self.backgroundColor);
	if (!backgroundColor) {
		if (self.hasPrimaryStyle) {
			backgroundColor = (uiStyle.primaryButtonBackgroundColor);
		}
		else if (self.hasSecondaryStyle) {
			backgroundColor = (uiStyle.secondaryButtonBackgroundColor);
		}
	}
	
	if (backgroundColor) {
		/*NSLog(@"%@ MOUSE DOWN FLAGS", @(self.mouseDownFlags));
		if ((self.mouseDownFlags) & NSLeftMouseDownMask) {
			backgroundColor = [backgroundColor colorWithAlphaComponent:0.7];
		}*/
		
		if (!(self.isEnabled)) {
			return nil;
			//return [backgroundColor colorWithAlphaComponent:(backgroundColor.alphaComponent) * 0.12];
		}
		else {
			return backgroundColor;
		}
	}
	
	return nil;
}

- (NSRect)titleRectForBounds:(NSRect)bounds
{
	NSRect titleRect = [super titleRectForBounds:bounds];
	titleRect = [NSButton GLAStyledCell:self adjustTitleRect:titleRect];
	return titleRect;
}

/*- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSLog(@"STATE %@", @(self.state));
}*/

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	//BOOL isHighlighted = [self cellAttribute:NSCellHighlighted];
	//NSLog(@"b STATE %@ %@ %@", @(self.state), @(isHighlighted), @(self.mouseDownFlags));
#if 1
	[NSButton GLAStyledCell:self drawBezelWithFrame:frame inView:controlView];
#else
	NSColor *backgroundColor = (self.backgroundColorForDrawing);
	if (backgroundColor) {
		[backgroundColor setFill];
		
		CGFloat backgroundInsetAmount = (self.backgroundInsetAmount);
		CGRect backgroundRect = CGRectInset(frame, backgroundInsetAmount, backgroundInsetAmount);
		[[NSBezierPath bezierPathWithRoundedRect:backgroundRect xRadius:4.0 yRadius:4.0] fill];
	}
#endif
}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	//BOOL isHighlighted = [self cellAttribute:NSCellHighlighted];
	//NSLog(@"h STATE %@ %@ %@", @(self.state), @(isHighlighted), @(flag));
	
	//[controlView setNeedsDisplayInRect:cellFrame];
	//[controlView displayRect:cellFrame];
	
	[NSButton GLAStyledCell:self drawBezelWithFrame:cellFrame inView:controlView highlighted:flag];
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
#if 0
	return [NSButton GLAStyledCell:self drawTitle:title withFrame:frame inView:controlView];
#else
	title = [NSButton GLAStyledCell:self adjustAttributedTitle:title];
	/*
	NSMutableAttributedString *coloredTitle = [NSMutableAttributedString new];
	[coloredTitle appendAttributedString:title];
	NSRange entireStringRange = NSMakeRange(0, (coloredTitle.length));
	
	NSColor *textColor = (self.textColorForDrawing);
	// Replace text color.
	if (textColor) {
		[coloredTitle addAttribute:NSForegroundColorAttributeName value:textColor range:entireStringRange];
	}*/
	
#if 1
	NSRect adjustedFrame = frame;
	//adjustedFrame.origin.y += (self.verticalOffsetDown);
#else
	NSRect adjustedFrame = [self titleRectForBounds:frame];
#endif
	/*
	NSRect adjustedFrame, adjustedFrameRemainder;
	adjustedFrame = frame;
	NSDivideRect(adjustedFrame, &adjustedFrameRemainder, &adjustedFrame, (self.leftSpacing), NSMinXEdge);
	NSDivideRect(adjustedFrame, &adjustedFrameRemainder, &adjustedFrame, (self.rightSpacing), NSMaxXEdge);
	
	adjustedFrame.origin.y += (self.verticalOffsetDown);
	*/
#if 0
	[coloredTitle drawWithRect:adjustedFrame options:0];
	
	return adjustedFrame;
#else
	
	// Draw title using super but using our attributed string.
	return [super drawTitle:title withFrame:adjustedFrame inView:controlView];
#endif
#endif
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
	NSLog(@"STOP TRACKKING");
	[((GLAButton *)controlView) gla_animateHighlightForPressed:NO];
	
	[super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
}

@end
