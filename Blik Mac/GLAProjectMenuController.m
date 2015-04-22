//
//  GLAProjectMenuController.m
//  Blik
//
//  Created by Patrick Smith on 8/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAProjectMenuController.h"
#import "GLAProjectManager.h"
#import "GLAProjectManager+GLAOpeningFiles.h"
#import "GLAMainSectionNavigator.h"
#import "GLACollectedFileListHelper.h"
#import "NSMenu+GLAMenuItemConvenience.h"
#import "GLAUIStyle.h"


@interface GLAProjectMenuController () <GLACollectedFileListHelperDelegate>

@property(nonatomic) id<GLALoadableArrayUsing> highlightsUser;
@property(nonatomic) id<GLALoadableArrayUsing> primaryFoldersUser;
@property(nonatomic) id<GLALoadableArrayUsing> collectionsUser;

@property(nonatomic) GLACollectedFileListHelper *collectedFileListHelper;

@property(nonatomic) BOOL pendingMenuUpdate;

@end

@implementation GLAProjectMenuController

- (instancetype)initWithMenu:(NSMenu *)menu project:(GLAProject *)project
{
	self = [super init];
	if (self) {
		_menu = menu;
		(menu.delegate) = self;
		
		_project = project;
		
		_collectedFileListHelper = [[GLACollectedFileListHelper alloc] initWithDelegate:self];
	}
	return self;
}

- (void)dealloc
{
	[self stopObservingProject];
}

- (GLAProjectManager *)projectManager
{
	return [GLAProjectManager sharedProjectManager];
}

- (GLAMainSectionNavigator *)mainSectionNavigator
{
	return [GLAMainSectionNavigator sharedMainSectionNavigator];
}

- (void)startObservingProject
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	GLAProjectManager *pm = (self.projectManager);
	id projectNotifier = [pm notificationObjectForProject:(self.project)];
	
	[nc addObserver:self selector:@selector(projectAnyCollectionFilesListDidChangeNotification:) name:GLAProjectAnyCollectionFilesListDidChangeNotification object:projectNotifier];
}

- (void)stopObservingProject
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	GLAProjectManager *pm = (self.projectManager);
	id projectNotifier = [pm notificationObjectForProject:(self.project)];
	
	[nc removeObserver:self name:nil object:projectNotifier];
}

#pragma mark -

- (id<GLALoadableArrayUsing>)useHighlights
{
	id<GLALoadableArrayUsing> highlightsUser = (self.highlightsUser);
	if (!highlightsUser) {
		GLAProjectManager *pm = (self.projectManager);
		(self.highlightsUser) = highlightsUser = [pm useHighlightsForProject:(self.project)];
		
		__weak GLAProjectMenuController *weakSelf = self;
		
		(highlightsUser.changeCompletionBlock) = ^(id<GLAArrayInspecting>array) {
			__strong GLAProjectMenuController *self = weakSelf;
			if (!self) {
				return;
			}
			
			[self updateMenu];
		};
	}
	
	return highlightsUser;
}

- (id<GLAArrayInspecting>)inspectHighlights
{
	return [[self useHighlights] inspectLoadingIfNeeded];
}

- (id<GLALoadableArrayUsing>)usePrimaryFolders
{
	id<GLALoadableArrayUsing> primaryFoldersUser = (self.primaryFoldersUser);
	if (!primaryFoldersUser) {
		GLAProjectManager *pm = (self.projectManager);
		(self.primaryFoldersUser) = primaryFoldersUser = [pm usePrimaryFoldersForProject:(self.project)];
		
		__weak GLAProjectMenuController *weakSelf = self;
		
		(primaryFoldersUser.changeCompletionBlock) = ^(id<GLAArrayInspecting>array) {
			__strong GLAProjectMenuController *self = weakSelf;
			if (!self) {
				return;
			}
			
			[self updateMenu];
		};
	}
	
	return primaryFoldersUser;
}

- (id<GLAArrayInspecting>)inspectPrimaryFolders
{
	return [[self usePrimaryFolders] inspectLoadingIfNeeded];
}

- (id<GLALoadableArrayUsing>)useCollections
{
	id<GLALoadableArrayUsing> collectionsUser = (self.collectionsUser);
	if (!collectionsUser) {
		GLAProjectManager *pm = (self.projectManager);
		(self.collectionsUser) = collectionsUser = [pm useCollectionsForProject:(self.project)];
		
		__weak GLAProjectMenuController *weakSelf = self;
		
		(collectionsUser.changeCompletionBlock) = ^(id<GLAArrayInspecting>array) {
			__strong GLAProjectMenuController *self = weakSelf;
			if (!self) {
				return;
			}
			
			[self updateMenu];
		};
	}
	
	return collectionsUser;
}

- (id<GLAArrayInspecting>)inspectCollections
{
	return [[self useCollections] inspectLoadingIfNeeded];
}

#pragma mark -

- (void)setNeedsUpdateMenu
{
	if (self.pendingMenuUpdate) {
		return;
	}
	
	(self.pendingMenuUpdate) = YES;
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		[self updateMenu];
	}];
}

- (void)updateMenu
{
	[self menuNeedsUpdate:(self.menu)];
}

#pragma mark Actions

- (void)activateApplication
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (IBAction)openHighlightedItem:(NSMenuItem *)sender
{
	GLAHighlightedItem *highlightedItem = (sender.representedObject);
	
	if ([highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
		GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
		
		GLAProjectManager *pm = (self.projectManager);
		[pm openHighlightedCollectedFile:highlightedCollectedFile modifierFlags:[NSEvent modifierFlags]];
	}
}

- (IBAction)openPrimaryFolderItem:(NSMenuItem *)sender
{
	GLACollectedFile *collectedFolder = (sender.representedObject);
	
	GLAProjectManager *pm = (self.projectManager);
	[pm openCollectedFile:collectedFolder modifierFlags:[NSEvent modifierFlags]];
}

- (IBAction)openCollection:(NSMenuItem *)sender
{
	GLACollection *collection = (sender.representedObject);
	
	GLAMainSectionNavigator *navigator = (self.mainSectionNavigator);
	[navigator goToCollection:collection];
	
	[self activateApplication];
}

- (IBAction)createNewCollection:(id)sender
{
	GLAMainSectionNavigator *navigator = (self.mainSectionNavigator);
	[navigator addNewCollectionToProject:(self.project)];
	
	[self activateApplication];
}

- (IBAction)makeNowProject:(NSMenuItem *)sender
{
	GLAProjectManager *pm = (self.projectManager);
	[pm changeNowProject:(self.project)];
}

#pragma mark Menu Delegate

- (void)addMenuItemsForHighlightsToMenu:(NSMenu *)menu
{
	id<GLAArrayInspecting> highlightsInspector = [self inspectHighlights];
	GLAProjectManager *pm = (self.projectManager);
	GLACollectedFileListHelper *collectedFileListHelper = (self.collectedFileListHelper);
	GLACollectedFilesSetting *collectedFilesSetting = (collectedFileListHelper.collectedFilesSetting);
	//GLAUIStyle *style = [GLAUIStyle activeStyle];
	
	if (highlightsInspector) {
		NSUInteger highlightCount = (highlightsInspector.childrenCount);
		SEL highlightAction = @selector(openHighlightedItem:);
		
		//collectionCount = 0;
		
		if (highlightCount == 0) {
			[menu gla_addDescriptiveMenuItemWithTitle:NSLocalizedString( @"No Highlighted Items Yet", @"Menu item for status item menu project menu when there are no highlighted items" )];
		}
		else {
			[menu gla_addDescriptiveMenuItemWithTitle:NSLocalizedString( @"Highlights", @"Status item menu item for grouping highlighted items" )];
		
			for (NSUInteger highlightIndex = 0; highlightIndex < highlightCount; highlightIndex++) {
				GLAHighlightedItem *highlightedItem = [highlightsInspector childAtIndex:highlightIndex];
				
				NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:highlightAction keyEquivalent:@""];
				(item.representedObject) = highlightedItem;
				(item.target) = self;
				
				if ([highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
					GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
					GLACollectedFile *collectedFile = [pm collectedFileForHighlightedCollectedFile:highlightedCollectedFile loadIfNeeded:YES];
					if (collectedFile && !(collectedFile.empty)) {
						[collectedFilesSetting startAccessingCollectedFile:collectedFile];
					}
					
					[collectedFilesSetting setUpMenuItem:item forOptionalCollectedFile:collectedFile wantsIcon:YES];
				}
				else {
					// No other highlighted item types currently.
				}
				
				[menu addItem:item];
			}
		}
	}
	else {
		[menu gla_addDescriptiveMenuItemWithTitle:NSLocalizedString(@"Loading Highlights…", @"Loading menu item for highlights inside a project menu")];
	}
}

- (void)addMenuItemsForPrimaryFoldersToMenu:(NSMenu *)menu
{
	id<GLAArrayInspecting> primaryFoldersInspector = [self inspectPrimaryFolders];
	GLACollectedFileListHelper *collectedFileListHelper = (self.collectedFileListHelper);
	GLACollectedFilesSetting *collectedFilesSetting = (collectedFileListHelper.collectedFilesSetting);
	//GLAUIStyle *style = [GLAUIStyle activeStyle];
	
	if (primaryFoldersInspector) {
		NSUInteger primaryFolderCount = (primaryFoldersInspector.childrenCount);
		SEL primaryFolderAction = @selector(openPrimaryFolderItem:);
		
		//collectionCount = 0;
		
		if (primaryFolderCount == 0) {
			[menu gla_addDescriptiveMenuItemWithTitle:NSLocalizedString( @"No Primary Folders Yet", @"Menu item for status item menu project menu when there are no primary folders" )];
		}
		else {
			[menu gla_addDescriptiveMenuItemWithTitle:NSLocalizedString( @"Primary Folders", @"Status item menu item for grouping primary folders" )];
			
			for (NSUInteger primaryFolderIndex = 0; primaryFolderIndex < primaryFolderCount; primaryFolderIndex++) {
				GLACollectedFile *collectedFolder = [primaryFoldersInspector childAtIndex:primaryFolderIndex];
				
				NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:primaryFolderAction keyEquivalent:@""];
				(item.representedObject) = collectedFolder;
				(item.target) = self;
				
				[collectedFilesSetting startAccessingCollectedFile:collectedFolder];
				
				[collectedFilesSetting setUpMenuItem:item forOptionalCollectedFile:collectedFolder wantsIcon:YES];
				
				[menu addItem:item];
			}
		}
	}
	else {
		[menu gla_addDescriptiveMenuItemWithTitle:NSLocalizedString(@"Loading Primary Folders…", @"Loading menu item for primary folders inside a project menu")];
	}
}

- (void)addMenuItemsForCollectionsToMenu:(NSMenu *)menu
{
	id<GLAArrayInspecting> collectionsInspector = [self inspectCollections];
	
	if (collectionsInspector) {
		NSUInteger collectionCount = (collectionsInspector.childrenCount);
		SEL collectionAction = @selector(openCollection:);
		
		// For testing:
		//collectionCount = 0;
		
		if (collectionCount == 0) {
			[menu gla_addDescriptiveMenuItemWithTitle:NSLocalizedString( @"No Collections Yet", @"Menu item for status item menu project menu when there are no collections" )];
		}
		else {
			[menu gla_addDescriptiveMenuItemWithTitle:NSLocalizedString( @"Collections", @"Status item menu item for grouping collections" )];
			
			for (NSUInteger collectionIndex = 0; collectionIndex < collectionCount; collectionIndex++) {
				GLACollection *collection = [collectionsInspector childAtIndex:collectionIndex];
				
				NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:(collection.name) action:collectionAction keyEquivalent:@""];
				(item.representedObject) = collection;
				(item.target) = self;
				
	#if 0
				GLACollectionColor *collectionColor = (collection.color);
				NSColor *color = [style colorForCollectionColor:collectionColor];
				NSDictionary *attributes =
				@{
				  //NSFontAttributeName: [NSFont menuFontOfSize:0],
				  NSFontAttributeName: [style collectionFont],
				  //NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle | NSUnderlinePatternSolid),
				  //NSUnderlineColorAttributeName: color
				  NSForegroundColorAttributeName: color
				  };
				(item.attributedTitle) = [[NSAttributedString alloc] initWithString:(collection.name) attributes:attributes];
	#endif
				
				[menu addItem:item];
			}
		}
	}
	else {
		[menu gla_addDescriptiveMenuItemWithTitle:NSLocalizedString(@"Loading Collections…", @"Loading menu item for collections inside a project menu")];
	}
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	//(menu.minimumWidth) = 400.0;
	
	[menu removeAllItems];
	
	NSMenuItem *item = nil;
	
	[self addMenuItemsForHighlightsToMenu:menu];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[self addMenuItemsForPrimaryFoldersToMenu:menu];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[self addMenuItemsForCollectionsToMenu:menu];
	
#if 0
	// New Collection
	[menu addItem:[NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"New Collection…", @"Status item menu item for creating a new collection in a project" ) action:@selector(createNewCollection:) keyEquivalent:@""];
	(item.target) = self;
	[menu addItem:item];
#endif
	
	// Work On Now
	[menu addItem:[NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Work On Now…", @"Status item menu item for working on a project now" ) action:@selector(makeNowProject:) keyEquivalent:@""];
	(item.target) = self;
	[menu addItem:item];
	
	
	(self.pendingMenuUpdate) = NO;
}

#pragma mark -

- (void)collectedFileListHelperDidInvalidate:(GLACollectedFileListHelper *)helper
{
	[self setNeedsUpdateMenu];
}

#pragma mark -

- (void)projectAnyCollectionFilesListDidChangeNotification:(NSNotification *)note
{
	[self setNeedsUpdateMenu];
}

@end
