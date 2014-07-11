//
//  GLAPrototypeBWindowController.m
//  Glance Prototype A
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAPrototypeBWindowController.h"
#import "GLAUIStyle.h"


@interface GLAPrototypeBWindowController ()

@end

@implementation GLAPrototypeBWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        (self.currentSection) = GLAMainNavigationSectionToday;
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	(self.window.movableByWindowBackground) = YES;
	
	[self setUpBaseUI];
	
	[self setUpMainNavigationBarController];
	[self setUpProjectViewController];
}

- (void)setUpBaseUI
{
	(self.barHolderView.translatesAutoresizingMaskIntoConstraints) = NO;
	(self.contentView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	NSView *contentView = (self.contentView);
	(contentView.wantsLayer) = YES;
	(contentView.layer.backgroundColor) = ([GLAUIStyle styleA].contentBackgroundColor.CGColor);
}

- (NSString *)layoutContraintIdentifierWithBase:(NSString *)baseIdentifier inView:(NSView *)view
{
	return [NSString stringWithFormat:@"%@--%@", (view.identifier), baseIdentifier];
}

- (NSLayoutConstraint *)layoutConstraintWithBaseIdentifier:(NSString *)baseIdentifier view:(NSView *)view inHolderView:(NSView *)holderView
{
	NSString *constraintIdentifier = [self layoutContraintIdentifierWithBase:baseIdentifier inView:view];
	NSArray *leadingConstraintInArray = [(holderView.constraints) filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", constraintIdentifier]];
	
	if (leadingConstraintInArray.count == 0) {
		return nil;
	}
	else {
		return leadingConstraintInArray[0];
	}
}

- (void)setUpViewController:(NSViewController *)viewController constrainedToFillView:(NSView *)holderView
{
	(viewController.nextResponder) = self;
	
	NSView *view = (viewController.view);
	
	if (holderView) {
		[holderView addSubview:view];
		
		(view.translatesAutoresizingMaskIntoConstraints) = NO;
		
		NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:holderView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
		NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:holderView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
		NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:holderView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];
		NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:holderView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
		
		(leadingConstraint.identifier) = [self layoutContraintIdentifierWithBase:@"leading" inView:view];
		(topConstraint.identifier) = [self layoutContraintIdentifierWithBase:@"top" inView:view];
		
		[holderView addConstraints:@[widthConstraint, heightConstraint, leadingConstraint, topConstraint]];
		
		/*
		[holderView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[innerView]|" options:NSLayoutConstraintOrientationHorizontal metrics:nil views:@{@"innerView": view}]];
		[holderView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[innerView]|" options:NSLayoutConstraintOrientationVertical metrics:nil views:@{@"innerView": view}]];
		 */
	}
}

- (void)setUpMainNavigationBarController
{
	if (!(self.mainNavigationBarController)) {
		GLAMainNavigationBarController *controller = [[GLAMainNavigationBarController alloc] initWithNibName:@"GLAMainNavigationBarController" bundle:nil];
		(controller.delegate) = self;
		
		(self.mainNavigationBarController) = controller;
	}
	
	[self setUpViewController:(self.mainNavigationBarController) constrainedToFillView:(self.barHolderView)];
	
}

- (void)setUpProjectViewController
{
	if (!(self.projectViewController)) {
		(self.projectViewController) = [[GLAPrototypeBProjectViewController alloc] initWithNibName:@"GLAPrototypeBProjectViewController" bundle:nil];
	}
	
	[self setUpViewController:(self.projectViewController) constrainedToFillView:(self.contentView)];
}

- (void)mainNavigationBarController:(GLAMainNavigationBarController *)controller didChangeCurrentSection:(GLAMainNavigationSection)newSection
{
	GLAMainNavigationSection previousSection = (self.currentSection);
	if (previousSection == GLAMainNavigationSectionToday) {
		[self hideProjectView];
	}
	
	(self.currentSection) = newSection;
	
	if (newSection == GLAMainNavigationSectionToday) {
		[self showProjectView];
		//[self hideProjectView];
	}
}

- (void)hideProjectView
{
	[self hideChildContentView:(self.projectViewController.view) offBy:500.0];
}

- (void)showProjectView
{
	[self showChildContentView:(self.projectViewController.view)];
}

- (NSTimeInterval)contentViewTransitionDurationGoingInNotOut:(BOOL)inNotOut
{
	// IN
	if (inNotOut) {
		return 5.0 / 12.0;
	}
	// OUT
	else {
		return 5.0 / 12.0;
	}
}

- (void)hideChildContentView:(NSView *)view offBy:(CGFloat)offset
{
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithBaseIdentifier:@"leading" view:view inHolderView:(self.contentView)];
	if (!leadingConstraint) {
		return;
	}
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		NSLog(@"HIDE RUNNING");
		(context.duration) = [self contentViewTransitionDurationGoingInNotOut:NO];
		(view.animator.alphaValue) = 0.0;
		(leadingConstraint.animator.constant) = offset;
		
		//(context.allowsImplicitAnimation) = YES;
		//[view layoutSubtreeIfNeeded];
	} completionHandler:^ {
		// If the current section hasn't been changed back before the animation finishes:
		if ((self.currentSection) != GLAMainNavigationSectionToday) {
			(view.hidden) = YES;
		}
		NSLog(@"HIDE COMPLETED");
	}];
}

- (void)showChildContentView:(NSView *)view
{
	NSLayoutConstraint *leadingConstraint = [self layoutConstraintWithBaseIdentifier:@"leading" view:view inHolderView:(self.contentView)];
	if (!leadingConstraint) {
		return;
	}
	/*
	// Run a zero duration animation to get any previous ones to complete.
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 0;
		(view.hidden) = NO;
	} completionHandler:nil];
	*/
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		NSLog(@"SHOW RUNNING %f %f %@", (leadingConstraint.constant), (leadingConstraint.animator.constant), (leadingConstraint.animations));
		CGFloat fractionFromDestination = ((leadingConstraint.constant) / (leadingConstraint.animator.constant));
		NSLog(@"%f", fractionFromDestination);
		
		(context.duration) = fractionFromDestination * [self contentViewTransitionDurationGoingInNotOut:YES];
		(view.hidden) = NO;
		(view.animator.alphaValue) = 1.0;
		(leadingConstraint.animator.constant) = 0.0;
		
		//(context.allowsImplicitAnimation) = YES;
		//[view layoutSubtreeIfNeeded];
	} completionHandler:^ {
		NSLog(@"SHOW COMPLETED");
	}];
}

@end
