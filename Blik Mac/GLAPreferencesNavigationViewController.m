//
//  GLAPreferencesNavigationViewController.m
//  Blik
//
//  Created by Patrick Smith on 10/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAPreferencesNavigationViewController.h"
#import "GLAPreferencesSection.h"
#import "GLANavigationButtonGroup.h"
#import "GLAUIStyle.h"


@interface GLAPreferencesNavigationViewController ()

@property(nonatomic) NSMutableDictionary *sectionIdentifiersToButtonGroups;

@end

@implementation GLAPreferencesNavigationViewController

- (void)dealloc
{
	(self.sectionNavigator) = nil; // Removes receiver as notification observer.
}

- (void)prepareView
{
	[super prepareView];
	
	NSView *view = (self.view);
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	
	(view.wantsLayer) = YES;
	(view.layer.backgroundColor) = (style.contentBackgroundColor.CGColor);
	
	[(self.templateButton) removeFromSuperview];
	
	(self.sectionIdentifiersToButtonGroups) = [NSMutableDictionary new];
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

- (GLANavigationButtonGroup *)createChooseSectionButtonGroup
{
	GLANavigationButtonGroup *buttonGroup = [GLANavigationButtonGroup buttonGroupWithViewController:self templateButton:(self.templateButton)];
	return buttonGroup;
}

- (GLANavigationButtonGroup *)createInsideSectionButtonGroup
{
	GLANavigationButtonGroup *buttonGroup = [GLANavigationButtonGroup buttonGroupWithViewController:self templateButton:(self.templateButton)];
	
	[buttonGroup makeLeadingButtonWithTitle:NSLocalizedString(@"Back to Preferences", @"Button title for back button when inside a preferences section") action:@selector(goBackToChooseSections:) identifier:@"backButton"];
	
	return buttonGroup;
}

#pragma mark -

- (void)navigatorDidChangeCurrentSection:(NSNotification *)note
{
	GLAPreferencesSectionNavigator *sectionNavigator = (self.sectionNavigator);
	[self didChangeCurrentSectionFrom:(sectionNavigator.previousSectionIdentifier) to:(sectionNavigator.currentSectionIdentifier)];
}

#pragma mark -

- (GLANavigationButtonGroup *)buttonGroupForSectionIdentifier:(NSString *)sectionIdentifier create:(BOOL)create
{
	NSMutableDictionary *sectionIdentifiersToButtonGroups = (self.sectionIdentifiersToButtonGroups);
	
	GLANavigationButtonGroup *buttonGroup = sectionIdentifiersToButtonGroups[sectionIdentifier];
	
	if (!buttonGroup && create) {
		if ([sectionIdentifier isEqualToString:GLAPreferencesSectionChoose]) {
			buttonGroup = [self createChooseSectionButtonGroup];
		}
		else if ([sectionIdentifier isEqualToString:GLAPreferencesSectionEditPermittedApplicationFolders]) {
			buttonGroup = [self createInsideSectionButtonGroup];
		}
		
		if (buttonGroup) {
			sectionIdentifiersToButtonGroups[sectionIdentifier] = buttonGroup;
		}
	}
	
	return buttonGroup;
}

- (void)didChangeCurrentSectionFrom:(NSString *)previousSectionIdentifier to:(NSString *)currentSectionIdentifier
{
	GLANavigationButtonGroup *previousButtonGroup = [self buttonGroupForSectionIdentifier:previousSectionIdentifier create:NO];
	GLANavigationButtonGroup *currentButtonGroup = [self buttonGroupForSectionIdentifier:currentSectionIdentifier create:YES];
	
	if (!currentButtonGroup) {
		return;
	}
	
	NSMutableDictionary *sectionIdentifiersToButtonGroups = (self.sectionIdentifiersToButtonGroups);
	
	if (previousButtonGroup) {
		[previousButtonGroup animateButtonsOutWithCompletionHandler:^{
			[sectionIdentifiersToButtonGroups removeObjectForKey:previousSectionIdentifier];
		}];
	}
	
	[currentButtonGroup animateButtonsIn];
}

#pragma mark - Actions

- (IBAction)goBackToChooseSections:(id)sender
{
	[(self.sectionNavigator) goToSectionWithIdentifier:GLAPreferencesSectionChoose];
}

@end
