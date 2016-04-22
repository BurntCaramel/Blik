//
//  GLATableRowView.m
//  Blik
//
//  Created by Patrick Smith on 17/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLATableProjectRowView.h"
#import "GLAUIStyle.h"


@interface GLATableProjectRowView ()

@property(nonatomic) NSTrackingArea *hoverTrackingArea;
@property(nonatomic) BOOL mouseIsInside;

@end

@implementation GLATableProjectRowView

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		(self.enabled) = YES;
	}
	return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self) {
		(self.enabled) = YES;
	}
	return self;
}

- (void)dealloc
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:NSScrollViewDidLiveScrollNotification object:nil];
}

- (void)updateTrackingAreas
{
	[super updateTrackingAreas];
	
	if (!(self.hoverTrackingArea)) {
		(self.hoverTrackingArea) = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
		[self addTrackingArea:(self.hoverTrackingArea)];
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	NSScrollView *scrollView = self.enclosingScrollView;
	if (scrollView) {
		[nc removeObserver:self name:NSScrollViewDidLiveScrollNotification object:nil];
		[nc addObserver:self selector:@selector(scrollViewDidScroll:) name:NSScrollViewDidLiveScrollNotification object:scrollView];
	}
	
	NSMenu *menu = self.enclosingMenuItem.menu;
	if (menu) {
		[nc removeObserver:self name:NSMenuDidEndTrackingNotification object:nil];
		[nc addObserver:self selector:@selector(menuDidEndTracking:) name:NSMenuDidEndTrackingNotification object:menu];
	}
}

- (void)setMouseIsInside:(BOOL)mouseIsInside
{
	if (_mouseIsInside == mouseIsInside) {
		return;
	}
	
	_mouseIsInside = mouseIsInside;
	
	(self.needsDisplay) = YES;
}

- (void)prepareForReuse
{
	(self.enabled) = YES;
	(self.mouseIsInside) = NO;
	
	[super prepareForReuse];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	(self.mouseIsInside) = YES;
}

- (void)mouseExited:(NSEvent *)theEvent
{
	(self.mouseIsInside) = NO;
}

- (void)checkMouseLocationIsInside
{
	NSPoint mouseLocation = [(self.window) mouseLocationOutsideOfEventStream];
	mouseLocation = [self convertPoint:mouseLocation fromView:nil];
	(self.mouseIsInside) = [self mouse:mouseLocation inRect:[self bounds]];
}

- (void)scrollViewDidScroll:(NSNotification *)note
{
	[self checkMouseLocationIsInside];
}

- (void)menuDidEndTracking:(NSNotification *)note
{
	(self.mouseIsInside) = NO;
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect
{
	[(self.backgroundColor) setFill];
	NSRectFill(dirtyRect);
	
	//[super drawBackgroundInRect:dirtyRect];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	NSMenuItem *enclosingMenuItem = (self.enclosingMenuItem);
		
	if ((self.enabled) && (self.mouseIsInside)) {
		if (enclosingMenuItem) {
			[[NSColor selectedMenuItemColor] setFill];
			NSRectFill(dirtyRect);
		}
		else {
			[(uiStyle.projectTableRowHoverBackgroundColor) setFill];
			NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
		}
	}
	
	if (self.showsDividers) {
		[(uiStyle.projectTableDividerColor) setFill];
		CGRect dividerRect, dividerElseRect;
		CGRectDivide((self.bounds), &dividerRect, &dividerElseRect, 0.5, CGRectMaxYEdge);
		NSRectFillUsingOperation(dividerRect, NSCompositeSourceOver);
	}
}

@end
