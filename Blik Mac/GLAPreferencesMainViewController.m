//
//  GLAPreferencesMainViewController.m
//  Blik
//
//  Created by Patrick Smith on 9/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAPreferencesMainViewController.h"
#import "GLAUIStyle.h"


@interface GLAPreferencesMainViewController () <GLAPreferencesChooseSectionViewControllerDelegate>

@end

@implementation GLAPreferencesMainViewController

- (void)dealloc
{
	(self.sectionNavigator) = nil; // Removes receiver as notification observer.
}

- (void)prepareView
{
	NSView *view = (self.view);
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	
	(view.wantsLayer) = YES;
	(view.layer.backgroundColor) = (style.contentBackgroundColor.CGColor);
}

- (void)setSectionNavigator:(GLAPreferencesSectionNavigator *)sectionNavigator
{
	_sectionNavigator = sectionNavigator;
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if (sectionNavigator) {
		[nc addObserver:self selector:@selector(navigatorDidChangeCurrentSection:) name:GLAPreferencesSectionNavigatorCurrentSectionDidChangeNotificiation object:sectionNavigator];
	}
	else {
		[nc removeObserver:self name:GLAPreferencesSectionNavigatorCurrentSectionDidChangeNotificiation object:nil];
	}
}

#pragma mark -

- (void)navigatorDidChangeCurrentSection:(NSNotification *)note
{
	GLAPreferencesSectionNavigator *sectionNavigator = (self.sectionNavigator);
	[self didChangeCurrentSectionFrom:(sectionNavigator.previousSectionIdentifier) to:(sectionNavigator.currentSectionIdentifier)];
}

#pragma mark -

@synthesize chooseSectionViewController = _chooseSectionViewController;

- (GLAPreferencesChooseSectionViewController *)chooseSectionViewController
{
	if (!_chooseSectionViewController) {
		GLAPreferencesChooseSectionViewController *chooseSectionViewController = [[GLAPreferencesChooseSectionViewController alloc] initWithNibName:NSStringFromClass([GLAPreferencesChooseSectionViewController class]) bundle:nil];
		(chooseSectionViewController.delegate) = self;
		
		(chooseSectionViewController.editPermittedApplicationFoldersButtonIdentifier) = GLAPreferencesSectionEditPermittedApplicationFolders;
		
		_chooseSectionViewController = chooseSectionViewController;
	}
	
	return _chooseSectionViewController;
}

@synthesize editPermittedApplicationFoldersViewController = _editPermittedApplicationFoldersViewController;

- (GLAEditPermittedApplicationFoldersViewController *)editPermittedApplicationFoldersViewController
{
	if (!_editPermittedApplicationFoldersViewController) {
		_editPermittedApplicationFoldersViewController = [[GLAEditPermittedApplicationFoldersViewController alloc] initWithNibName:NSStringFromClass([GLAEditPermittedApplicationFoldersViewController class]) bundle:nil];
	}
	
	return _editPermittedApplicationFoldersViewController;
}

- (NSInteger)depthForSectionWithIdentifier:(NSString *)sectionIdentifier
{
	if ([sectionIdentifier isEqualToString:GLAPreferencesSectionChoose]) {
		return 0;
	}
	else if ([sectionIdentifier isEqualToString:GLAPreferencesSectionEditPermittedApplicationFolders]) {
		return 1;
	}
	
	return 0;
}

- (GLAViewController *)viewControllerForSectionWithIdentifier:(NSString *)sectionIdentifier
{
	if ([sectionIdentifier isEqualToString:GLAPreferencesSectionChoose]) {
		return (self.chooseSectionViewController);
	}
	else if ([sectionIdentifier isEqualToString:GLAPreferencesSectionEditPermittedApplicationFolders]) {
		return (self.editPermittedApplicationFoldersViewController);
	}
	
	return nil;
}

- (void)didChangeCurrentSectionFrom:(NSString *)previousSectionIdentifier to:(NSString *)currentSectionIdentifier
{
	GLAViewController *vcOut = [self viewControllerForSectionWithIdentifier:previousSectionIdentifier];
	GLAViewController *vcIn = [self viewControllerForSectionWithIdentifier:currentSectionIdentifier];
	
	if (!vcIn) {
		return;
	}
	
	BOOL animate = (previousSectionIdentifier != nil);
	
	NSTimeInterval duration = animate ? 7.0/16.0 : 0.0;
	
	NSInteger depthIn = [self depthForSectionWithIdentifier:currentSectionIdentifier];
	NSInteger depthOut = [self depthForSectionWithIdentifier:previousSectionIdentifier];
	
	CGFloat movementPerDepth = 500.0;
	
	CGFloat constraintInStartValue = (depthIn - depthOut) * movementPerDepth;
	CGFloat constraintInFinishValue = 0.0;
	
	CGFloat constraintOutStartValue = 0.0;
	CGFloat constraintOutFinishValue = (depthOut - depthIn) * movementPerDepth;
	
	NSView *viewOut = nil;
	NSLayoutConstraint *constraintOut = nil;
	
	if (vcOut) {
		viewOut = (vcOut.view);
		constraintOut = [self layoutConstraintWithIdentifier:@"leading" forChildView:viewOut];
		
		//[vcOut transitionOutWithDuration:duration adjustingConstraint:constraintOut fromValue:0.0 toValue:-500.0 removeWhenCompleteHandler:nil];
	}
	
	
	NSView *viewIn = (vcIn.view);
	if (!(viewIn.superview)) {
		[self fillViewWithChildView:viewIn];
	}
	
	BOOL viewInWantsLayer = (viewIn.wantsLayer);
	(viewIn.wantsLayer) = YES;
	
	NSLayoutConstraint *constraintIn = [self layoutConstraintWithIdentifier:@"leading" forChildView:viewIn];
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 0.0;
		//(context.allowsImplicitAnimation) = YES;
		
		[vcIn viewWillTransitionIn];
		(viewIn.animator.alphaValue) = 0.0;
		
		(constraintIn.animator.constant) = constraintInStartValue;
		
		if (vcOut) {
			[vcOut viewWillTransitionOut];
			(viewOut.animator.alphaValue) = 1.0;
			(constraintOut.animator.constant) = constraintOutStartValue;
		}
	} completionHandler:^{
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			(context.duration) = duration;
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			(viewIn.animator.alphaValue) = 1.0;
			(constraintIn.animator.constant) = constraintInFinishValue;
			
			if (vcOut) {
				(viewOut.animator.alphaValue) = 0.0;
				(constraintOut.animator.constant) = constraintOutFinishValue;
			}
		} completionHandler:^ {
			(viewIn.wantsLayer) = viewInWantsLayer;
			
			[vcIn viewDidTransitionIn];
			
			if (vcOut) {
				[viewOut removeFromSuperview];
				[vcOut viewDidTransitionIn];
			}
		}];
	}];
	
	//[vcIn transitionInWithDuration:duration adjustingConstraint:constraintIn fromValue:500.0 toValue:0.0 isActiveChecker:nil completionHandler:nil];
}

#pragma mark - GLAPreferencesChooseSectionViewControllerDelegate

- (void)preferencesChooseSectionViewControllerDelegate:(GLAPreferencesChooseSectionViewController *)vc goToSectionWithIdentifier:(NSString *)sectionIdentifier
{
	[(self.sectionNavigator) goToSectionWithIdentifier:sectionIdentifier];
}

@end
