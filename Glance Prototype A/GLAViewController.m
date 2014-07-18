//
//  GLAViewController.m
//  Blik
//
//  Created by Patrick Smith on 14/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"

@interface GLAViewController ()

- (NSString *)layoutConstraintIdentifierWithBaseIdentifier:(NSString *)baseIdentifier insideView:(NSView *)innerView;

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

- (NSString *)layoutConstraintIdentifierWithBaseIdentifier:(NSString *)baseIdentifier insideView:(NSView *)innerView
{
	return [NSString stringWithFormat:@"%@--%@", (innerView.identifier), baseIdentifier];
}

- (NSLayoutConstraint *)layoutConstraintWithIdentifier:(NSString *)baseIdentifier insideView:(NSView *)innerView
{
	if (!innerView) {
		return nil;
	}
	
	NSString *constraintIdentifier = [self layoutConstraintIdentifierWithBaseIdentifier:baseIdentifier insideView:innerView];
	NSArray *leadingConstraintInArray = [(self.view.constraints) filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", constraintIdentifier]];
	
	if (leadingConstraintInArray.count == 0) {
		return nil;
	}
	else {
		return leadingConstraintInArray[0];
	}
}

- (void)fillViewWithInnerView:(NSView *)innerView
{
	NSView *holderView = (self.view);
	
	if (holderView) {
		[holderView addSubview:innerView];
		
		// Interface Builder's default is to have this on for new view controllers in 10.9 for some reason.
		// I have disabled it where I remember to in the xib file.
		(innerView.translatesAutoresizingMaskIntoConstraints) = NO;
		
		NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:innerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:holderView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
		NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:innerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:holderView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
		NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:innerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:holderView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];
		NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:innerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:holderView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
		
		(leadingConstraint.identifier) = [self layoutConstraintIdentifierWithBaseIdentifier:@"leading" insideView:innerView];
		(topConstraint.identifier) = [self layoutConstraintIdentifierWithBaseIdentifier:@"top" insideView:innerView];
		
		[holderView addConstraints:@[widthConstraint, heightConstraint, leadingConstraint, topConstraint]];
	}
}

@end
