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

- (GLAButton *)addButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAViewController *vc = (self.viewController);
	
	GLAButton *button = [GLAButton new];
	(button.cell) = [(self.templateButton.cell) copy];
	(button.identifier) = identifier;
	(button.title) = title;
	if (action) {
		(button.target) = vc;
		(button.action) = action;
	}
	(button.translatesAutoresizingMaskIntoConstraints) = NO;
	
	NSView *view = (vc.view);
	[view addSubview:button];
	
	[vc addLayoutConstraintToMatchAttribute:NSLayoutAttributeTop withChildView:button identifier:@"top"];
	[vc addLayoutConstraintToMatchAttribute:NSLayoutAttributeHeight withChildView:button identifier:@"height"];
	
	return button;
}

- (GLAButton *)makeLeadingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAButton *button = [self addButtonWithTitle:title action:action identifier:identifier];
	
	(button.hasSecondaryStyle) = YES;
	
	GLAViewController *vc = (self.viewController);
	[vc addLayoutConstraintToMatchAttribute:NSLayoutAttributeLeading withChildView:button identifier:@"leading"];
	
	(self.leadingButton) = button;
	
	return button;
}

- (GLAButton *)makeCenterButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAButton *button = [self addButtonWithTitle:title action:action identifier:identifier];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	(button.font) = (uiStyle.labelFont);
	
	GLAViewController *vc = (self.viewController);
	[vc addLayoutConstraintToMatchAttribute:NSLayoutAttributeCenterX withChildView:button identifier:@"centerX"];
	
	(self.centerButton) = button;
	
	return button;
}

- (GLAButton *)makeTrailingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier
{
	GLAButton *button = [self addButtonWithTitle:title action:action identifier:identifier];
	
	(button.hasSecondaryStyle) = YES;
	
	GLAViewController *vc = (self.viewController);
	[vc addLayoutConstraintToMatchAttribute:NSLayoutAttributeLeading withChildView:button identifier:@"trailing"];
	
	(self.leadingButton) = button;
	
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

- (void)animateInButton:(GLAButton *)button duration:(NSTimeInterval)duration constraintIdentifier:(NSString *)constraintIdentifier constraintStartValue:(CGFloat)constraintStartValue
{
	GLAViewController *vc = (self.viewController);
	
	[self willBeginAnimating];
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = duration;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		NSLayoutConstraint *constraint = [vc layoutConstraintWithIdentifier:constraintIdentifier forChildView:button];
		
		(button.alphaValue) = 0.0;
		(button.animator.alphaValue) = 1.0;
		
		(constraint.constant) = constraintStartValue;
		(constraint.animator.constant) = 0.0;
	} completionHandler:^ {
		[self didEndAnimating];
	}];
}

- (void)animateOutButton:(GLAButton *)button duration:(NSTimeInterval)duration constraintIdentifier:(NSString *)constraintIdentifier constraintEndValue:(CGFloat)constraintEndValue completionHandler:(dispatch_block_t)completionHandler
{
	GLAViewController *vc = (self.viewController);
	
	[self willBeginAnimating];
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = duration;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		NSLayoutConstraint *constraint = [vc layoutConstraintWithIdentifier:constraintIdentifier forChildView:button];
		
		(button.animator.alphaValue) = 0.0;
		
		(constraint.animator.constant) = constraintEndValue;
	} completionHandler:^ {
		[button removeFromSuperview];
		
		completionHandler();
		
		[self didEndAnimating];
	}];
}

- (void)animateButtonsIn
{
	GLAButton *leadingButton = (self.leadingButton);
	GLAButton *centerButton = (self.centerButton);
	GLAButton *trailingButton = (self.trailingButton);
	
	if (leadingButton) {
		[self animateInButton:leadingButton duration:(self.leadingButtonInDuration) constraintIdentifier:@"leading" constraintStartValue:-250.0];
	}
	
	if (centerButton) {
		[self animateInButton:centerButton duration:(self.centerButtonInDuration) constraintIdentifier:@"top" constraintStartValue:50.0];
	}
	
	if (trailingButton) {
		[self animateInButton:trailingButton duration:(self.trailingButtonInDuration) constraintIdentifier:@"trailing" constraintStartValue:250.0];
	}
}

- (void)animateButtonsOutWithCompletionHandler:(dispatch_block_t)completionHandler
{
	GLAButton *leadingButton = (self.leadingButton);
	GLAButton *centerButton = (self.centerButton);
	GLAButton *trailingButton = (self.trailingButton);
	__block NSUInteger buttonsAnimating = 0;
	
	dispatch_block_t individualButtonCompletionHandler = ^{
		buttonsAnimating--;
		if (buttonsAnimating == 0) {
			completionHandler();
		}
	};
	
	if (leadingButton) {
		buttonsAnimating++;
		[self animateOutButton:leadingButton duration:(self.leadingButtonInDuration) constraintIdentifier:@"leading" constraintEndValue:-250.0 completionHandler:individualButtonCompletionHandler];
	}
	
	if (centerButton) {
		buttonsAnimating++;
		[self animateOutButton:centerButton duration:(self.centerButtonInDuration) constraintIdentifier:@"top" constraintEndValue:50.0 completionHandler:individualButtonCompletionHandler];
	}
	
	if (trailingButton) {
		buttonsAnimating++;
		[self animateOutButton:trailingButton duration:(self.trailingButtonInDuration) constraintIdentifier:@"trailing" constraintEndValue:250.0 completionHandler:individualButtonCompletionHandler];
	}
	
	if (buttonsAnimating == 0) {
		completionHandler();
	}
}

@end
