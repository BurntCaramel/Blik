//
//  GLAQuickLookPreviewHelper.m
//  Blik
//
//  Created by Patrick Smith on 18/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAQuickLookPreviewHelper.h"
#import "Blik-Swift.h"


@interface GLAQuickLookPreviewHelper () <QLPreviewPanelDataSource, QLPreviewPanelDelegate, GLAFolderContentsAssisting>

@property(nonatomic) QLPreviewPanel *activeQuickLookPreviewPanel;

@property(nonatomic) GLAFolderContentsViewController *folderContentsViewController;

@property(readwrite, nonatomic) NSURL *activeURL;
@property(nonatomic) BOOL previewingDirectory;

@property(nonatomic) NSResponder *previousFirstResponder;

@end

@implementation GLAQuickLookPreviewHelper

- (void)setPreviewHolderView:(NSView *)previewHolderView
{
	NSParameterAssert(previewHolderView != nil);
	
	_previewHolderView = previewHolderView;
	
	GLAViewController *previewHolderViewController = [[GLAViewController alloc] initWithNibName:nil bundle:nil];
	(previewHolderViewController.view) = previewHolderView;
	
	(self.previewHolderViewController) = previewHolderViewController;
}

- (void)firstResponderDidChange
{
	QLPreviewPanel *activeQuickLookPreviewPanel = (self.activeQuickLookPreviewPanel);
	if (activeQuickLookPreviewPanel) {
		[activeQuickLookPreviewPanel updateController];
	}
}

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

- (NSURL *)activeURLForDirectoryPreviewing
{
	if (self.previewingDirectory) {
		return (self.activeURL);
	}
	else {
		return nil;
	}
}

- (NSURL *)activeURLForFilePreviewing
{
	if (! self.previewingDirectory) {
		return (self.activeURL);
	}
	else {
		return nil;
	}
}

- (BOOL)folderContentsIsFirstResponder
{
	if (self.previewingDirectory) {
		GLAFolderContentsViewController *folderContentsViewController = (self.folderContentsViewController);
		if (folderContentsViewController.hasFirstResponder) {
			return YES;
		}
	}
	
	return NO;
}

- (NSArray * __nullable)folderContentsSelectedURLsOnlyIfFirstResponder:(BOOL)onlyIfFirstResponder;
{
	if (self.previewingDirectory) {
		GLAFolderContentsViewController *folderContentsViewController = (self.folderContentsViewController);
		if (folderContentsViewController.hasFirstResponder) {
			return (folderContentsViewController.selectedURLs);
		}
	}
	
	return nil;
}

- (void)fadePreviewView:(NSView *)view fadeIn:(BOOL)fadeInNotOut animating:(BOOL)animate updateBlock:(dispatch_block_t)updateBlock
{
	if (!(view.superview)) {
		[(self.previewHolderViewController) fillViewWithChildView:view];
	}
	
	CGFloat alphaValue = fadeInNotOut ? 1.0 : 0.0;
	
	if (animate) {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 2.0 / 16.0;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
			
			if (fadeInNotOut) {
				updateBlock();
			}
			
			view.animator.alphaValue = alphaValue;
		} completionHandler:^{
			// If fading out, only update once the animation is over.
			if (!fadeInNotOut) {
				updateBlock();
				
				[view removeFromSuperview];
			}
		}];
	}
	else {
		(view.alphaValue) = alphaValue;
		
		updateBlock();
		
		if (!fadeInNotOut) {
			[view removeFromSuperview];
		}
	}
}

- (void)updateQuickLookPreviewViewAnimating:(BOOL)animate
{
	NSURL *URL = (self.activeURLForFilePreviewing);
	
	QLPreviewView *quickLookPreviewView = (self.quickLookPreviewView);
	if (!quickLookPreviewView) {
		if (!URL) {
			return;
		}
		
		quickLookPreviewView = [[QLPreviewView alloc] initWithFrame:NSZeroRect style:QLPreviewViewStyleNormal];
		(self.quickLookPreviewView) = quickLookPreviewView;
	}
	
#if 1
	[self fadePreviewView:quickLookPreviewView fadeIn:(URL != nil) animating:animate updateBlock:^{
		@try {
			(quickLookPreviewView.previewItem) = URL;
		}
		@catch (NSException *exception) {
			NSLog(@"Quick Look exception %@", exception);
		}
	}];
#else
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
#endif
}

- (void)updateFolderContentsViewAnimating:(BOOL)animate
{
	NSURL *URL = (self.activeURLForDirectoryPreviewing);
	
	GLAFolderContentsViewController *folderContentsViewController = (self.folderContentsViewController);
	if (!folderContentsViewController) {
		if (!URL) {
			return;
		}
		
		folderContentsViewController = [GLAFolderContentsViewController new];
		(folderContentsViewController.assistant) = self;
		(self.folderContentsViewController) = folderContentsViewController;
	}
	
	[self fadePreviewView:(folderContentsViewController.view) fadeIn:(URL != nil) animating:animate updateBlock:^{
		(folderContentsViewController.sourceDirectoryURL) = URL;
	}];
}

- (void)updatePreviewAnimating:(BOOL)animate
{
#if DEBUG
	//NSLog(@"updateQuickLookPreviewAnimating %@", (self.activeQuickLookPreviewPanel));
#endif
	
	// PANEL
	if (self.activeQuickLookPreviewPanel) {
		QLPreviewPanel *panel = (self.activeQuickLookPreviewPanel);
		//[panel updateController];
		[panel reloadData];
	}
	
#if 0
	// PREVIEW
	if (!(self.quickLookPreviewView)) {
		GLAViewController *previewHolderViewController = [[GLAViewController alloc] init];
		NSView *holderView = (self.previewHolderView);
		if (holderView) {
			//(holderView.wantsLayer) = YES;
			//(holderView.canDrawSubviewsIntoLayer) = YES;
			(previewHolderViewController.view) = holderView;
			
			(self.previewHolderViewController) = previewHolderViewController;
			
			QLPreviewView *quickLookPreviewView = [[QLPreviewView alloc] initWithFrame:NSZeroRect style:QLPreviewViewStyleNormal];
			//(quickLookPreviewView.wantsLayer) = YES;
			[previewHolderViewController fillViewWithChildView:quickLookPreviewView];
			(self.quickLookPreviewView) = quickLookPreviewView;
		}
	}
#endif
	
	NSArray *selectedURLs = (self.selectedURLs);
	NSURL *URL = nil;
	
	if ((selectedURLs.count) == 1) {
		URL = selectedURLs[0];
	}
	
	if (URL) {
		NSURL *previouslyActiveURL = (self.activeURL);
		if ([URL isEqual:previouslyActiveURL]) {
			return;
		}
		
		[self startObservingPreviewFrameChanges];
	}
	(self.activeURL) = URL;
	
	if (URL) {
		__weak GLAQuickLookPreviewHelper *weakSelf = self;
		dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(backgroundQueue, ^{
			NSError *error = nil;
			NSDictionary *values = [URL resourceValuesForKeys:@[NSURLIsDirectoryKey, NSURLIsPackageKey] error:&error];
			
			if (values) {
				BOOL isDirectory = [@YES isEqual:values[NSURLIsDirectoryKey]];
				BOOL isPackage = [@YES isEqual:values[NSURLIsPackageKey]];
				
				[[NSOperationQueue mainQueue] addOperationWithBlock:^{
					__strong GLAQuickLookPreviewHelper *self = weakSelf;
					if (!self) {
						return;
					}
					
					BOOL previewingDirectory = (isDirectory && !isPackage);
					(self.previewingDirectory) = previewingDirectory;
					
					[self updateFolderContentsViewAnimating:animate];
					[self updateQuickLookPreviewViewAnimating:animate];
				}];
			}
			else {
				(self.activeURL) = nil;
				[self updateQuickLookPreviewViewAnimating:animate];
				[self updateFolderContentsViewAnimating:animate];
			}
		});
	}
	else {
		[self updateQuickLookPreviewViewAnimating:animate];
		[self updateFolderContentsViewAnimating:animate];
	}
}

#pragma mark -

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	id<GLAFolderContentsAssisting> folderContentsAssistant = (self.folderContentsAssistant);
	if (folderContentsAssistant) {
		NSProtocolChecker *assistantChecker = [NSProtocolChecker protocolCheckerWithTarget:folderContentsAssistant protocol:@protocol(GLAFolderContentsAssisting)];
		if ([assistantChecker respondsToSelector:aSelector]) {
			return assistantChecker;
		}
	}
	
	return [super forwardingTargetForSelector:aSelector];
}

#if 0
- (void)folderContentsSelectionDidChange
{
	id<GLAFolderContentsAssisting> folderContentsAssistant = (self.folderContentsAssistant);
	if (folderContentsAssistant) {
		[folderContentsAssistant folderContentsSelectionDidChange];
	}
}

- (BOOL)fileURLsAreAllCollected:(NSArray * __nonnull)fileURLs
{
	id<GLAFolderContentsAssisting> folderContentsAssistant = (self.folderContentsAssistant);
	if (folderContentsAssistant) {
		return [folderContentsAssistant fileURLsAreAllCollected:fileURLs];
	}
	
	return NO;
}

- (void)addFileURLsToCollection:(NSArray * __nonnull)fileURLs
{
	id<GLAFolderContentsAssisting> folderContentsAssistant = (self.folderContentsAssistant);
	if (folderContentsAssistant) {
		[folderContentsAssistant addFileURLsToCollection:fileURLs];
	}
}

- (void)removeFileURLsFromCollection:(NSArray * __nonnull)fileURLs
{
	id<GLAFolderContentsAssisting> folderContentsAssistant = (self.folderContentsAssistant);
	if (folderContentsAssistant) {
		[folderContentsAssistant removeFileURLsFromCollection:fileURLs];
	}
}
#endif

#pragma mark - QuickLook

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

#pragma mark QLPreviewPanel Data Source

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
		[(self.sourceTableView) keyDown:event];
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
	
	NSTableView *tableView = (self.sourceTableView);
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
	
	NSTableView *tableView = (self.sourceTableView);
	NSTableCellView *cellView = [tableView viewAtColumn:0 row:rowIndex makeIfNecessary:YES];
	NSImageView *imageView = (cellView.imageView);
	
	return (imageView.image);
}

@end
