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
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 5.0 / 36.0;
			(self.animator.highlightAmount) = 1.0;
		} completionHandler:nil];
	}
	else if (newState == NSOffState) {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 3.0 / 36.0;
			(self.animator.highlightAmount) = 0.0;
		} completionHandler:nil];
		
	}
	
	[super setState:newState];
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

- (void)mouseEntered:(NSEvent *)theEvent
{
	if ((self.isEnabled) && (self.state) == NSOffState) {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 5.0 / 36.0;
			(self.animator.highlightAmount) = 3.0 / 6.0;
		} completionHandler:nil];
	}
}

- (void)mouseExited:(NSEvent *)theEvent
{
	if ((self.isEnabled) && (self.state) == NSOffState) {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 5.0 / 36.0;
			(self.animator.highlightAmount) = 0.0;
		} completionHandler:nil];
	}
}

- (BOOL)isOnAndShowsOnState
{
	return (self.cell.isOnAndShowsOnState);
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

/*
 - (void)displayLayer:(CALayer *)layer
 {
 
 }
 */
- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

+ (Class)cellClass
{
	return [GLAButtonCell class];
}

@end


@implementation GLAButtonCell

- (instancetype)copyWithZone:(NSZone *)zone
{
	GLAButtonCell *copy = [super copyWithZone:zone];
	
	(copy.leftSpacing) = (self.leftSpacing);
	(copy.rightSpacing) = (self.rightSpacing);
	(copy.verticalOffsetDown) = (self.verticalOffsetDown);
	
	(copy.alwaysHighlighted) = (self.alwaysHighlighted);
	
	(copy.textHighlightColor) = (self.textHighlightColor);
	(copy.backgroundColor) = (self.backgroundColor);
	(copy.highlightAmount) = (self.highlightAmount);
	
	return copy;
}

- (NSSize)cellSizeForBounds:(NSRect)aRect
{
	NSSize cellSize = [super cellSizeForBounds:aRect];
	cellSize.width += (2.0 * 16.0);
	return cellSize;
}

- (BOOL)isOnAndShowsOnState
{
	if ((self.state) == NSOnState && (((self.showsStateBy) & NSChangeGrayCellMask) == NSChangeGrayCellMask)) {
		return YES;
	}
	
	return NO;
}

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
	if (backgroundColor) {
		return backgroundColor;
	}
	
	if (self.hasPrimaryStyle) {
		return (uiStyle.primaryButtonBackgroundColor);
	}
	else if (self.hasSecondaryStyle) {
		return (uiStyle.secondaryButtonBackgroundColor);
	}
	
	return nil;
}

- (NSRect)titleRectForBounds:(NSRect)theRect
{
	return theRect;
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	NSColor *backgroundColor = (self.backgroundColorForDrawing);
	if (backgroundColor) {
		[backgroundColor setFill];
		
		CGFloat backgroundInsetAmount = (self.backgroundInsetAmount);
		CGRect backgroundRect = CGRectInset(frame, backgroundInsetAmount, backgroundInsetAmount);
		[[NSBezierPath bezierPathWithRoundedRect:backgroundRect xRadius:4.0 yRadius:4.0] fill];
	}
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
	NSMutableAttributedString *coloredTitle = [NSMutableAttributedString new];
	[coloredTitle appendAttributedString:title];
	NSRange entireStringRange = NSMakeRange(0, (coloredTitle.length));
	
	NSColor *textColor = (self.textColorForDrawing);
	//NSLog(@"mouse %lu", (unsigned long)(self.mouseDownFlags));
	/*
	if ((self.isOnAndShowsOnState) || (self.alwaysHighlighted) || (self.textHighlightColor)) {
		if (self.isEnabled || (self.alwaysHighlighted)) {
			color = (self.textHighlightColor);
			if (!color) {
				color = ([GLAUIStyle activeStyle].activeTextColor);
			}
		}
		else {
			color = ([GLAUIStyle activeStyle].activeTextDisabledColor);
		}
	}
	else {
		if (self.isEnabled) {
			color = ([GLAUIStyle activeStyle].lightTextColor);
		}
		else {
			color = ([GLAUIStyle activeStyle].lightTextDisabledColor);
		}
	}
	 */
	// Replace text color.
	if (textColor) {
		[coloredTitle addAttribute:NSForegroundColorAttributeName value:textColor range:entireStringRange];
	}
	
	
	NSRect adjustedFrame, adjustedFrameRemainder;
	adjustedFrame = frame;
	NSDivideRect(adjustedFrame, &adjustedFrameRemainder, &adjustedFrame, (self.leftSpacing), NSMinXEdge);
	NSDivideRect(adjustedFrame, &adjustedFrameRemainder, &adjustedFrame, (self.rightSpacing), NSMaxXEdge);
	
	adjustedFrame.origin.y += (self.verticalOffsetDown);
	
	/*
	 NSFont *font = [title attribute:NSFontNameAttribute atIndex:0 effectiveRange:NULL];
	 NSRect verticallyCenteredFrame, verticallyCenteredFrameRemainder;
	 CGFloat frameHeight = NSHeight(frame);
	 CGFloat textHeight = (font.pointSize);
	 NSDivideRect(frame, &verticallyCenteredFrame, &verticallyCenteredFrameRemainder, (frameHeight + textHeight) / 2, NSMinYEdge);
	 NSDivideRect(verticallyCenteredFrame, &verticallyCenteredFrame, &verticallyCenteredFrameRemainder, textHeight, NSMaxYEdge);
	 
	 NSLog(@"VERTICAL ALIGNED FRAME %@, BEFORE %@", NSStringFromRect(verticallyCenteredFrame), NSStringFromRect(frame));
	 */
	// Draw title using super but using our attributed string.
	return [super drawTitle:coloredTitle withFrame:adjustedFrame inView:controlView];
}

@end
