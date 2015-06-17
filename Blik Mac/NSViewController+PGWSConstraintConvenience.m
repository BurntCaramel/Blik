//
//  NSViewController+PGWSConstraintConvenience.m
//  BurntIcing
//
//  Created by Patrick Smith on 28/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "NSViewController+PGWSConstraintConvenience.h"


@implementation NSViewController (PGWSConstraintConvenience)

- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)constraintIdentifier
{
	NSArray *leadingConstraintInArray = [(self.view.constraints) filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", constraintIdentifier]];
	
	if (leadingConstraintInArray.count == 0) {
		return nil;
	}
	else {
		return leadingConstraintInArray[0];
	}
}

+ (NSString *)layoutConstraintIdentifierWithBaseIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView
{
	return [NSString stringWithFormat:@"%@--%@", (innerView.identifier), baseIdentifier];
}

- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView
{
	if (!innerView) {
		return nil;
	}
	
	NSString *constraintIdentifier = [(self.class) layoutConstraintIdentifierWithBaseIdentifier:baseIdentifier forChildView:innerView];
	return [self layoutConstraintWithIdentifier:constraintIdentifier];
}

#pragma mark -

- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute ofHolderView:(NSView *)holderView withChildView:(NSView *)innerView identifier:(NSString *)identifier priority:(NSLayoutPriority)priority
{
	NSParameterAssert(holderView != nil);
	NSParameterAssert(innerView != nil);
	NSParameterAssert(identifier != nil);
	
	NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:innerView attribute:attribute relatedBy:NSLayoutRelationEqual toItem:holderView attribute:attribute multiplier:1.0 constant:0.0];
	
	(constraint.identifier) = [(self.class) layoutConstraintIdentifierWithBaseIdentifier:identifier forChildView:innerView];
	(constraint.priority) = priority;
	
	[holderView addConstraint:constraint];
	
	return constraint;
}

- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute withChildView:(NSView *)innerView identifier:(NSString *)identifier priority:(NSLayoutPriority)priority
{
	return [self addLayoutConstraintToMatchAttribute:attribute ofHolderView:(self.view) withChildView:innerView identifier:identifier priority:priority];
}

- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute withChildView:(NSView *)innerView identifier:(NSString *)identifier
{
	return [self addLayoutConstraintToMatchAttribute:attribute withChildView:innerView identifier:identifier priority:NSLayoutPriorityRequired];
}

- (void)fillView:(NSView *)holderView withView:(NSView *)innerView
{
	NSParameterAssert(holderView != nil);
	NSParameterAssert(innerView != nil);
	
	if (!(innerView.identifier)) {
		NSUUID *UUID = [NSUUID UUID];
		(innerView.identifier) = [NSString stringWithFormat:@"(%@)", (UUID.UUIDString)];
	}
	
	[holderView addSubview:innerView];
	
	// Interface Builder's default is to have this on for new view controllers in 10.9 for some reason.
	// I have disabled it where I remember to in the xib file, but no harm in just setting it off here too.
	(innerView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	// By setting width and height constraints, we can move the view around whilst keeping it the same size.
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeWidth ofHolderView:holderView withChildView:innerView identifier:@"width" priority:NSLayoutPriorityRequired];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeHeight ofHolderView:holderView withChildView:innerView identifier:@"height" priority:NSLayoutPriorityRequired];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeLeading ofHolderView:holderView withChildView:innerView identifier:@"leading" priority:NSLayoutPriorityRequired];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeTop ofHolderView:holderView withChildView:innerView identifier:@"top" priority:NSLayoutPriorityRequired];
}

- (void)fillViewWithChildView:(NSView *)innerView
{
	[self fillView:(self.view) withView:innerView];
}

- (void)fillWithChildViewController:(NSViewController *)childViewController
{
	NSParameterAssert(childViewController != nil);
	
	[self addChildViewController:childViewController];
	[self fillViewWithChildView:(childViewController.view)];
}

#pragma mark -

- (NSArray *)allLayoutConstraintsUsingChildView:(NSView *)innerView
{
	return [(self.view.constraints) filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"firstItem = %@ OR secondItem = %@", innerView, innerView]];
}

+ (NSArray *)copyLayoutConstraints:(NSArray *)oldConstraints replacingUsesOf:(id)originalItem with:(id)replacementItem constraintVisitor:(PGWSViewControllerConstraintReplacementVisitor)constraintVisitor
{
	NSAssert(originalItem != nil, @"originalItem must not be nil.");
	NSAssert(replacementItem != nil, @"replacementItem must not be nil.");
	
	NSMutableArray *newConstraints = [NSMutableArray arrayWithCapacity:(oldConstraints.count)];
	for (NSLayoutConstraint *oldConstraint in oldConstraints) {
		id firstItem = (oldConstraint.firstItem);
		if (firstItem == originalItem) {
			firstItem = replacementItem;
		}
		
		id secondItem = (oldConstraint.secondItem);
		if (secondItem == originalItem) {
			secondItem = replacementItem;
		}
		
		NSLayoutConstraint *newConstraint = [NSLayoutConstraint constraintWithItem:firstItem attribute:(oldConstraint.firstAttribute) relatedBy:(oldConstraint.relation) toItem:secondItem attribute:(oldConstraint.secondAttribute) multiplier:(oldConstraint.multiplier) constant:(oldConstraint.constant)];
		
		(newConstraint.priority) = (oldConstraint.priority);
		(newConstraint.identifier) = (oldConstraint.identifier);
		
		if (constraintVisitor) {
			constraintVisitor(oldConstraint, newConstraint);
		}
		
		[newConstraints addObject:newConstraint];
	}
	
	return newConstraints;
}

- (void)wrapChildViewKeepingOutsideConstraints:(NSView *)childView withView:(NSView *)replacementView constraintVisitor:(PGWSViewControllerConstraintReplacementVisitor)constraintVisitor
{
	NSAssert(childView != nil, @"childView must not be nil.");
	NSAssert(replacementView != nil, @"replacementView must not be nil.");
	
	NSArray *oldConstraints = [self allLayoutConstraintsUsingChildView:childView];
	NSArray *newConstraints = [[self class] copyLayoutConstraints:oldConstraints replacingUsesOf:childView with:replacementView constraintVisitor:constraintVisitor];
	
	NSView *view = (self.view);
	[view removeConstraints:oldConstraints];
	
	[childView removeFromSuperview];
	[replacementView addSubview:childView];
	[view addSubview:replacementView];
	
	[view addConstraints:newConstraints];
}

@end
