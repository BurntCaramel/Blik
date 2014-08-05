//
//  GLAViewController.m
//  Blik
//
//  Created by Patrick Smith on 14/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
@import QuartzCore;

@interface GLAViewController ()

- (NSString *)layoutConstraintIdentifierWithBaseIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView;

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

- (GLAView *)view
{
	return (id)[super view];
}

- (void)viewWillAppear
{
}

- (void)viewDidAppear
{
}

- (void)viewWillDisappear
{
}

- (void)viewDidDisappear
{
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

- (NSString *)layoutConstraintIdentifierWithBaseIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView
{
	return [NSString stringWithFormat:@"%@--%@", (innerView.identifier), baseIdentifier];
}

- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)baseIdentifier forChildView:(NSView *)innerView
{
	if (!innerView) {
		return nil;
	}
	
	NSString *constraintIdentifier = [self layoutConstraintIdentifierWithBaseIdentifier:baseIdentifier forChildView:innerView];
	NSArray *leadingConstraintInArray = [(self.view.constraints) filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", constraintIdentifier]];
	
	if (leadingConstraintInArray.count == 0) {
		return nil;
	}
	else {
		return leadingConstraintInArray[0];
	}
}

- (NSLayoutConstraint *)addLayoutConstraintToMatchAttribute:(NSLayoutAttribute)attribute withChildView:(NSView *)innerView identifier:(NSString *)identifier
{
	NSView *holderView = (self.view);
	
	NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:innerView attribute:attribute relatedBy:NSLayoutRelationEqual toItem:holderView attribute:attribute multiplier:1.0 constant:0.0];
	
	(constraint.identifier) = [self layoutConstraintIdentifierWithBaseIdentifier:identifier forChildView:innerView];
	
	[holderView addConstraint:constraint];
	
	return constraint;
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
