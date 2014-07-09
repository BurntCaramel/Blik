//
//  GLAPrototypeBNavigationItem.m
//  Glance Prototype A
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAPrototypeBNavigationItem.h"
#import "GLAUIStyle.h"

@implementation GLAPrototypeBNavigationItem

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		(self.cell) = [GLAPrototypeBNavigationItemCell new];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

+ (Class)cellClass
{
	return [GLAPrototypeBNavigationItemCell class];
}

@end


@implementation GLAPrototypeBNavigationItemCell

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

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	if ((self.isOnAndShowsOnState)) {
		NSRect topBarRect, elseRect;
		NSDivideRect(frame, &topBarRect, &elseRect, 6.0, CGRectMinYEdge);
		
		[([GLAUIStyle styleA].activeBarColor) setFill];
		NSRectFill(topBarRect);
	}
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
	NSMutableAttributedString *coloredTitle = [NSMutableAttributedString new];
	[coloredTitle appendAttributedString:title];
	NSRange entireStringRange = NSMakeRange(0, (coloredTitle.length));
	
	NSColor *color;
	if ((self.isOnAndShowsOnState) || (self.alwaysHighlighted)) {
		color = ([GLAUIStyle styleA].activeTextColor);
	}
	else {
		color = ([GLAUIStyle styleA].lightTextColor);
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