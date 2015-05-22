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
#import "GLAFolderContentsAssisting.h"

NS_ASSUME_NONNULL_BEGIN

@class GLAQuickLookPreviewHelper;
@protocol GLAQuickLookPreviewHelperDelegate <NSObject>

- (NSArray *)selectedURLsForQuickLookPreviewHelper:(GLAQuickLookPreviewHelper *)helper;

- (NSInteger)quickLookPreviewHelper:(GLAQuickLookPreviewHelper *)helper tableRowForSelectedURL:(NSURL *)fileURL;

@end


@interface GLAQuickLookPreviewHelper : NSObject

@property(weak, nonatomic) IBOutlet id<GLAQuickLookPreviewHelperDelegate> delegate;

@property(nonatomic) IBOutlet GLAViewController * __nullable previewHolderViewController;
@property(nonatomic) IBOutlet NSView * __nullable previewHolderView;

@property(nonatomic) IBOutlet QLPreviewView * __nullable quickLookPreviewView;

@property(nonatomic) IBOutlet NSTableView *sourceTableView;

@property(readonly, nonatomic) NSURL *__nullable activeURL;

@property(weak, nonatomic) id<GLAFolderContentsAssisting> __nullable folderContentsAssistant;

- (void)firstResponderDidChange;

- (BOOL)folderContentsIsFirstResponder;
- (NSArray * __nullable)folderContentsSelectedURLsOnlyIfFirstResponder:(BOOL)onlyIfFirstResponder;

- (void)updatePreviewAnimating:(BOOL)animate;

- (void)showQuickLookPanel:(BOOL)show;
- (IBAction)quickLookPreviewItems:(id __nullable)sender;

- (void)deactivate;

@end

NS_ASSUME_NONNULL_END
