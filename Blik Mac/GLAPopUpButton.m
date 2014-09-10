//
//  GLAPopUpButton.m
//  Blik
//
//  Created by Patrick Smith on 8/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAPopUpButton.h"
#import "GLAUIStyle.h"


@implementation GLAPopUpButton

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
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

- (CGFloat)baselineOffsetFromBottom
{
	return 5.0;
}

- (BOOL)isAlwaysHighlighted
{
	return (self.cell.isAlwaysHighlighted);
}

- (void)setAlwaysHighlighted:(BOOL)alwaysHighlighted
{
	(self.cell.alwaysHighlighted) = alwaysHighlighted;
}

@end


@implementation GLAPopUpButtonCell

- (void)drawTitleWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSString *title = (self.titleOfSelectedItem);
	/*if (!title) {
		return;
	}*/
	
	NSMutableAttributedString *attrString = [NSMutableAttributedString new];
	[(attrString.mutableString) appendString:title];
	
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
}

@end