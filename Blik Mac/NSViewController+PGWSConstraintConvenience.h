//
//  NSViewController+PGWSConstraintConvenience.h
//  BurntIcing
//
//  Created by Patrick Smith on 28/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;


typedef void (^PGWSViewControllerConstraintReplacementVisitor)(NSLayoutConstraint *oldConstraint, NSLayoutConstraint *newConstraint);


@interface NSViewController (PGWSConstraintConvenience)

- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)constraintIdentifier;

+ (NSString *)layoutConstraintIdentifierWithBaseIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView;
- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView;

#pragma mark -

- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute ofHolderView:(NSView *)holderView withChildView:(NSView *)innerView identifier:(NSString *)identifier priority:(NSLayoutPriority)priority;

- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute withChildView:(NSView *)innerView identifier:(NSString *)identifier priority:(NSLayoutPriority)priority;
- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute withChildView:(NSView *)innerView identifier:(NSString *)identifier;

- (void)fillView:(NSView *)holderView withView:(NSView *)innerView;
- (void)fillViewWithChildView:(NSView *)innerView;
- (void)fillWithChildViewController:(NSViewController *)childViewController;

#pragma mark -

- (NSArray *)allLayoutConstraintsUsingChildView:(NSView *)innerView;

+ (NSArray *)copyLayoutConstraints:(NSArray *)oldConstraints replacingUsesOf:(id)originalItem with:(id)replacementItem constraintVisitor:(PGWSViewControllerConstraintReplacementVisitor)constraintVisitor;

- (void)wrapChildViewKeepingOutsideConstraints:(NSView *)childView withView:(NSView *)replacementView constraintVisitor:(PGWSViewControllerConstraintReplacementVisitor)constraintVisitor;

@end
