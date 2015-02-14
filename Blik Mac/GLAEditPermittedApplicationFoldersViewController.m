//
//  GLAEditPermittedApplicationFoldersViewController.m
//  Blik
//
//  Created by Patrick Smith on 6/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAEditPermittedApplicationFoldersViewController.h"
#import "GLAApplicationSettingsManager.h"


@interface GLAEditPermittedApplicationFoldersViewController ()

@end

@implementation GLAEditPermittedApplicationFoldersViewController

- (void)dealloc
{
	[self stopApplicationSettingsManagerObserving];
}

- (void)prepareView
{
	[super prepareView];
	
	NSView *view = (self.view);
	(view.wantsLayer) = YES;
	(view.canDrawSubviewsIntoLayer) = YES;
	
	[self startApplicationSettingsManagerObserving];
}

#pragma mark -

- (GLAApplicationSettingsManager *)applicationSettingsManager
{
	return [GLAApplicationSettingsManager sharedApplicationSettingsManager];
}

- (void)startApplicationSettingsManagerObserving
{
	GLAApplicationSettingsManager *applicationSettingsManager = (self.applicationSettingsManager);
	if (!applicationSettingsManager) {
		return;
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self selector:@selector(permittedApplicationFoldersDidChangeNotification:) name:GLAApplicationSettingsManagerPermittedApplicationFoldersDidChangeNotification object:applicationSettingsManager];
}

- (void)stopApplicationSettingsManagerObserving
{
	GLAApplicationSettingsManager *applicationSettingsManager = (self.applicationSettingsManager);
	if (!applicationSettingsManager) {
		return;
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc removeObserver:self name:nil object:applicationSettingsManager];
}

#pragma mark - Model Notifications

- (void)permittedApplicationFoldersDidChangeNotification:(NSNotification *)note
{
	[self reloadFolders];
}

#pragma mark -

- (BOOL)canViewFolders
{
	return (self.applicationSettingsManager) != nil;
}

- (BOOL)hasLoadedFolders
{
	GLAApplicationSettingsManager *applicationSettingsManager = (self.applicationSettingsManager);
	if (!applicationSettingsManager) {
		return NO;
	}
	
	return [applicationSettingsManager hasLoadedPermittedApplicationFolders];
}

- (NSArray *)copyFolders
{
	GLAApplicationSettingsManager *applicationSettingsManager = (self.applicationSettingsManager);
	if (!applicationSettingsManager) {
		return nil;
	}
	
	[applicationSettingsManager loadPermittedApplicationFolders];
	return [applicationSettingsManager copyPermittedApplicationFolders];
}

- (void)makeChangesToFoldersUsingEditingBlock:(GLAArrayEditingBlock)editingBlock
{
	GLAApplicationSettingsManager *applicationSettingsManager = (self.applicationSettingsManager);
	if (!applicationSettingsManager) {
		return;
	}
	
	[applicationSettingsManager editPermittedApplicationFoldersUsingBlock:editingBlock];
}

#pragma mark -

@end
