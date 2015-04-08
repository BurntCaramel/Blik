//
//  GLACollectedFilePreviewView.m
//  Blik
//
//  Created by Patrick Smith on 27/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLACollectedFilePreviewView.h"
#import "GLAAccessedFileInfo.h"


@interface GLACollectedFilePreviewView ()

@property(nonatomic) GLAAccessedFileInfo *accessedFile;

@property(nonatomic) CGImageRef contentImage;
@property(nonatomic) CGFloat contentImageBackingScale;
@property(nonatomic) BOOL wantsNewPreviewImage;

@end

@implementation GLACollectedFilePreviewView

- (CGFloat)initialContentScale
{
	return 0.5;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self) {
		_contentScale = (self.initialContentScale);
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		_contentScale = (self.initialContentScale);
	}
	return self;
}

- (void)setFileURL:(NSURL *)fileURL
{
	if (_fileURL != nil && fileURL != nil && [_fileURL isEqual:fileURL]) {
		return;
	}
	
	if (fileURL) {
		fileURL = [fileURL copy];
		_fileURL = fileURL;
		(self.accessedFile) = [[GLAAccessedFileInfo alloc] initWithFileURL:fileURL];
	}
	else {
		_fileURL = nil;
		(self.accessedFile) = nil;
	}
	
	[self invalidatePreview];
}

- (void)setContentScale:(CGFloat)contentScale
{
	_contentScale = fmin(fmax(contentScale, 0.25), 1.0);
	
	[self invalidatePreview];
}

- (void)setContentImage:(CGImageRef)contentImage
{
	if (_contentImage) {
		CGImageRelease(_contentImage);
		_contentImage = nil;
	}
	
	if (contentImage) {
		_contentImage = CGImageRetain(contentImage);
		
		[self invalidateIntrinsicContentSize];
	}
}

- (void)invalidatePreview
{
	//(self.contentImage) = nil;
	(self.wantsNewPreviewImage) = YES;
	(self.needsDisplay) = YES;
}

- (BOOL)wantsUpdateLayer
{
	// More efficient to return no, as -drawRect: only draws when
	// view is actually visible, where -updateLayer won't check.
	return NO;
}

- (BOOL)wantsDefaultClipping
{
	// Uses layer only, so can return no as an optimisation.
	return NO;
}

+ (BOOL)isCompatibleWithResponsiveScrolling
{
	return YES;
}

- (BOOL)canDrawConcurrently
{
	return YES;
}

- (NSSize)intrinsicContentSize
{
	NSSize maxSize = NSMakeSize(10000.0, 10000.0);
	NSScrollView *scrollView = (self.enclosingScrollView);
	if (scrollView) {
		maxSize = (scrollView.documentVisibleRect.size);
	}
	
	NSSize contentSize;
	
	CGImageRef contentImage = (self.contentImage);
	if (contentImage) {
		NSSize imageSize = NSMakeSize((CGFloat)CGImageGetWidth(contentImage), (CGFloat)CGImageGetHeight(contentImage));
		
		CGFloat contentImageBackingScale = (self.contentImageBackingScale);
		imageSize.width /= contentImageBackingScale;
		imageSize.height /= contentImageBackingScale;
		
		NSLog(@"intrinsicContentSize use iamge size");
		contentSize = imageSize;
	}
	else {
		NSLog(@"intrinsicContentSize use no size");
		contentSize = NSMakeSize(maxSize.width, 50.0);
		//return NSMakeSize(NSViewNoInstrinsicMetric, NSViewNoInstrinsicMetric);
	}
	
	contentSize = NSMakeSize(fmax(maxSize.width, contentSize.width), fmin(maxSize.height, contentSize.height));
	
	return contentSize;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[self updateLayer];
}

- (void)prepareContentInRect:(NSRect)rect
{
	[super prepareContentInRect:rect];
	
	[self updateLayer];
}

+ (dispatch_queue_t)backgroundDispatchQueue
{
	static dispatch_queue_t backgroundDispatchQueue;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		backgroundDispatchQueue = dispatch_queue_create("GLACollectedFilePreviewView.previewImageQueue", DISPATCH_QUEUE_SERIAL);
	});
	
	return backgroundDispatchQueue;
}

- (void)updateLayer
{
	CALayer *layer = (self.layer);
	
	GLAAccessedFileInfo *accessedFile = (self.accessedFile);
	if (!accessedFile) {
		(layer.contents) = nil;
		return;
	}
	
	if (self.wantsNewPreviewImage) {
		(self.wantsNewPreviewImage) = NO;
	}
	else if (self.contentImage) {
		return;
	}
	
	//NSURL *fileURL = (self.fileURL);
	
	//NSView *superview = (self.superview);
	NSView *superview = (self.enclosingScrollView);
	CGFloat previewWidth = NSWidth(superview.frame) * (self.contentScale);
	//CGFloat previewWidth = NSWidth(self.bounds) * (self.contentScale);
	CGFloat previewHeight = previewWidth;
	
	CGFloat backingScaleFactor = (self.window.backingScaleFactor);
	
	dispatch_queue_t backgroundDispatchQueue = (self.class.backgroundDispatchQueue);
	//dispatch_queue_t backgroundDispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	__weak GLACollectedFilePreviewView *weakSelf = self;
	
	dispatch_async(backgroundDispatchQueue, ^{
		NSURL *fileURL = (accessedFile.filePathURL);
		
		CGImageRef image = QLThumbnailImageCreate
		(kCFAllocatorDefault,
		 (__bridge CFURLRef)fileURL,
		 CGSizeMake(previewWidth, previewHeight),
		 (__bridge CFDictionaryRef)
		 @{
		   (id)kQLThumbnailOptionScaleFactorKey: @(backingScaleFactor)
		   }
		 );
		//NSLog(@"CREATED IMAGE %@", image);
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			__strong GLACollectedFilePreviewView *strongSelf = weakSelf;
			if (!strongSelf) {
				return;
			}
			
			(strongSelf.contentImage) = image;
			(strongSelf.contentImageBackingScale) = backingScaleFactor;
			
			//(layer.backgroundColor) = [NSColor whiteColor].CGColor;
			(layer.contents) = (__bridge id)image;
			(layer.contentsScale) = backingScaleFactor;
			//(layer.contentsGravity) = kCAGravityCenter;
			(layer.contentsGravity) = kCAGravityResizeAspect;
			
			CGImageRelease(image);
		}];
	});
}

- (NSViewLayerContentsRedrawPolicy)layerContentsRedrawPolicy
{
	//return NSViewLayerContentsRedrawBeforeViewResize;
	return NSViewLayerContentsRedrawOnSetNeedsDisplay;
	//return NSViewLayerContentsRedrawCrossfade;
}

/*
- (void)viewWillStartLiveResize
{
	
}
*/
- (void)viewDidEndLiveResize
{
	[self invalidatePreview];
	[self intrinsicContentSize];
}

#if 0
- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint locationInSuperview = [(self.superview) convertPoint:[theEvent locationInWindow] fromView:nil];
	// Require receiver to have been clicked.
	if ([self hitTest:locationInSuperview] != self) {
		return;
	}
	
	
	// Center image in scroll view
	
	NSRect visibleRect = (self.visibleRect);
	visibleRect.size.height = 1.0;
	
	if (visibleRect.origin.y > 0) {
		visibleRect.origin.y = 0.0;
	}
	else {
		visibleRect.origin.y = NSHeight(self.bounds);
	}
	
	// FIXME: doesn't animate
	[self scrollRectToVisible:visibleRect];
}
#endif

@end
