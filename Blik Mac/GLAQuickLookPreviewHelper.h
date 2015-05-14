//
//  GLAQuickLookPreviewHelper.h
//  Blik
//
//  Created by Patrick Smith on 18/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;
@import Quartz;
#import "GLAViewController.h"
#import "GLACollectedFolderContentsViewController.h"


@class GLAQuickLookPreviewHelper;
@protocol GLAQuickLookPreviewHelperDelegate <NSObject>

- (NSArray *)selectedURLsForQuickLookPreviewHelper:(GLAQuickLookPreviewHelper *)helper;

- (NSInteger)quickLookPreviewHelper:(GLAQuickLookPreviewHelper *)helper tableRowForSelectedURL:(NSURL *)fileURL;

@end


@interface GLAQuickLookPreviewHelper : NSObject

@property(weak, nonatomic) IBOutlet id<GLAQuickLookPreviewHelperDelegate> delegate;

@property(nonatomic) IBOutlet GLAViewController *previewHolderViewController;
@property(nonatomic) IBOutlet NSView *previewHolderView;

@property(nonatomic) IBOutlet QLPreviewView *quickLookPreviewView;
@property(nonatomic) GLACollectedFolderContentsViewController *folderContentsViewController;

@property(nonatomic) IBOutlet NSTableView *tableView;

@property(readonly, nonatomic) NSURL *activeURL;

- (void)updatePreviewAnimating:(BOOL)animate;

- (void)showQuickLookPanel:(BOOL)show;
- (IBAction)quickLookPreviewItems:(id)sender;

- (void)deactivate;

@end
