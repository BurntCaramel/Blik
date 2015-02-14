//
//  GLAPreferencesChooseSectionViewController.m
//  Blik
//
//  Created by Patrick Smith on 10/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAPreferencesChooseSectionViewController.h"
#import "GLAUIStyle.h"
#import "GLAStatusItemController.h"


@interface GLAPreferencesChooseSectionViewController ()

@end

@implementation GLAPreferencesChooseSectionViewController

- (GLAStatusItemController *)statusItemController
{
	return [GLAStatusItemController sharedStatusItemController];
}

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	
	[style prepareSecondaryInstructionalTextLabel:(self.editPermittedApplicationFoldersLabel)];
	
	[style prepareCheckButton:(self.showStatusMenuItemCheckButton)];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	GLAStatusItemController *statusItemController = (self.statusItemController);
	[nc addObserver:self selector:@selector(statusItemControllerItemShowsItemChangedNotification:) name:GLAStatusItemControllerItemShowsItemChangedNotification object:statusItemController];
	
	[self updateUIForShowsStatusMenuItem];
}

- (void)updateUIForShowsStatusMenuItem
{
	BOOL showsItem = (self.statusItemController.showsItem);
	(self.showStatusMenuItemCheckButton.state) = (showsItem ? NSOnState : NSOffState);
}

- (void)statusItemControllerItemShowsItemChangedNotification:(NSNotification *)note
{
	[self updateUIForShowsStatusMenuItem];
}

- (IBAction)toggleShowStatusMenuItem:(id)sender
{
	[(self.statusItemController) toggleShowingItem:sender];
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
