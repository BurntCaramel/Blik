//
//  GLAViewController.m
//  Blik
//
//  Created by Patrick Smith on 14/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAViewController.h"
@import QuartzCore;

@interface GLAViewController ()

@end

@implementation GLAViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)loadView
{
	[super loadView];
	
	[self prepareViewIfNeeded];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self prepareViewIfNeeded];
}


- (void)prepareViewIfNeeded
{
	if (self.hasPreparedViews) {
		return;
	}
	
	[self prepareView];
	
	(self.hasPreparedViews) = YES;
}

- (void)prepareView
{
	// For subclasses.
}

- (void)viewWillAppear
{
	// For subclasses.
}

- (void)viewDidAppear
{
	// For subclasses.
}

- (void)viewWillDisappear
{
	// For subclasses.
}

- (void)viewDidDisappear
{
	// For subclasses.
}

- (void)updateConstraintsWithAnimatedDuration:(NSTimeInterval)duration
{
	NSView *view = (self.view);
	[view setNeedsUpdateConstraints:YES];
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = duration;
		(context.allowsImplicitAnimation) = YES;
		
		[view layoutSubtreeIfNeeded];
	} completionHandler:^{
		
	}];
}

- (void)updateConstraintsNow
{
	NSView *view = (self.view);
	[view setNeedsUpdateConstraints:YES];
	[view layoutSubtreeIfNeeded];
}

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

- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute withChildView:(NSView *)innerView identifier:(NSString *)identifier priority:(NSLayoutPriority)priority
{
	NSView *holderView = (self.view);
	
	NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:innerView attribute:attribute relatedBy:NSLayoutRelationEqual toItem:holderView attribute:attribute multiplier:1.0 constant:0.0];
	
	(constraint.identifier) = [(self.class) layoutConstraintIdentifierWithBaseIdentifier:identifier forChildView:innerView];
	(constraint.priority) = priority;
	
	[holderView addConstraint:constraint];
	
	return constraint;
}

- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute withChildView:(NSView *)innerView identifier:(NSString *)identifier
{
	return [self addLayoutConstraintToMatchAttribute:attribute withChildView:innerView identifier:identifier priority:NSLayoutPriorityRequired];
}

- (void)fillViewWithChildView:(NSView *)innerView
{
	if (!(innerView.identifier)) {
		NSUUID *UUID = [NSUUID UUID];
		(innerView.identifier) = [NSString stringWithFormat:@"(%@)", (UUID.UUIDString)];
	}
	
	[(self.view) addSubview:innerView];
	
	// Interface Builder's default is to have this on for new view controllers in 10.9 for some reason.
	// I have disabled it where I remember to in the xib file, but no harm in just setting it off here too.
	(innerView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	// By setting width and height constraints, we can move the view around whilst keeping it the same size.
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeWidth withChildView:innerView identifier:@"width"];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeHeight withChildView:innerView identifier:@"height"];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeLeading withChildView:innerView identifier:@"leading"];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeTop withChildView:innerView identifier:@"top"];
}

- (NSArray *)allLayoutConstraintsWithChildView:(NSView *)innerView
{
	return [(self.view.constraints) filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"firstItem = %@ OR secondItem = %@", innerView, innerView]];
}

+ (NSArray *)copyLayoutConstraints:(NSArray *)oldConstraints replacingUsesOf:(id)originalItem with:(id)replacementItem constraintVisitor:(GLAViewControllerConstraintReplacementVisitor)constraintVisitor
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

- (void)wrapChildViewKeepingOutsideConstraints:(NSView *)childView withView:(NSView *)replacementView constraintVisitor:(GLAViewControllerConstraintReplacementVisitor)constraintVisitor
{
	NSAssert(childView != nil, @"childView must not be nil.");
	NSAssert(replacementView != nil, @"replacementView must not be nil.");
	
	NSArray *oldConstraints = [self allLayoutConstraintsWithChildView:childView];
	NSArray *newConstraints = [[self class] copyLayoutConstraints:oldConstraints replacingUsesOf:childView with:replacementView constraintVisitor:constraintVisitor];
	
	NSView *view = (self.view);
	[view removeConstraints:oldConstraints];
	
	[childView removeFromSuperview];
	[replacementView addSubview:childView];
	[view addSubview:replacementView];
	
	[view addConstraints:newConstraints];
}

#pragma mark Colors

- (void)animateBackgroundColorTo:(NSColor *)color
{
	CALayer *layer = (self.view.layer);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.allowsImplicitAnimation) = YES;
		
		(layer.backgroundColor) = (color.CGColor);
	} completionHandler:^{
		
	}];
}

@end


@implementation GLAViewController (ViewIdentifiers)

+ (NSView *)viewWithIdentifier:(NSString *)identifier inViews:(NSArray *)views
{
	NSArray *matchingViews = [views filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", identifier]];
	
	if (matchingViews.count == 0) {
		return nil;
	}
	else {
		return matchingViews[0];
	}
}

@end


@implementation GLAViewController (HolderView)

- (instancetype)initWithHolderView:(NSView *)holderView filledWithView:(NSView *)contentView
{
	self = [self init];
	if (self) {
		(self.view) = holderView;
		[self fillViewWithChildView:contentView];
	}
	return self;
}

@end
