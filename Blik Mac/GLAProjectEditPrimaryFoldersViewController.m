//
//  GLAProjectEditPrimaryFoldersViewController.m
//  Blik
//
//  Created by Patrick Smith on 17/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAProjectEditPrimaryFoldersViewController.h"
#import "GLACollectedFile.h"
#import "GLAProjectManager.h"
#import "GLAUIStyle.h"
#import "NSTableView+GLAActionHelpers.h"


@implementation GLAProjectEditPrimaryFoldersViewController

- (void)dealloc
{
	[self stopProjectObserving];
}

#pragma mark -

- (GLAProjectManager *)projectManager
{
	return [GLAProjectManager sharedProjectManager];
}

- (void)startProjectObserving
{
	GLAProject *project = (self.project);
	if (!project) {
		return;
	}
	
	GLAProjectManager *pm = (self.projectManager);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	id projectNotifier = [pm notificationObjectForProject:project];
	[nc addObserver:self selector:@selector(primaryFoldersDidChangeNotification:) name:GLAProjectPrimaryFoldersDidChangeNotification object:projectNotifier];
}

- (void)stopProjectObserving
{
	GLAProject *project = (self.project);
	if (!project) {
		return;
	}
	
	GLAProjectManager *pm = (self.projectManager);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Stop observing any notifications on the project manager.
	[nc removeObserver:self name:nil object:[pm notificationObjectForProject:project]];
}

@synthesize project = _project;

- (void)setProject:(GLAProject *)project
{
	if (_project == project) {
		return;
	}
	
	[self stopProjectObserving];
	
	_project = project;
	
	[self startProjectObserving];
	
	[self reloadFolders];
}

#pragma mark - Model Notifications

- (void)primaryFoldersDidChangeNotification:(NSNotification *)note
{
	[self reloadFolders];
}

#pragma mark -

- (BOOL)canViewFolders
{
	return (self.project) != nil;
}

- (BOOL)hasLoadedFolders
{
	GLAProjectManager *pm = (self.projectManager);
	GLAProject *project = (self.project);
	
	return [pm hasLoadedPrimaryFoldersForProject:project];
}

- (NSArray *)copyFolders
{
	GLAProjectManager *pm = (self.projectManager);
	GLAProject *project = (self.project);
	
	[pm loadPrimaryFoldersForProjectIfNeeded:project];
	return [pm copyPrimaryFoldersForProject:project];
}

- (void)makeChangesToFoldersUsingEditingBlock:(GLAArrayEditingBlock)editingBlock
{
	GLAProjectManager *pm = (self.projectManager);
	GLAProject *project = (self.project);
	
	[pm editPrimaryFoldersOfProject:project usingBlock:editingBlock];
}

@end
