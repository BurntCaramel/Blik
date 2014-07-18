//
//  GLAMainNavigationBarController.m
//  Blik
//
//  Created by Patrick Smith on 10/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAMainNavigationBarController.h"
@import QuartzCore;

@interface GLAMainNavigationBarController ()

@property(nonatomic) BOOL private_enabled;

@property(nonatomic, getter = isAnimating) BOOL animating;

@property(readonly, nonatomic) NSString *titleForEditingProjectBackButton;

@end

@implementation GLAMainNavigationBarController

- (GLAPrototypeBNavigationBar *)navigationBar
{
	return (GLAPrototypeBNavigationBar *)(self.view);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		(self.currentSection) = GLAMainNavigationSectionToday;
		[self updateSelectedSectionUI];
		(self.private_enabled) = YES;
    }
    return self;
}

- (void)loadView
{
	[super loadView];
	
	(self.navigationBar.delegate) = self;
}

- (void)updateSelectedSectionUI
{
	GLAMainNavigationSection currentSection = (self.currentSection);
	(self.allButton.state) = (currentSection == GLAMainNavigationSectionAll) ? NSOnState : NSOffState;
	(self.todayButton.state) = (currentSection == GLAMainNavigationSectionToday) ? NSOnState : NSOffState;
	(self.plannedButton.state) = (currentSection == GLAMainNavigationSectionPlanned) ? NSOnState : NSOffState;
}

- (void)changeCurrentSectionTo:(GLAMainNavigationSection)newSection
{
	if (self.isAnimating) {
		return;
	}
	
	(self.currentSection) = newSection;
	
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainNavigationBarController:self didChangeCurrentSection:newSection];
	}
	
	[self updateSelectedSectionUI];
}

- (IBAction)goToAll:(id)sender
{
	[self changeCurrentSectionTo:GLAMainNavigationSectionAll];
}

- (IBAction)goToToday:(id)sender
{
	[self changeCurrentSectionTo:GLAMainNavigationSectionToday];
}

- (IBAction)goToPlanned:(id)sender
{
	[self changeCurrentSectionTo:GLAMainNavigationSectionPlanned];
}

- (NSString *)titleForEditingProjectBackButton
{
	GLAMainNavigationSection currentSection = (self.currentSection);
	if (currentSection == GLAMainNavigationSectionAll) {
		return NSLocalizedString(@"Back to All Projects", @"Title for editing project back button to go back to all projects");
	}
	else if (currentSection == GLAMainNavigationSectionPlanned) {
		return NSLocalizedString(@"Back to Planned Projects", @"Title for editing project back button to go back to planned projects");
	}
	else {
		return nil;
	}
}

- (void)enterProject:(id)project
{
	(self.currentProject) = project;
	
	(self.editingProjectBackButton.title) = (self.titleForEditingProjectBackButton);
	
	(self.animating) = YES;
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 12.0;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		
		(self.allButtonTopConstraint.animator.constant) = -50;
		(self.todayButtonTopConstraint.animator.constant) = -50;
		(self.plannedButtonTopConstraint.animator.constant) = -50;
		(self.addProjectButtonTopConstraint.animator.constant) = -50;
		
		(self.editingProjectBackButton.animator.alphaValue) = 1.0;
	} completionHandler:^ {
		(self.animating) = NO;
	}];
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 12.0;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		
		(self.editingProjectBackButtonLeadingConstraint.animator.constant) = 0;
	} completionHandler:nil];
}

- (IBAction)exitCurrentProject:(id)sender
{
	if (self.isAnimating) {
		return;
	}
	
	(self.animating) = YES;
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 12.0;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		(self.allButtonTopConstraint.animator.constant) = 0;
		(self.todayButtonTopConstraint.animator.constant) = 0;
		(self.plannedButtonTopConstraint.animator.constant) = 0;
		(self.addProjectButtonTopConstraint.animator.constant) = 0;
		
		(self.editingProjectBackButton.animator.alphaValue) = 0.0;
	} completionHandler:^ {
		(self.animating) = NO;
	}];
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 4.0 / 12.0;
		(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		
		(self.editingProjectBackButtonLeadingConstraint.animator.constant) = -200;
	} completionHandler:nil];
	
	id<GLAMainNavigationBarControllerDelegate> delegate = (self.delegate);
	if (delegate) {
		[delegate mainNavigationBarController:self didExitProject:(self.currentProject)];
	}
	
	(self.currentProject) = nil;
}

- (void)setEnabled:(BOOL)enabled
{
	if (enabled != (self.private_enabled)) {
		(self.private_enabled) = enabled;
		
		(self.allButton.enabled) = enabled;
		(self.todayButton.enabled) = enabled;
		(self.plannedButton.enabled) = enabled;
		(self.addProjectButton.enabled) = enabled;
		(self.editingProjectBackButton.enabled) = enabled;
	}
}

- (BOOL)isEnabled
{
	return (self.private_enabled);
}

- (void)viewUpdateConstraints:(GLAPrototypeBNavigationBar *)view
{
	if (self.currentProject) {
		(self.editingProjectBackButton.alphaValue) = 1.0;
		(self.editingProjectBackButtonLeadingConstraint.constant) = 0;
	}
	else {
		(self.editingProjectBackButton.alphaValue) = 0.0;
		(self.editingProjectBackButtonLeadingConstraint.constant) = -200;
	}
}

@end
