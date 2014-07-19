//
//  GLAViewController.h
//  Blik
//
//  Created by Patrick Smith on 14/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAView.h"

@interface GLAViewController : NSViewController <GLAViewDelegate>

@property(readonly, nonatomic) GLAView *view;

- (void)updateConstraintsWithAnimatedDuration:(NSTimeInterval)duration;
- (void)updateConstraintsNow;

- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)baseIdentifier insideView:(NSView *)innerView;

- (void)fillViewWithInnerView:(NSView *)innerView;

@end
