//
//  GLAProjectsListMenuController.m
//  Blik
//
//  Created by Patrick Smith on 8/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAProjectsListMenuController.h"
#import "GLAProjectManager.h"
#import "GLAMainSectionNavigator.h"
#import "GLAProjectMenuController.h"
#import "GLAUIStyle.h"


@interface GLAProjectsListMenuController ()

@property(nonatomic) id<GLALoadableArrayUsing> allProjectsUser;
@property(nonatomic) NSCache *projectMenuControllerCache;

@end

@implementation GLAProjectsListMenuController

- (instancetype)initWithMenu:(NSMenu *)menu
{
	self = [super init];
	if (self) {
		_menu = menu;
		(menu.delegate) = self;
		
		_projectMenuControllerCache = [NSCache new];
	}
	return self;
}

- (GLAProjectManager *)projectManager
{
	return [GLAProjectManager sharedProjectManager];
}

- (GLAMainSectionNavigator *)mainSectionNavigator
{
	return [GLAMainSectionNavigator sharedMainSectionNavigator];
}

#pragma mark -

- (id<GLALoadableArrayUsing>)useAllProjects
{
	id<GLALoadableArrayUsing> allProjectsUser = (self.allProjectsUser);
	if (!allProjectsUser) {
		GLAProjectManager *pm = (self.projectManager);
		allProjectsUser = [pm useAllProjects];
		
		NSMenu *menu = (self.menu);
		
		(allProjectsUser.changeCompletionBlock) = ^(id<GLAArrayInspecting>array) {
			[menu update];
		};
		
		[allProjectsUser inspectLoadingIfNeeded];
	}
	
	return allProjectsUser;
}

#pragma mark Actions

- (void)activateApplication
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (IBAction)openProject:(NSMenuItem *)sender
{
	GLAProject *project = (sender.representedObject);
	
	GLAMainSectionNavigator *navigator = (self.mainSectionNavigator);
	[navigator goToProject:project];
	
	[self activateApplication];
}

- (IBAction)createNewProject:(id)sender
{
	GLAMainSectionNavigator *navigator = (self.mainSectionNavigator);
	[navigator addNewProject];
	
	[self activateApplication];
}

- (IBAction)goToAllProjects:(id)sender
{
	GLAMainSectionNavigator *navigator = (self.mainSectionNavigator);
	[navigator goToAllProjects];
	
	[self activateApplication];
}

#pragma mark Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{
#if 1
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	(menu.font) = (style.menuFont);
#endif
	
	id<GLALoadableArrayUsing> allProjectsUser = [self useAllProjects];
	
	if (allProjectsUser.finishedLoading) {
		[menu removeAllItems];
		
		id<GLAArrayInspecting> arrayInspector = (allProjectsUser.inspectLoadingIfNeeded);
		
		NSUInteger projectCount = (arrayInspector.childrenCount);
		SEL projectAction = @selector(openProject:);
		
		// For testing:
		//projectCount = 0;
		
		for (NSUInteger projectIndex = 0; projectIndex < projectCount; projectIndex++) {
			GLAProject *project = [arrayInspector childAtIndex:projectIndex];
			
			if (project.hideFromLauncherMenu) {
				continue;
			}
			
			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:(project.name) action:projectAction keyEquivalent:@""];
			(item.representedObject) = project;
			(item.target) = self;
			
			NSUUID *projectUUID = (project.UUID);
			NSCache *projectMenuControllerCache = (self.projectMenuControllerCache);
			GLAProjectMenuController *projectMenuController = [projectMenuControllerCache objectForKey:projectUUID];
			
			// Menus for projects are cached.
			if (projectMenuController) {
				(item.submenu) = (projectMenuController.menu);
			}
			else {
				(item.submenu) = [[NSMenu alloc] initWithTitle:(project.name)];
			}
			
			[menu addItem:item];
		}
		
		if (projectCount == 0) {
			NSMenuItem *noProjectsItem = [menu addItemWithTitle:NSLocalizedString( @"No Projects Yet", @"Menu item for status item menu projects list when there are no projects" ) action:nil keyEquivalent:@""];
			(noProjectsItem.enabled) = NO;
		}
	}
	else {
		[menu removeAllItems];
		[menu addItemWithTitle:NSLocalizedString(@"Loading Projects…", @"Loading menu item for projects list") action:nil keyEquivalent:@""];
	}
	
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	// All Projects
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"All Projects…", @"Status item menu item for going to all projects section" ) action:@selector(goToAllProjects:) keyEquivalent:@""];
	(item.target) = self;
	[menu addItem:item];
	
	// New Project
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"New Project…", @"Status item menu item for creating a new project" ) action:@selector(createNewProject:) keyEquivalent:@""];
	(item.target) = self;
	[menu addItem:item];
}

- (void)menu:(NSMenu *)menu willHighlightItem:(NSMenuItem *)item
{
	if (!item) {
		return;
	}
	
	id representedObject = (item.representedObject);
	if ([representedObject isKindOfClass:[GLAProject class]]) {
		GLAProject *project = representedObject;
		NSMenu *submenu = (item.submenu);
		
		NSCache *projectMenuControllerCache = (self.projectMenuControllerCache);
		
		NSUUID *projectUUID = (project.UUID);
		GLAProjectMenuController *projectMenuController = [projectMenuControllerCache objectForKey:projectUUID];
		if (!projectMenuController) {
			projectMenuController = [[GLAProjectMenuController alloc] initWithMenu:submenu project:project];
			[projectMenuControllerCache setObject:projectMenuController forKey:projectUUID];
		}
		
		[projectMenuController updateMenu];
	}
}

@end
