//
//  GLAProjectActionsBarController.m
//  Blik
//
//  Created by Patrick Smith on 14/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAProjectActionsBarController.h"
#import "GLAUIStyle.h"

@interface GLAProjectActionsBarController ()

@property(nonatomic) BOOL editingItems;
@property(nonatomic) BOOL editingPlan;

@end

@implementation GLAProjectActionsBarController

- (void)loadView
{
	[super loadView];
	
	[self setUpBaseUI];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self setUpBaseUI];
}

- (void)setUpBaseUI
{
	NSColor *activeBarTextColor = ([GLAUIStyle activeStyle].activeBarTextColor);
	(self.finishEditingItemsButton.textHighlightColor) = activeBarTextColor;
	(self.finishEditingPlanButton.textHighlightColor) = activeBarTextColor;
	
	[self setUpNormalView];
}

- (void)setUpNormalView
{
	GLAView *normalView = (self.normalView);
	
	(normalView.wantsLayer) = YES;
	//(normalView.canDrawSubviewsIntoLayer) = YES;
	
	[self fillViewWithChildView:normalView];
}

- (BOOL)setUpEditingItemsViewIfNeeded
{
	GLAView *editingItemsView = (self.editingItemsView);
	if (editingItemsView.superview) {
		return NO;
	}
	
	(editingItemsView.wantsLayer) = YES;
	//(editingItemsView.canDrawSubviewsIntoLayer) = YES;
	(editingItemsView.layer.backgroundColor) = ([GLAUIStyle activeStyle].activeBarBackgroundColor.CGColor);
	
	[self fillViewWithChildView:editingItemsView];
	
	return YES;
}

- (BOOL)setUpEditingPlanViewIfNeeded
{
	GLAView *editingPlanView = (self.editingPlanView);
	if (editingPlanView.superview) {
		return NO;
	}
	
	(editingPlanView.layer.backgroundColor) = ([GLAUIStyle activeStyle].activeBarBackgroundColor.CGColor);
	[self fillViewWithChildView:editingPlanView];
	
	return YES;
}

- (BOOL)showingNormalView
{
	return !((self.editingItems) || (self.editingPlan));
}

- (void)animateNormalView
{
	//NSLayoutConstraint *normalTopConstraint = [self layoutConstraintWithIdentifier:@"top" insideView:(self.normalView)];
	if (self.showingNormalView) {
		(self.normalView.hidden) = NO;
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 2.5 / 12.0;
			
			(self.normalView.animator.alphaValue) = 1.0;
			//(normalTopConstraint.constant) = 50;
		} completionHandler:nil];
	}
	else {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 2.5 / 12.0;
			
			(self.normalView.animator.alphaValue) = 0.0;
			//(normalTopConstraint.constant) = 0;
		} completionHandler:^ {
			if (self.showingNormalView) {
				(self.normalView.hidden) = YES;
			}
		}];
	}
}

- (void)animateEditingItemsView
{
	NSLayoutConstraint *editingItemsTopConstraint = [self layoutConstraintWithIdentifier:@"top" forChildView:(self.editingItemsView)];
	
	if (self.editingItems) {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 3.5 / 12.0;
			
			(editingItemsTopConstraint.animator.constant) = 0;
		} completionHandler:nil];
	}
	else {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 5.0 / 12.0;
			
			(editingItemsTopConstraint.animator.constant) = 50;
		} completionHandler:nil];
	}
}

- (void)animateEditingPlanView
{
	NSLayoutConstraint *editingPlanTopConstraint = [self layoutConstraintWithIdentifier:@"top" forChildView:(self.editingPlanView)];
	
	if (self.editingPlan) {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 3.5 / 12.0;
			
			(editingPlanTopConstraint.animator.constant) = 0;
		} completionHandler:nil];
	}
	else {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = 5.0 / 12.0;
			
			(editingPlanTopConstraint.animator.constant) = 50;
		} completionHandler:nil];
	}
}

- (void)showBarForEditingItems
{
	// Layout editing bar now if it's being added for the first time.
	if ([self setUpEditingItemsViewIfNeeded]) {
		[self updateConstraintsNow];
	}
	
	(self.editingItems) = YES;
	
	[self animateEditingItemsView];
	[self animateNormalView];
	
}

- (void)hideBarForEditingItems
{
	(self.editingItems) = NO;
	
	[self animateEditingItemsView];
	[self animateNormalView];
}

- (void)showBarForEditingPlan
{
	// Layout editing bar now if it's being added for the first time.
	if ([self setUpEditingPlanViewIfNeeded]) {
		[self updateConstraintsNow];
	}
	
	(self.editingPlan) = YES;
	
	[self animateEditingPlanView];
	[self animateNormalView];
	
}

- (void)hideBarForEditingPlan
{
	(self.editingPlan) = NO;
	
	[self animateEditingPlanView];
	[self animateNormalView];
}

- (void)viewUpdateConstraints:(GLAView *)view
{
	NSLayoutConstraint *editingItemsTopConstraint = [self layoutConstraintWithIdentifier:@"top" forChildView:(self.editingItemsView)];
	if (self.editingItems) {
		(editingItemsTopConstraint.constant) = 0;
		//(self.editingItemsView.alphaValue) = 1.0;
	}
	else if (editingItemsTopConstraint) {
		//(self.editingItemsView.alphaValue) = 0.0;
		(editingItemsTopConstraint.constant) = 50;
	}
	
	NSLayoutConstraint *editingPlanTopConstraint = [self layoutConstraintWithIdentifier:@"top" forChildView:(self.editingPlanView)];
	if (self.editingPlan) {
		(editingPlanTopConstraint.constant) = 0;
		//(self.editingPlanView.alphaValue) = 1.0;
	}
	else if (editingPlanTopConstraint) {
		//(self.editingPlanView.alphaValue) = 0.0;
		(editingPlanTopConstraint.constant) = 50;
	}
}

@end
