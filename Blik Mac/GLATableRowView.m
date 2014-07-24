//
//  GLATableRowView.m
//  Blik
//
//  Created by Patrick Smith on 17/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLATableRowView.h"
#import "GLAUIStyle.h"


@interface GLATableRowView ()

@property(nonatomic) NSTrackingArea *hoverTrackingArea;
@property(nonatomic) BOOL mouseIsInside;

@end

@implementation GLATableRowView

/*
- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}
 */

- (void)updateTrackingAreas
{
	[super updateTrackingAreas];
	
	if (!(self.hoverTrackingArea)) {
		(self.hoverTrackingArea) = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
		[self addTrackingArea:(self.hoverTrackingArea)];
	}
	
	NSScrollView *scrollView = [self enclosingScrollView];
	if (scrollView) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc removeObserver:self name:nil object:scrollView];
		[nc addObserver:self selector:@selector(scrollViewDidScroll:) name:NSScrollViewDidLiveScrollNotification object:scrollView];
	}
}

- (void)prepareForReuse
{
	(self.mouseIsInside) = NO;
	
	[super prepareForReuse];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	(self.mouseIsInside) = YES;
	
	[self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	(self.mouseIsInside) = NO;
	
	[self setNeedsDisplay:YES];
}

- (void)checkMouseLocationIsInside
{
	NSPoint mouseLocation = [(self.window) mouseLocationOutsideOfEventStream];
	mouseLocation = [self convertPoint:mouseLocation fromView:nil];
	BOOL mouseIsInside = [self mouse:mouseLocation inRect:[self bounds]];
	if (mouseIsInside != (self.mouseIsInside)) {
		(self.mouseIsInside) = mouseIsInside;
		[self setNeedsDisplay:YES];
	}
}

- (void)scrollViewDidScroll:(NSNotification *)note
{
	[self checkMouseLocationIsInside];
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect
{
	[(self.backgroundColor) setFill];
	NSRectFill(dirtyRect);
	
	//[super drawBackgroundInRect:dirtyRect];
	
	if (self.mouseIsInside) {
		GLAUIStyle *uiStyle = [GLAUIStyle styleA];
		[(uiStyle.projectTableRowHoverBackgroundColor) setFill];
		NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
	}
}

@end
