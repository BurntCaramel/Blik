//
//  GLACollectedFolderStackItemViewController.h
//  Blik
//
//  Created by Patrick Smith on 24/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLACollectedItemContentHolderView.h"

@class GLACollectedFolderStackItemViewController;
@protocol GLACollectedFolderStackItemViewControllerDelegate <NSObject>

- (void)didClickViewForItemViewController:(GLACollectedFolderStackItemViewController *)viewController;

@end


@interface GLACollectedFolderStackItemViewController : GLAViewController

@property(weak, nonatomic) id<GLACollectedFolderStackItemViewControllerDelegate> delegate;

@property(nonatomic) IBOutlet NSView *topBarView;
@property(nonatomic) IBOutlet NSView *bottomBarView;

@property(nonatomic) IBOutlet NSTextField *nameLabel;
@property(nonatomic) IBOutlet NSImageView *iconImageView;

@property(nonatomic) BOOL isDirectory;

@property(nonatomic) NSURL *fileURL;

- (void)updateContentWithFileURL:(NSURL *)fileURL;
- (void)updateContentWithDirectoryURL:(NSURL *)folderURL;

@property(nonatomic) IBOutlet GLACollectedItemContentHolderView *contentHolderView;
@property(nonatomic) IBOutlet NSLayoutConstraint *contentHolderHeightConstraint;
@property(nonatomic) GLAViewController *contentHolderViewController;

@property(nonatomic) QLPreviewView *quickLookPreviewView;

@end


@interface GLACollectedFolderStackItemView : NSView

@end