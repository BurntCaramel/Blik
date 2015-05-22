//
//  GLAViewController.h
//  Blik
//
//  Created by Patrick Smith on 14/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;
@import QuartzCore;
#import "NSViewController+PGWSConstraintConvenience.h"


@interface GLAViewController : NSViewController

+ (NSString *)defaultNibName;
- (instancetype)init;

- (void)prepareViewIfNeeded;
@property(nonatomic) BOOL hasPreparedViews;

// Subclass these, no super call required:

- (void)prepareView; // Like 10.10's -viewDidLoad method.
- (void)didPrepareView; // Set up that requires hasPreparedViews to be set.
- (void)didInsertView; // For when the view hierarchy or window is needed.

- (void)insertIntoResponderChain;

#pragma mark Transitioning

- (void)transitionToInStateWithoutAnimating;
- (void)transitionToOutStateWithoutAnimating;

- (void)transitionInWithDuration:(NSTimeInterval)duration adjustingConstraint:(NSLayoutConstraint *)constraint fromValue:(CGFloat)constraintStartValue toValue:(CGFloat)constraintFinishValue isActiveChecker:(BOOL (^)(void))isActiveChecker completionHandler:(BOOL (^)(void))completionHandler;

- (void)transitionOutWithDuration:(NSTimeInterval)duration adjustingConstraint:(NSLayoutConstraint *)constraint fromValue:(CGFloat)constraintStartValue toValue:(CGFloat)constraintFinishValue removeWhenCompleteHandler:(BOOL (^)(void))removeWhenCompleteHandler;

- (void)transitionInWithDuration:(NSTimeInterval)duration adjustingConstraint:(NSLayoutConstraint *)constraint toValue:(CGFloat)constraintValue animate:(BOOL)animate isActiveChecker:(BOOL (^)(void))isActiveChecker completionHandler:(void (^)())completionHandler;

- (void)transitionOutWithDuration:(NSTimeInterval)duration adjustingConstraint:(NSLayoutConstraint *)constraint toValue:(CGFloat)constraintValue animate:(BOOL)animate isNotActiveChecker:(BOOL (^)(void))isNotActiveChecker completionHandler:(void (^)())completionHandler;

- (void)viewWillTransitionIn;
- (void)viewDidTransitionIn;

- (void)viewWillTransitionOut;
- (void)viewDidTransitionOut;

#pragma mark Auto Layout

- (void)updateConstraintsWithAnimatedDuration:(NSTimeInterval)duration;
- (void)updateConstraintsNow;

#pragma mark Colors

- (void)animateBackgroundColorTo:(NSColor *)color;

#pragma mark Notification

- (void)addObserver:(id)observer forNotificationWithName:(NSString *)name selector:(SEL)aSelector;

@end

@interface GLAViewController (ViewIdentifiers)

+ (NSView *)viewWithIdentifier:(NSString *)identifier inViews:(NSArray *)views;

@end

@interface GLAViewController (HolderView)

- (instancetype)initWithHolderView:(NSView *)holderView filledWithView:(NSView *)contentView;

@end
