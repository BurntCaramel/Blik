//
//  GLAViewController.h
//  Blik
//
//  Created by Patrick Smith on 14/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
@import QuartzCore;
#import "GLAView.h"

@interface GLAViewController : NSViewController <GLAViewDelegate>

@property(readonly, nonatomic) GLAView *view;

- (void)viewWillAppear;
- (void)viewDidAppear;

- (void)viewWillDisappear;
- (void)viewDidDisappear;

#pragma mark Auto Layout

- (void)updateConstraintsWithAnimatedDuration:(NSTimeInterval)duration;
- (void)updateConstraintsNow;

- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)constraintIdentifier;

+ (NSString *)layoutConstraintIdentifierWithBaseIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView;
- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView;

- (void)fillViewWithChildView:(NSView *)innerView;
- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute withChildView:(NSView *)innerView identifier:(NSString *)identifier priority:(NSLayoutPriority)priority;
- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute withChildView:(NSView *)innerView identifier:(NSString *)identifier;

//- (NSLayoutConstraint *)addLayoutConstraintForAttribute:(NSLayoutAttribute)attribute withValue:(CGFloat)value;

- (NSArray *)allLayoutConstraintsWithChildView:(NSView *)innerView;

+ (NSArray *)copyLayoutConstraints:(NSArray *)oldConstraints replacingUsesOf:(id)originalItem with:(id)replacementItem;

- (void)wrapChildViewKeepingOutsideConstraints:(NSView *)childView withView:(NSView *)replacementView;

#pragma mark Colors

- (void)animateBackgroundColorTo:(NSColor *)color;

@end
