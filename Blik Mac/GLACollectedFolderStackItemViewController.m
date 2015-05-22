//
//  GLACollectedFolderStackItemViewController.m
//  Blik
//
//  Created by Patrick Smith on 24/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Quartz;

#import "GLACollectedFolderStackItemViewController.h"
#import "GLAUIStyle.h"
#import "GLACollectedFilePreviewView.h"
#import "Blik-Swift.h"
//#import "GLACollectedFolderContentsViewController.h"


@interface GLACollectedFolderStackItemViewController () <GLACollectedItemContentHolderViewDelegate>

@property(nonatomic) GLACollectedFilePreviewView *filePreviewView;

@property(nonatomic) GLACollectedFolderContentsViewController *folderContentsViewController;

@end

@implementation GLACollectedFolderStackItemViewController

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	[style prepareTextLabel:(self.nameLabel)];
	
	GLACollectedItemContentHolderView *contentHolderView = (self.contentHolderView);
	(contentHolderView.delegate) = self;
	(self.contentHolderView) = contentHolderView;
	
	GLAViewController *contentHolderViewController = [GLAViewController new];
	(contentHolderViewController.view) = contentHolderView;
	(self.contentHolderViewController) = contentHolderViewController;
	
	(contentHolderView.wantsLayer) = YES;
	//(self.contentHolderView.canDrawSubviewsIntoLayer) = YES;
	//(self.contentHolderView.layer.backgroundColor) = [[NSColor redColor] CGColor];
	
	//[self makeContentSquare];
}

- (void)makeContentSquare
{
	GLACollectedItemContentHolderView *contentHolderView = (self.contentHolderView);
	
	// Make square: width = height
	[(contentHolderView.superview) addConstraint:[NSLayoutConstraint constraintWithItem:contentHolderView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:contentHolderView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
}

- (void)updateContentWithFileURL:(NSURL *)fileURL
{
	(self.fileURL) = fileURL;
	
#if 0
	QLPreviewView *previewView = (self.quickLookPreviewView);
	if (!previewView) {
		previewView = [[QLPreviewView alloc] initWithFrame:NSZeroRect style:QLPreviewViewStyleCompact];
		(self.quickLookPreviewView) = previewView;
		
		(previewView.wantsLayer) = YES;
		
		[(self.contentHolderViewController) fillViewWithChildView:previewView];
	}
	
	(previewView.previewItem) = fileURL;
#else
	GLACollectedFilePreviewView *filePreviewView = (self.filePreviewView);
	if (!filePreviewView) {
		filePreviewView = [GLACollectedFilePreviewView new];
		(self.filePreviewView) = filePreviewView;
		
		[(self.contentHolderViewController) fillViewWithChildView:filePreviewView];
	}
	
	(filePreviewView.fileURL) = fileURL;
#endif
}

- (void)updateContentWithDirectoryURL:(NSURL *)directoryURL
{
	GLACollectedFolderContentsViewController *folderContentsViewController = [GLACollectedFolderContentsViewController new];
	(folderContentsViewController.sourceDirectoryURL) = directoryURL;
	(self.folderContentsViewController) = folderContentsViewController;
	
	[(self.contentHolderViewController) fillViewWithChildView:(folderContentsViewController.view)];
	
	GLACollectedItemContentHolderView *contentHolderView = (self.contentHolderView);
	(contentHolderView.minimumHeight) = 300.0;
	
}

#pragma mark - GLACollectedItemContentHolderViewDelegate

- (NSArray *)barViews
{
	return
  @[
	(self.topBarView),
	(self.bottomBarView)
	];
}

- (void)mouseDidEnterContentHolderView:(GLACollectedItemContentHolderView *)view
{
#if 0
	NSArray *barViews = (self.barViews);
	[[barViews valueForKey:@"animator"] setValue:@(1.0) forKey:@"alphaValue"];
#endif
}

- (void)mouseDidExitContentHolderView:(GLACollectedItemContentHolderView *)view
{
#if 0
	NSArray *barViews = (self.barViews);
	[[barViews valueForKey:@"animator"] setValue:@(0.0) forKey:@"alphaValue"];
#endif
}

- (void)didClickContentHolderView:(GLACollectedItemContentHolderView *)view
{
	id<GLACollectedFolderStackItemViewControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate didClickViewForItemViewController:self];
	}
}

@end


@implementation GLACollectedFolderStackItemView

#if 0
- (NSSize)intrinsicContentSize
{
	NSView *superview = (self.superview);
	
	return NSMakeSize(NSWidth(superview.frame), 50.0);
	
	//NSLog(@"GLACollectedFolderStackItemView intrinsicContentSize");
	//return NSMakeSize(NSViewNoInstrinsicMetric, 50.0);
}
#endif

@end