//
//  GLACollectedFilePreviewView.h
//  Blik
//
//  Created by Patrick Smith on 27/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;
@import Quartz;


@interface GLACollectedFilePreviewView : NSView

@property(copy, nonatomic) NSURL *fileURL;

@property(nonatomic) CGFloat contentScale;

- (void)invalidatePreview;

@end
