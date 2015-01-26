//
//  GLAPluckedCollectedFilesMenuController.m
//  Blik
//
//  Created by Patrick Smith on 24/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAPluckedCollectedFilesMenuController.h"
#import "GLAFileInfoRetriever.h"


static GLAPluckedCollectedFilesMenuController *sharedMenuController;


@interface GLAPluckedCollectedFilesMenuController () <NSMenuDelegate, GLAFileInfoRetrieverDelegate>

@property(nonatomic) NSArray *pluckedCollectedFilesMenuItems;

@property(readonly, nonatomic) GLAFileInfoRetriever *fileInfoRetriever;

@end

@implementation GLAPluckedCollectedFilesMenuController

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedMenuController = [[super allocWithZone:zone] initProper];
	});
	return sharedMenuController;
}

- (instancetype)initProper
{
	self = [super init];
	if (self) {
		_pluckedCollectedFilesList = [[GLAPluckedCollectedFilesList alloc] initWithProjectManager:[GLAProjectManager sharedProjectManager]];
		
		GLAFileInfoRetriever *fileInfoRetriever = [[GLAFileInfoRetriever alloc] initWithDelegate:self];
		(fileInfoRetriever.defaultResourceKeysToRequest) = @[NSURLLocalizedNameKey, NSURLEffectiveIconKey];
		_fileInfoRetriever = fileInfoRetriever;
	}
	return self;
}

- (instancetype)init
{
	return self;
}

- (void)awakeFromNib
{
	(self.pluckedMainMenu.delegate) = self;
}

+ (instancetype)sharedMenuController
{
	(void)[self alloc];
	return sharedMenuController;
}

#pragma mark - Notifications

- (void)startObservingPluckedCollectedFilesList
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	GLAPluckedCollectedFilesList *pluckedCollectedFilesList = (self.pluckedCollectedFilesList);
	
	[nc addObserver:self selector:@selector(pluckedCollectedFilesListDidChange:) name:GLAPluckedCollectedFilesListDidAddCollectedFilesNotification object:pluckedCollectedFilesList];
	[nc addObserver:self selector:@selector(pluckedCollectedFilesListDidChange:) name:GLAPluckedCollectedFilesListDidRemoveCollectedFilesNotification object:pluckedCollectedFilesList];
}

- (void)pluckedCollectedFilesListDidChange:(NSNotification *)note
{
	[self updateMenu];
}

#pragma mark -

- (NSArray *)createMenuItemsForPluckedCollectedFiles
{
	NSMutableArray *menuItems = [NSMutableArray new];
	SEL action = @selector(placePluckedCollectedFiles:);
	
	GLAPluckedCollectedFilesList *pluckedCollectedFilesList = (self.pluckedCollectedFilesList);
	GLAFileInfoRetriever *fileInfoRetriever = (self.fileInfoRetriever);
	
	NSArray *collectedFiles = [pluckedCollectedFilesList copyPluckedCollectedFiles];
	for (GLACollectedFile *collectedFile in collectedFiles) {
		NSURL *fileURL = (collectedFile.filePathURL);
		NSString *name = [fileInfoRetriever localizedNameForURL:fileURL];
		if (!name) {
			name = NSLocalizedString(@"(Loading)", @"Menu item title for plucked collected file when its name is still loading.");
		}
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:name action:action keyEquivalent:@""];
		(menuItem.representedObject) = collectedFile;
		
		(menuItem.image) = [fileInfoRetriever effectiveIconImageForURL:fileURL withSizeDimension:16.0];
		[menuItems addObject:menuItem];
	}
	
	return menuItems;
}

- (void)updateMenu
{
	NSMenu *menu = (self.pluckedMainMenu);
	NSArray *menuItemsToAdd = [self createMenuItemsForPluckedCollectedFiles];
	
	NSArray *existingMenuItems = (self.pluckedCollectedFilesMenuItems);
	if (existingMenuItems) {
		for (NSMenuItem *menuItem in existingMenuItems) {
			[menu removeItem:menuItem];
		}
	}
	
	NSMenuItem *placeholderMenuItem = (self.pluckedCollectedFilesPlaceholderMenuItem);
	(placeholderMenuItem.hidden) = YES;
	NSUInteger menuIndexToInsert = [menu indexOfItem:placeholderMenuItem] + 1;
	
	for (NSMenuItem *menuItem in menuItemsToAdd) {
		[menu insertItem:menuItem atIndex:menuIndexToInsert];
		menuIndexToInsert++;
	}
	
	(self.pluckedCollectedFilesMenuItems) = menuItemsToAdd;
	
	BOOL hasItems = ((menuItemsToAdd.count) > 0);
	(self.noPluckedItemsMenuItem.hidden) = hasItems;
	(self.placeAllPluckedItemsMenuItem.hidden) = !hasItems;
}

- (void)placePluckedItemsWithMenuItem:(NSMenuItem *)menuItem intoCollection:(GLACollection *)destinationCollection project:(GLAProject *)destinationProject
{
	GLAPluckedCollectedFilesList *pluckedCollectedFilesList = (self.pluckedCollectedFilesList);
	
	GLACollectedFile *collectedFile = (menuItem.representedObject);
	if (collectedFile) {
		NSSet *collectedFileUUIDs = [NSSet setWithObject:(collectedFile.UUID)];
		[pluckedCollectedFilesList placePluckedCollectedFilesFilteringByUUIDs:collectedFileUUIDs intoCollection:destinationCollection project:destinationProject];
	}
	else {
		[pluckedCollectedFilesList placeAllPluckedCollectedFilesIntoCollection:destinationCollection project:destinationProject];
	}
}

#pragma mark - Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if (menu == (self.pluckedMainMenu)) {
		[self updateMenu];
	}
}

#pragma mark - GLAFileInfoRetriever delegate

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)URL
{
	//[(self.pluckedMainMenu) update];
	[self updateMenu];
}

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL
{
	
}

@end
