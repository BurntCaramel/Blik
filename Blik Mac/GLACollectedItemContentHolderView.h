//
//  GLACollectedItemContentHolderView.h
//  Blik
//
//  Created by Patrick Smith on 7/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;


@class GLACollectedItemContentHolderView;
@protocol GLACollectedItemContentHolderViewDelegate <NSObject>

- (void)mouseDidEnterContentHolderView:(GLACollectedItemContentHolderView *)view;
- (void)mouseDidExitContentHolderView:(GLACollectedItemContentHolderView *)view;

- (void)didClickContentHolderView:(GLACollectedItemContentHolderView *)view;

@end


@interface GLACollectedItemContentHolderView : NSView

@property(weak, nonatomic) id<GLACollectedItemContentHolderViewDelegate> delegate;

@end
