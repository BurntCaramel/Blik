//
//  GLAPreferencesChooseSectionViewController.m
//  Blik
//
//  Created by Patrick Smith on 10/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAPreferencesChooseSectionViewController.h"
#import "GLAUIStyle.h"
#import "GLAApplicationSettingsManager.h"
#import "GLAStatusItemController.h"


@interface GLAPreferencesChooseSectionViewController ()

@end

@implementation GLAPreferencesChooseSectionViewController

- (GLAStatusItemController *)statusItemController
{
	return [GLAStatusItemController sharedStatusItemController];
}

- (GLAApplicationSettingsManager *)applicationSettingsManager
{
	return [GLAApplicationSettingsManager sharedApplicationSettingsManager];
}

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	
	[style prepareSecondaryInstructionalTextLabel:(self.editPermittedApplicationFoldersLabel)];
	
	[style prepareCheckButton:(self.showStatusMenuItemCheckButton)];
	[style prepareCheckButton:(self.hideMainWindowWhenInactiveCheckButton)];
	
	[self setUpNotifications];
	
	[self updateUIForShowsStatusMenuItem];
	[self updateUIForHidesMainWindowWhenInactive];
}

- (void)setUpNotifications
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	GLAStatusItemController *statusItemController = (self.statusItemController);
	[nc addObserver:self selector:@selector(statusItemControllerItemShowsItemChangedNotification:) name:GLAStatusItemControllerItemShowsItemChangedNotification object:statusItemController];
	
	GLAApplicationSettingsManager *settingsManager = (self.applicationSettingsManager);
	[nc addObserver:self selector:@selector(hideMainWindowWhenInactiveSettingDidChangeNotification:) name:GLAApplicationSettingsManagerHideMainWindowWhenInactiveDidChangeNotification object:settingsManager];
}

- (void)updateUIForShowsStatusMenuItem
{
	BOOL showsItem = (self.statusItemController.showsItem);
	(self.showStatusMenuItemCheckButton.state) = (showsItem ? NSOnState : NSOffState);
}

- (void)updateUIForHidesMainWindowWhenInactive
{
	BOOL hidesMainWindowWhenInactive = (self.applicationSettingsManager.hidesMainWindowWhenInactive);
	(self.hideMainWindowWhenInactiveCheckButton.state) = (hidesMainWindowWhenInactive ? NSOnState : NSOffState);
}

- (void)statusItemControllerItemShowsItemChangedNotification:(NSNotification *)note
{
	[self updateUIForShowsStatusMenuItem];
}

- (void)hideMainWindowWhenInactiveSettingDidChangeNotification:(NSNotification *)note
{
	[self updateUIForHidesMainWindowWhenInactive];
}

- (IBAction)toggleShowStatusMenuItem:(id)sender
{
	[(self.statusItemController) toggleShowingItem:sender];
}

- (IBAction)toggleHideMainWindowWhenInactive:(id)sender
{
	[(self.applicationSettingsManager) toggleHidesMainWindowWhenInactive:sender];
}

- (void)notifyDelegateToGoToSectionWithIdentifier:(NSString *)sectionIdentifier
{
	id<GLAPreferencesChooseSectionViewControllerDelegate> delegate = (self.delegate);
	if (!delegate) {
		return;
	}
	
	[delegate preferencesChooseSectionViewControllerDelegate:self goToSectionWithIdentifier:sectionIdentifier];
}

- (IBAction)goToEditPermittedApplicationFolders:(id)sender
{
	[self notifyDelegateToGoToSectionWithIdentifier:(self.editPermittedApplicationFoldersButtonIdentifier)];
}

@end
