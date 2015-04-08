//
//  GLANavigationButtonGroup.m
//  Blik
//
//  Created by Patrick Smith on 10/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLANavigationButtonGroup.h"
#import "GLAUIStyle.h"


@interface GLANavigationButtonGroup ()

@property(readwrite, nonatomic) NSView *leadingView;
@property(readwrite, nonatomic) NSView *centerView;
@property(readwrite, nonatomic) NSView *trailingView;

@property(nonatomic) NSUInteger animatingCounter;

@end

@implementation GLANavigationButtonGroup

- (instancetype)init
{
	self = [super init];
	if (self) {
		CGFloat defaultInDuration = 4.0 / 16.0;
		CGFloat defaultOutDuration = 4.0 / 16.0;
		_leadingButtonInDuration = defaultInDuration;
		_centerButtonInDuration = defaultInDuration;
		_trailingButtonInDuration = defaultInDuration;
		_leadingButtonOutDuration = defaultOutDuration;
		_centerButtonOutDuration = defaultOutDuration;
		_trailingButtonOutDuration = defaultOutDuration;
	}
	return self;
}

+ (instancetype)buttonGroupWithViewController:(GLAViewController *)viewController templateButton:(GLAButton *)templateButton
{
	GLANavigationButtonGroup *buttonGroup = [GLANavigationButtonGroup new];
	(buttonGroup.viewController) = viewController;
	(buttonGroup.templateButton) = templateButton;
	
	return buttonGroup;
}

#pragma mark -

- (void)addChildView:(NSView *)childView
{
	GLAViewController *vc = (self.viewController);
	NSView *view = (vc.view);
	[view addSubview:childView];
	
	(childView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	[vc addLayoutConstraintToMatchAttribute:NSLayoutAttributeTop withChildView:childView identifier:@"top"];
	[vc addLayoutConstraintToMatchAttribute:NSLayoutAttributeHeight withChildView:childView identifier:@"height"];
}

- (void)addLeadingView:(NSView *)childView
{
	[self addChildView:childView];
	(self.leadingView) = childView;
	
	GLAViewController *vc = (self.viewController);
	[vc addLayoutConstraintToMatchAttribute:NSLayoutAttributeLeading withChildView:childView identifier:@"leading"];
}

- (void)addCenterView:(NSView *)childView
{
	[self addChildView:childView];
	(self.centerView) = childView;
	
	GLAViewController *vc = (self.viewController);
	[vc addLayoutConstraintToMatchAttribute:NSLayoutAttributeCenterX withChildView:childView identifier:@"centerX"];
}

- (void)addTrailingView:(NSView *)childView
{
	[self addChildView:childView];
	(self.trailingView) = childView;
	
	GLAViewController *vc = (self.viewController);
	[vc addLayoutConstraintToMatchAttribute:NSLayoutAttributeTrailing withChildView:childView identifier:@"trailing"];
}

#pragma mark -

- (GLAButton *)addButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAViewController *vc = (self.viewController);
	
	GLAButton *button = [GLAButton new];
	(button.cell) = [(self.templateButton.cell) copy];
	//GLAButton *button = [(self.templateButton) copy];
	(button.identifier) = identifier;
	(button.title) = title;
	if (action) {
		(button.target) = vc;
		(button.action) = action;
	}
	else {
		(button.target) = nil;
		(button.action) = nil;
	}
	
	return button;
}

- (GLAButton *)leadingButton
{
	NSView *leadingView = (self.leadingView);
	if (leadingView && [leadingView isKindOfClass:[GLAButton class]]) {
		return (GLAButton *)leadingView;
	}
	else {
		return nil;
	}
}

- (GLAButton *)centerButton
{
	NSView *centerView = (self.centerView);
	if (centerView && [centerView isKindOfClass:[GLAButton class]]) {
		return (GLAButton *)centerView;
	}
	else {
		return nil;
	}
}

- (GLAButton *)trailingButton
{
	NSView *trailingView = (self.trailingView);
	if (trailingView && [trailingView isKindOfClass:[GLAButton class]]) {
		return (GLAButton *)trailingView;
	}
	else {
		return nil;
	}
}

- (GLAButton *)makeLeadingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAButton *button = [self addButtonWithTitle:title action:action identifier:identifier];
	
	(button.hasSecondaryStyle) = YES;
	
	[self addLeadingView:button];
	
	return button;
}

- (GLAButton *)makeCenterButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAButton *button = [self addButtonWithTitle:title action:action identifier:identifier];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	(button.font) = (uiStyle.labelFont);
	
	[self addCenterView:button];
	
	return button;
}

- (GLAButton *)makeTrailingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAButton *button = [self addButtonWithTitle:title action:action identifier:identifier];
	
	(button.hasSecondaryStyle) = YES;
	
	[self addTrailingView:button];
	
	return button;
}

- (void)willBeginAnimating
{
	(self.animatingCounter)++;
}

- (void)didEndAnimating
{
	NSAssert((self.animatingCounter) > 0, @"Should end animating when not actually animating.");
	(self.animatingCounter)--;
}

- (void)animateInView:(NSView *)view duration:(NSTimeInterval)duration constraintIdentifier:(NSString *)constraintIdentifier constraintStartValue:(CGFloat)constraintStartValue constraintEndValue:(CGFloat)constraintEndValue
{
	GLAViewController *vc = (self.viewController);
	
	[self willBeginAnimating];
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = duration;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		NSLayoutConstraint *constraint = [vc layoutConstraintWithIdentifier:constraintIdentifier forChildView:view];
		
		(view.alphaValue) = 0.0;
		(view.animator.alphaValue) = 1.0;
		
		(constraint.constant) = constraintStartValue;
		(constraint.animator.constant) = constraintEndValue;
	} completionHandler:^ {
		[self didEndAnimating];
	}];
}

- (void)animateOutView:(NSView *)view duration:(NSTimeInterval)duration constraintIdentifier:(NSString *)constraintIdentifier constraintEndValue:(CGFloat)constraintEndValue completionHandler:(dispatch_block_t)completionHandler
{
	GLAViewController *vc = (self.viewController);
	
	[self willBeginAnimating];
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = duration;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		NSLayoutConstraint *constraint = [vc layoutConstraintWithIdentifier:constraintIdentifier forChildView:view];
		
		(view.animator.alphaValue) = 0.0;
		
		(constraint.animator.constant) = constraintEndValue;
	} completionHandler:^ {
		[view removeFromSuperview];
		
		completionHandler();
		
		[self didEndAnimating];
	}];
}

- (void)animateButtonsIn
{
	NSView *leadingView = (self.leadingView);
	NSView *centerView = (self.centerView);
	NSView *trailingView = (self.trailingView);
	
	if (leadingView) {
		[self animateInView:leadingView duration:(self.leadingButtonInDuration) constraintIdentifier:@"leading" constraintStartValue:-250.0 constraintEndValue:0.0];
	}
	
	if (centerView) {
		[self animateInView:centerView duration:(self.centerButtonInDuration) constraintIdentifier:@"top" constraintStartValue:50.0 constraintEndValue:0.0];
	}
	
	if (trailingView) {
		[self animateInView:trailingView duration:(self.trailingButtonInDuration) constraintIdentifier:@"trailing" constraintStartValue:250.0 constraintEndValue:(self.trailingViewOffset)];
	}
}

- (void)animateButtonsOutWithCompletionHandler:(dispatch_block_t)completionHandler
{
	NSView *leadingView = (self.leadingView);
	NSView *centerButton = (self.centerView);
	NSView *trailingButton = (self.trailingView);
	__block NSUInteger buttonsAnimating = 0;
	
	dispatch_block_t individualButtonCompletionHandler = ^{
		buttonsAnimating--;
		if (buttonsAnimating == 0) {
			completionHandler();
		}
	};
	
	if (leadingView) {
		buttonsAnimating++;
		[self animateOutView:leadingView duration:(self.leadingButtonInDuration) constraintIdentifier:@"leading" constraintEndValue:-250.0 completionHandler:individualButtonCompletionHandler];
	}
	
	if (centerButton) {
		buttonsAnimating++;
		[self animateOutView:centerButton duration:(self.centerButtonInDuration) constraintIdentifier:@"top" constraintEndValue:50.0 completionHandler:individualButtonCompletionHandler];
	}
	
	if (trailingButton) {
		buttonsAnimating++;
		[self animateOutView:trailingButton duration:(self.trailingButtonInDuration) constraintIdentifier:@"trailing" constraintEndValue:250.0 completionHandler:individualButtonCompletionHandler];
	}
	
	if (buttonsAnimating == 0) {
		completionHandler();
	}
}

@end
