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
		(self.layer.delegate) = self;
    }
    return self;
}

- (void)awakeFromNib
{
	if ((self.state) == NSOnState) {
		(self.highlightOpacity) = 1.0;
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
	
	[self setNeedsDisplay:YES];
}

- (CGFloat)rightSpacing
{
	return (self.cell.rightSpacing);
}

- (void)setRightSpacing:(CGFloat)rightSpacing
{
	(self.cell.rightSpacing) = rightSpacing;
	
	[self setNeedsDisplay:YES];
}

- (CGFloat)verticalOffsetDown
{
	return (self.cell.verticalOffsetDown);
}

- (void)setVerticalOffsetDown:(CGFloat)verticalOffsetDown
{
	(self.cell.verticalOffsetDown) = verticalOffsetDown;
	
	[self setNeedsDisplay:YES];
}

- (BOOL)isAlwaysHighlighted
{
	return (self.cell.isAlwaysHighlighted);
}

- (void)setAlwaysHighlighted:(BOOL)alwaysHighlighted
{
	(self.cell.alwaysHighlighted) = alwaysHighlighted;
	
	[self setNeedsDisplay:YES];
}

- (BOOL)isSecondary
{
	return (self.cell.isSecondary);
}

- (void)setSecondary:(BOOL)secondary
{
	(self.cell.secondary) = secondary;
	
	[self setNeedsDisplay:YES];
}

- (NSColor *)textHighlightColor
{
	return (self.cell.textHighlightColor);
}

- (void)setTextHighlightColor:(NSColor *)textHighlightColor
{
	(self.cell.textHighlightColor) = textHighlightColor;
	
	[self setNeedsDisplay:YES];
}

+ (id)defaultAnimationForKey:(NSString *)key
{
	if ([key isEqualToString:@"highlightOpacity"]) {
		return [CABasicAnimation animation];
	}
	else {
		return [super defaultAnimationForKey:key];
	}
}

- (void)setState:(NSInteger)newState
{
	if (newState == NSOffState) {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 3.0 / 36.0;
			(self.animator.highlightOpacity) = 0.0;
		} completionHandler:^{
			
		}];
		
	}
	else if (newState == NSOnState) {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 3.0 / 36.0;
			(self.animator.highlightOpacity) = 1.0;
		} completionHandler:^{
			
		}];
	}
	
	[super setState:newState];
}

- (BOOL)isOnAndShowsOnState
{
	return (self.cell.isOnAndShowsOnState);
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

- (NSRect)titleRectForBounds:(NSRect)theRect
{
	return theRect;
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
	NSMutableAttributedString *coloredTitle = [NSMutableAttributedString new];
	[coloredTitle appendAttributedString:title];
	NSRange entireStringRange = NSMakeRange(0, (coloredTitle.length));
	
	NSColor *color = nil;
	//NSLog(@"mouse %lu", (unsigned long)(self.mouseDownFlags));
	if ((self.isOnAndShowsOnState) || (self.alwaysHighlighted) || (self.textHighlightColor) /*|| ((self.mouseDownFlags & NSMouseEnteredMask) == NSMouseEnteredMask)*/ ) {
		if (self.isEnabled) {
			color = (self.textHighlightColor);
			if (!color) {
				color = ([GLAUIStyle styleA].activeTextColor);
			}
		}
		else {
			color = ([GLAUIStyle styleA].activeTextDisabledColor);
		}
	}
	else {
		if (self.isEnabled) {
			color = ([GLAUIStyle styleA].lightTextColor);
		}
		else {
			color = ([GLAUIStyle styleA].lightTextDisabledColor);
		}
	}
	// Replace text color.
	[coloredTitle addAttribute:NSForegroundColorAttributeName value:color range:entireStringRange];
	
	
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
