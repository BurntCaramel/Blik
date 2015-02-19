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

@property(nonatomic) IBOutlet NSTableView *tableView;

- (void)updateQuickLookPreviewAnimating:(BOOL)animate;

- (IBAction)quickLookPreviewItems:(id)sender;

- (void)deactivate;

@end
