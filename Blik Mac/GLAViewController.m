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

+ (NSString *)defaultNibName
{
	return [self className];
}

- (instancetype)init
{
	return [self initWithNibName:[[self class] defaultNibName] bundle:nil];
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
	
	[self didPrepareView];
}

- (void)prepareView
{
	// For subclasses.
}

- (void)didPrepareView
{
	// For subclasses.
}

- (void)didInsertView
{
	// For subclasses.
}

- (void)insertIntoResponderChain
{
	NSView *view = (self.view);
	// Add this view controller to the responder chain pre-Yosemite.
	// Allows self to handle keyDown: events, and also work with a QLPreviewPanel
	if ((view.nextResponder) != self) {
		(self.nextResponder) = (view.nextResponder);
		(view.nextResponder) = self;
	}
}

- (void)viewWillTransitionIn
{
	// For subclasses.
}

- (void)viewDidTransitionIn
{
	// For subclasses.
}

- (void)viewWillTransitionOut
{
	// For subclasses.
}

- (void)viewDidTransitionOut
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

#pragma mark Transitioning

- (NSTimeInterval)transitionDurationGoingInForChildView:(NSView *)view
{
	return 4.0 / 12.0;
}

- (NSTimeInterval)transitionDurationGoingOutForChildView:(NSView *)view
{
	return 4.0 / 12.0;
}

- (void)transitionToInStateWithoutAnimating
{
	NSView *view = (self.view);
	
	(view.alphaValue) = 1.0;
}

- (void)transitionToOutStateWithoutAnimating
{
	NSView *view = (self.view);
	
	(view.alphaValue) = 0.0;
}

- (void)transitionInWithDuration:(NSTimeInterval)duration adjustingConstraint:(NSLayoutConstraint *)constraint fromValue:(CGFloat)constraintStartValue toValue:(CGFloat)constraintFinishValue isActiveChecker:(BOOL (^)(void))isActiveChecker completionHandler:(BOOL (^)(void))completionHandler
{
	NSView *view = (self.view);
	
	[self viewWillTransitionIn];
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 0.0;
		
		(view.animator.alphaValue) = 0.0;
		(constraint.animator.constant) = constraintStartValue;
	} completionHandler:^{
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = duration;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(view.animator.alphaValue) = 1.0;
			(constraint.animator.constant) = constraintFinishValue;
		} completionHandler:^ {
			BOOL isStillActive = YES;
			if (isActiveChecker) {
				isStillActive = isActiveChecker();
			}
			if (isStillActive) {
				[self viewDidTransitionIn];
			}
			
			if (completionHandler) {
				completionHandler();
			}
		}];
	}];
}

- (void)transitionOutWithDuration:(NSTimeInterval)duration adjustingConstraint:(NSLayoutConstraint *)constraint fromValue:(CGFloat)constraintStartValue toValue:(CGFloat)constraintFinishValue removeWhenCompleteHandler:(BOOL (^)(void))removeWhenCompleteHandler
{
	NSView *view = (self.view);
	
	[self viewWillTransitionOut];
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 0.0;
		
		(view.animator.alphaValue) = 1.0;
		(constraint.animator.constant) = constraintStartValue;
	} completionHandler:^{
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = duration;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(view.animator.alphaValue) = 0.0;
			(constraint.animator.constant) = constraintFinishValue;
		} completionHandler:^ {
			BOOL isStillNotActive = YES;
			if (removeWhenCompleteHandler) {
				isStillNotActive = removeWhenCompleteHandler();
			}
			if (isStillNotActive) {
				[view removeFromSuperview];
				[self viewDidTransitionOut];
			}
		}];
	}];
}

- (void)transitionInWithDuration:(NSTimeInterval)duration adjustingConstraint:(NSLayoutConstraint *)constraint toValue:(CGFloat)constraintValue animate:(BOOL)animate isActiveChecker:(BOOL (^)(void))isActiveChecker completionHandler:(void (^)())completionHandler
{
	NSView *view = (self.view);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(view.hidden) = NO;
		
		CGFloat fractionFromDestination = (constraint.constant) / (constraint.animator.constant);
		
		if (animate || YES) {
			(context.duration) = fractionFromDestination * duration;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(view.animator.alphaValue) = 1.0;
			(constraint.animator.constant) = constraintValue;
		}
		else {
			(context.duration) = 0;
			(view.alphaValue) = 1.0;
			(constraint.constant) = constraintValue;
		}
	} completionHandler:^ {
		BOOL isStillActive = YES;
		if (isActiveChecker) {
			isStillActive = isActiveChecker();
		}
		if (isStillActive) {
			[self viewDidTransitionIn];
		}
		
		if (completionHandler) {
			completionHandler();
		}
	}];
}

- (void)transitionOutWithDuration:(NSTimeInterval)duration adjustingConstraint:(NSLayoutConstraint *)constraint toValue:(CGFloat)constraintValue animate:(BOOL)animate isNotActiveChecker:(BOOL (^)(void))isNotActiveChecker completionHandler:(void (^)())completionHandler
{
	NSView *view = (self.view);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		if (animate || YES) {
			(context.duration) = duration;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(view.animator.alphaValue) = 0.0;
			(constraint.animator.constant) = constraintValue;
		}
		else {
			(context.duration) = 0;
			(view.alphaValue) = 0.0;
			(constraint.constant) = constraintValue;
		}
	} completionHandler:^ {
		BOOL isStillNotActive = YES;
		if (isNotActiveChecker) {
			isStillNotActive = isNotActiveChecker();
		}
		if (isStillNotActive) {
			[self viewWillTransitionOut];
			[view removeFromSuperview];
		}
		
		if (completionHandler) {
			completionHandler();
		}
	}];
}

- (void)showChildViewController:(GLAViewController *)vc adjustingConstraint:(NSLayoutConstraint *)constraint toValue:(CGFloat)constraintValue animate:(BOOL)animate isActiveChecker:(BOOL (^)(void))isActiveChecker completionHandler:(void (^)())completionHandler
{
	NSParameterAssert(vc != nil);
	
	NSView *view = (vc.view);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(view.hidden) = NO;
		
		CGFloat fractionFromDestination = (constraint.constant) / (constraint.animator.constant);
		
		if (animate) {
			(context.duration) = fractionFromDestination * [self transitionDurationGoingInForChildView:view];
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(view.animator.alphaValue) = 1.0;
			(constraint.animator.constant) = constraintValue;
		}
		else {
			(context.duration) = 0;
			(view.alphaValue) = 1.0;
			(constraint.constant) = constraintValue;
		}
	} completionHandler:^ {
		if (isActiveChecker()) {
			[vc viewDidTransitionIn];
		}
		
		completionHandler();
	}];
}

- (void)hideChildViewController:(GLAViewController *)vc adjustingConstraint:(NSLayoutConstraint *)constraint toValue:(CGFloat)constraintValue animate:(BOOL)animate isNotActiveChecker:(BOOL (^)(void))isNotActiveChecker completionHandler:(void (^)())completionHandler
{
	NSView *view = (vc.view);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		if (animate) {
			(context.duration) = [self transitionDurationGoingOutForChildView:view];
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(view.animator.alphaValue) = 0.0;
			(constraint.animator.constant) = constraintValue;
		}
		else {
			(context.duration) = 0;
			(view.alphaValue) = 0.0;
			(constraint.constant) = constraintValue;
		}
	} completionHandler:^ {
		if (animate) {
			if (isNotActiveChecker()) {
				[vc viewWillTransitionOut];
				[view removeFromSuperview];
			}
		}
		
		completionHandler();
	}];
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

#pragma mark Notification

- (void)addObserver:(id)observer forNotificationWithName:(NSString *)name selector:(SEL)aSelector
{
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:aSelector name:name object:self];
}

#pragma mark Reduce Motion

static BOOL _reduceMotion = NO;

+ (void)setReduceMotion:(BOOL)reduceMotion
{
	_reduceMotion = reduceMotion;
}

+ (BOOL)reduceMotion
{
	return _reduceMotion;
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
