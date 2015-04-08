//
//  GLAQuickLookPreviewHelper.m
//  Blik
//
//  Created by Patrick Smith on 18/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAQuickLookPreviewHelper.h"


@interface GLAQuickLookPreviewHelper () <QLPreviewPanelDataSource, QLPreviewPanelDelegate>

@property(nonatomic) QLPreviewPanel *activeQuickLookPreviewPanel;

@property(readwrite, nonatomic) NSURL *activeURL;

@end

@implementation GLAQuickLookPreviewHelper

- (void)deactivate
{
	QLPreviewPanel *activeQuickLookPreviewPanel = (self.activeQuickLookPreviewPanel);
	if (activeQuickLookPreviewPanel) {
		(activeQuickLookPreviewPanel.delegate) = nil;
		(activeQuickLookPreviewPanel.dataSource) = nil;
		[activeQuickLookPreviewPanel reloadData];
		
		if (activeQuickLookPreviewPanel.isVisible) {
			[activeQuickLookPreviewPanel orderOut:nil];
		}
	}
	
	QLPreviewView *quickLookPreviewView = (self.quickLookPreviewView);
	if (quickLookPreviewView && (quickLookPreviewView.previewItem) != nil) {
		[quickLookPreviewView close];
	}
}

- (void)dealloc
{
	[self stopObservingPreviewFrameChanges];
	
	[self deactivate];
}

- (void)stopObservingPreviewFrameChanges
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	NSView *previewHolderView = (self.previewHolderView);
	NSWindow *window = (previewHolderView.window);
	[nc removeObserver:self name:NSWindowWillStartLiveResizeNotification object:window];
	[nc removeObserver:self name:NSWindowDidEndLiveResizeNotification object:window];
	[nc removeObserver:self name:NSViewFrameDidChangeNotification object:previewHolderView];
}

- (void)startObservingPreviewFrameChanges
{
	[self stopObservingPreviewFrameChanges];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	NSView *previewHolderView = (self.previewHolderView);
	NSWindow *window = (previewHolderView.window);
	[nc addObserver:self selector:@selector(windowDidStartLiveResize:) name:NSWindowWillStartLiveResizeNotification object:window];
	[nc addObserver:self selector:@selector(windowDidEndLiveResize:) name:NSWindowDidEndLiveResizeNotification object:window];
	[nc addObserver:self selector:@selector(previewFrameDidChange:) name:
	 NSViewFrameDidChangeNotification object:previewHolderView];
}

- (void)windowDidStartLiveResize:(NSNotification *)note
{
	//(self.previewHolderView.animator.alphaValue) = 0.0;
}

- (void)windowDidEndLiveResize:(NSNotification *)note
{
	QLPreviewView *quickLookPreviewView = (self.quickLookPreviewView);
	if (quickLookPreviewView && ![quickLookPreviewView isHiddenOrHasHiddenAncestor]) {
		//[quickLookPreviewView refreshPreviewItem];
	}
	
	//(self.previewHolderView.animator.alphaValue) = 1.0;
}

- (void)previewFrameDidChange:(NSNotification *)note
{
	QLPreviewView *quickLookPreviewView = (self.quickLookPreviewView);
	if (quickLookPreviewView && ![quickLookPreviewView isHiddenOrHasHiddenAncestor]) {
		//[quickLookPreviewView refreshPreviewItem];
	}
}

#pragma mark -

- (NSArray *)selectedURLs
{
	id<GLAQuickLookPreviewHelperDelegate> delegate = (self.delegate);
	if (!delegate) {
		return nil;
	}
	
	return [delegate selectedURLsForQuickLookPreviewHelper:self];
}

- (NSInteger)tableRowForSelectedURL:(NSURL *)fileURL
{
	id<GLAQuickLookPreviewHelperDelegate> delegate = (self.delegate);
	if (!delegate) {
		return -1;
	}
	
	return [delegate quickLookPreviewHelper:self tableRowForSelectedURL:fileURL];
}

- (void)updateQuickLookPreviewAnimating:(BOOL)animate
{
#if DEBUG
	NSLog(@"updateQuickLookPreviewAnimating %@", (self.activeQuickLookPreviewPanel));
#endif
	// PANEL
	if (self.activeQuickLookPreviewPanel) {
		[(self.activeQuickLookPreviewPanel) reloadData];
	}
	
	// PREVIEW
	if (!(self.quickLookPreviewView)) {
		GLAViewController *previewHolderViewController = [[GLAViewController alloc] init];
		NSView *holderView = (self.previewHolderView);
		if (holderView) {
			(holderView.wantsLayer) = YES;
			(holderView.canDrawSubviewsIntoLayer) = YES;
			(previewHolderViewController.view) = holderView;
			
			(self.previewHolderViewController) = previewHolderViewController;
			
			QLPreviewView *quickLookPreviewView = [[QLPreviewView alloc] initWithFrame:NSZeroRect style:QLPreviewViewStyleNormal];
			(quickLookPreviewView.wantsLayer) = YES;
			[previewHolderViewController fillViewWithChildView:quickLookPreviewView];
			(self.quickLookPreviewView) = quickLookPreviewView;
		}
	}
	
	NSArray *selectedURLs = (self.selectedURLs);
#if DEBUG
	NSLog(@"selectedURLs %@", selectedURLs);
#endif
	NSURL *URL = nil;
	
	if ((selectedURLs.count) == 1) {
		URL = selectedURLs[0];
		[self startObservingPreviewFrameChanges];
	}
	
	NSURL *previouslyActiveURL = (self.activeURL);
	if ([previouslyActiveURL isEqual:URL]) {
		return;
	}
	(self.activeURL) = URL;
	
	// Animate preview
	QLPreviewView *quickLookPreviewView = (self.quickLookPreviewView);
	if (quickLookPreviewView) {
		CGFloat alphaValue = (URL != nil) ? 1.0 : 0.0;
		
		@try {
			if (animate) {
				[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
					(context.duration) = 2.0 / 16.0;
					(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
					
					if (URL) {
						(quickLookPreviewView.previewItem) = URL;
					}
					
					quickLookPreviewView.animator.alphaValue = alphaValue;
				} completionHandler:^{
					if (!URL) {
						(quickLookPreviewView.previewItem) = nil;
					}
				}];
			}
			else {
				(quickLookPreviewView.alphaValue) = alphaValue;
				(quickLookPreviewView.previewItem) = URL;
			}
		}
		@catch (NSException *exception) {
			NSLog(@"Quick Look exception %@", exception);
		}
		@finally {
			
		}
	}
}

#pragma mark -

#pragma mark QuickLook

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel
{
	return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
#if DEBUG
	NSLog(@"beginPreviewPanelControl");
#endif
	(panel.delegate) = self;
	(panel.dataSource) = self;
	
	(self.activeQuickLookPreviewPanel) = panel;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
	(panel.delegate) = nil;
	(panel.dataSource) = nil;
	
	(self.activeQuickLookPreviewPanel) = nil;
}

- (void)showQuickLookPanel:(BOOL)show
{
	QLPreviewPanel *qlPanel = [QLPreviewPanel sharedPreviewPanel];
	
	BOOL isCurrentlyShowing = (qlPanel.isVisible);
	if (isCurrentlyShowing == show) {
		return;
	}
	
	if (show) {
		// Only show if there is something selected to show.
		if ((self.selectedURLs.count) == 0) {
			return;
		}
		
		[qlPanel makeKeyAndOrderFront:nil];
	}
	else {
		[qlPanel orderOut:nil];
	}
}

- (IBAction)quickLookPreviewItems:(id)sender
{
	QLPreviewPanel *qlPanel = [QLPreviewPanel sharedPreviewPanel];
	
	if (! qlPanel.isVisible) {
		// Only show if there is something selected to show.
		if ((self.selectedURLs.count) == 0) {
			return;
		}
		
		[qlPanel makeKeyAndOrderFront:nil];
	}
	else {
		[qlPanel orderOut:nil];
	}
}

#pragma QLPreviewPanel Data Source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
	NSArray *selectedURLs = (self.selectedURLs);
	return (selectedURLs.count);
}

- (id<QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
	NSArray *selectedURLs = (self.selectedURLs);
	NSURL *URL = selectedURLs[index];
	return URL;
}

#pragma mark QLPreviewPanel Delegate

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
	if ((event.type) == NSKeyDown) {
		[(self.tableView) keyDown:event];
		return YES;
	}
	
	return NO;
}

- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id<QLPreviewItem>)item
{
	NSInteger rowIndex = [self tableRowForSelectedURL:(NSURL *)item];
	if (rowIndex == -1) {
		return NSZeroRect;
	}
	
	NSTableView *tableView = (self.tableView);
#if 1
	NSTableCellView *cellView = [tableView viewAtColumn:0 row:rowIndex makeIfNecessary:YES];
	NSImageView *imageView = (cellView.imageView);
	NSRect windowSourceRect = [imageView convertRect:(imageView.bounds) toView:nil];
#else
	NSRect itemRect = [tableView rectOfRow:rowIndex];
	
	NSRect windowSourceRect = [tableView convertRect:itemRect toView:nil];
#endif
	
	return [(tableView.window) convertRectToScreen:windowSourceRect];
}

- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id<QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
	NSInteger rowIndex = [self tableRowForSelectedURL:(NSURL *)item];
	if (rowIndex == -1) {
		return nil;
	}
	
	NSTableView *tableView = (self.tableView);
	NSTableCellView *cellView = [tableView viewAtColumn:0 row:rowIndex makeIfNecessary:YES];
	NSImageView *imageView = (cellView.imageView);
	
	return (imageView.image);
}

@end
