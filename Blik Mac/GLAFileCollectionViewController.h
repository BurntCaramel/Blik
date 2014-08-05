//
//  GLAFileCollectionViewController.h
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectionViewController.h"
@class GLACollectionFilesListContent;
@import Quartz;


@interface GLAFileCollectionViewController : GLACollectionViewController <NSTableViewDataSource, NSTableViewDelegate>

@property(nonatomic) IBOutlet NSTableView *sourceFilesListTableView;

@property(nonatomic) IBOutlet GLAViewController *previewHolderViewController;
@property(nonatomic) IBOutlet NSView *previewHolderView;
@property(nonatomic) QLPreviewView *quickLookPreviewView;

@property(nonatomic) GLACollectionFilesListContent *filesListContent;

@end
