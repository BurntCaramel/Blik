//
//  GLAView.h
//  Blik
//
//  Created by Patrick Smith on 11/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;


@class GLAView;
@protocol GLAViewDelegate <NSObject>

@optional

- (void)viewUpdateConstraints:(GLAView *)view;

@end


@interface GLAView : NSView

@property(weak, nonatomic) IBOutlet id<GLAViewDelegate> delegate;

@end
