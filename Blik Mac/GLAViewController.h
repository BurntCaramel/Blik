//
//  GLAViewController.h
//  Blik
//
//  Created by Patrick Smith on 14/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;
@import QuartzCore;


typedef void (^GLAViewControllerConstraintReplacementVisitor)(NSLayoutConstraint *oldConstraint, NSLayoutConstraint *newConstraint);


@interface GLAViewController : NSViewController

- (void)prepareViewIfNeeded;
@property(nonatomic) BOOL hasPreparedViews;

// Subclass these, no super call required:

- (void)prepareView; // Like 10.10's -viewDidLoad method.

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

- (NSArray *)allLayoutConstraintsWithChildView:(NSView *)innerView;

+ (NSArray *)copyLayoutConstraints:(NSArray *)oldConstraints replacingUsesOf:(id)originalItem with:(id)replacementItem constraintVisitor:(GLAViewControllerConstraintReplacementVisitor)constraintVisitor;

- (void)wrapChildViewKeepingOutsideConstraints:(NSView *)childView withView:(NSView *)replacementView constraintVisitor:(GLAViewControllerConstraintReplacementVisitor)constraintVisitor;

#pragma mark Colors

- (void)animateBackgroundColorTo:(NSColor *)color;

@end

@interface GLAViewController (ViewIdentifiers)

+ (NSView *)viewWithIdentifier:(NSString *)identifier inViews:(NSArray *)views;

@end

@interface GLAViewController (HolderView)

- (instancetype)initWithHolderView:(NSView *)holderView filledWithView:(NSView *)contentView;

@end
