//
//  GLAFileURLOpenerApplicationCombiner.m
//  Blik
//
//  Created by Patrick Smith on 3/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAFileOpenerApplicationFinder.h"
#import "GLAFileInfoRetriever.h"


@interface GLAFileOpenerApplicationFinder () <GLAFileInfoRetrieverDelegate>

@property(nonatomic) GLAFileInfoRetriever *fileInfoRetriever;

@property(nonatomic) NSMutableSet *mutableFileURLs;

@property(nonatomic) NSMutableDictionary *URLsToOpenerApplicationURLs;
@property(nonatomic) NSMutableDictionary *URLsToDefaultOpenerApplicationURL;

@property(nonatomic) NSUInteger combinedCountSoFar;
@property(nonatomic) NSMutableSet *mutableCombinedOpenerApplicationURLs;
@property(readwrite, nonatomic) NSURL *combinedDefaultOpenerApplicationURL;

- (void)recombineAllFileURLs;

@end

@implementation GLAFileOpenerApplicationFinder

- (instancetype)init
{
	self = [super init];
	if (self) {
		(self.fileInfoRetriever) = [[GLAFileInfoRetriever alloc] initWithDelegate:self];
		_mutableFileURLs = [NSMutableSet new];
	}
	return self;
}

- (void)addFileURLs:(NSSet *)fileURLsSet
{
	NSMutableSet *mutableFileURLs = (self.mutableFileURLs);
	
	for (NSURL *fileURL in fileURLsSet) {
		if ([mutableFileURLs containsObject:fileURL]) {
			continue;
		}
		
		[self combineOpenerApplicationURLsForFileURL:fileURL loadIfNeeded:YES];
	}
	
	[mutableFileURLs unionSet:fileURLsSet];
}

- (void)removeFileURLs:(NSSet *)fileURLsSet
{
	[(self.mutableFileURLs) minusSet:fileURLsSet];
	
	[self recombineAllFileURLs];
}

- (BOOL)hasFileURL:(NSURL *)fileURL
{
	return [(self.mutableFileURLs) containsObject:fileURL];
}

- (NSSet *)fileURLs
{
	return [(self.mutableFileURLs) copy];
}

- (void)setFileURLs:(NSSet *)fileURLs
{
	if (!fileURLs) {
		fileURLs = [NSSet set];
	}
	
	NSMutableSet *mutableFileURLs = (self.mutableFileURLs);
	
	NSMutableSet *fileURLsBeingAdded = [fileURLs mutableCopy];
	[fileURLsBeingAdded minusSet:mutableFileURLs];
	
	NSMutableSet *fileURLsBeingRemoved = [mutableFileURLs mutableCopy];
	[fileURLsBeingRemoved minusSet:fileURLs];
	
	BOOL isRemoving = (fileURLsBeingRemoved.count) > 0;
	BOOL isAdding = (fileURLsBeingAdded.count) > 0;
	
	if (isRemoving) {
		[mutableFileURLs minusSet:fileURLsBeingRemoved];
	}
	
	if (isAdding) {
		[mutableFileURLs unionSet:fileURLsBeingAdded];
	}
	
	if (isRemoving) {
		[self recombineAllFileURLs];
	}
	else if (isAdding) {
		for (NSURL *fileURL in fileURLsBeingAdded) {
			[self combineOpenerApplicationURLsForFileURL:fileURL loadIfNeeded:YES];
		}
	}
}

- (BOOL)hasLoadedAll
{
	return (self.combinedCountSoFar) == (self.mutableFileURLs.count);
}

#pragma mark -

- (void)setOpenerApplicationURLs:(NSArray *)applicationURLs forFileURL:(NSURL *)fileURL
{
	NSMutableDictionary *URLsToOpenerApplicationURLs = (self.URLsToOpenerApplicationURLs);
	if (!URLsToOpenerApplicationURLs) {
		URLsToOpenerApplicationURLs = (self.URLsToOpenerApplicationURLs) = [NSMutableDictionary new];
	}
	
	URLsToOpenerApplicationURLs[fileURL] = [applicationURLs copy];
}

- (NSArray *)openerApplicationURLsForFileURL:(NSURL *)fileURL
{
	NSMutableDictionary *URLsToOpenerApplicationURLs = (self.URLsToOpenerApplicationURLs);
	if (!URLsToOpenerApplicationURLs) {
		return nil;
	}
	
	NSArray *applicationURLs = URLsToOpenerApplicationURLs[fileURL];
	return applicationURLs;

}

- (void)setDefaultOpenerApplicationURL:(NSURL *)applicationURL forFileURL:(NSURL *)fileURL
{
	NSMutableDictionary *URLsToDefaultOpenerApplicationURL = (self.URLsToDefaultOpenerApplicationURL);
	if (!URLsToDefaultOpenerApplicationURL) {
		URLsToDefaultOpenerApplicationURL = (self.URLsToDefaultOpenerApplicationURL) = [NSMutableDictionary new];
	}
	
	URLsToDefaultOpenerApplicationURL[fileURL] = applicationURL;
}

- (NSURL *)defaultOpenerApplicationURLForFileURL:(NSURL *)fileURL
{
	NSMutableDictionary *URLsToDefaultOpenerApplicationURL = (self.URLsToDefaultOpenerApplicationURL);
	if (!URLsToDefaultOpenerApplicationURL) {
		return nil;
	}
	
	NSURL *applicationURL = URLsToDefaultOpenerApplicationURL[fileURL];
	return applicationURL;
}

- (NSSet *)combinedOpenerApplicationURLs
{
	return [(self.mutableCombinedOpenerApplicationURLs) copy];
}

- (void)clearCombinedApplicationURLs
{
	(self.combinedCountSoFar) = 0;
	
	NSMutableSet *mutableCombinedOpenerApplicationURLs = (self.mutableCombinedOpenerApplicationURLs);
	if (mutableCombinedOpenerApplicationURLs) {
		[mutableCombinedOpenerApplicationURLs removeAllObjects];
	}
}

- (void)combineOpenerApplicationURLsForFileURL:(NSURL *)fileURL loadIfNeeded:(BOOL)load
{
	NSArray *applicationURLs = [self openerApplicationURLsForFileURL:fileURL];
	
	if (!applicationURLs) {
		if (load) {
			[(self.fileInfoRetriever) requestApplicationURLsToOpenURL:fileURL];
		}
		return;
	}
	
	NSURL *defaultOpenerApplicationURL = [self defaultOpenerApplicationURLForFileURL:fileURL];
	
	NSMutableSet *mutableCombinedOpenerApplicationURLs = (self.mutableCombinedOpenerApplicationURLs);
	if (!mutableCombinedOpenerApplicationURLs) {
		mutableCombinedOpenerApplicationURLs = (self.mutableCombinedOpenerApplicationURLs) = [NSMutableSet new];
	}
	
	// If this is the first set to be combined, just add them straight in as is.
	if ((self.combinedCountSoFar) == 0) {
		[mutableCombinedOpenerApplicationURLs addObjectsFromArray:applicationURLs];
		(self.combinedDefaultOpenerApplicationURL) = defaultOpenerApplicationURL;
		
		[self didChangeCombinedOpenerApplicationURLs];
	}
	// Otherwise we need to combine by only keeping the applications that can open all files.
	else {
		NSUInteger countBefore = (mutableCombinedOpenerApplicationURLs.count);
		[mutableCombinedOpenerApplicationURLs intersectSet:[NSSet setWithArray:applicationURLs]];
		NSUInteger countAfter = (mutableCombinedOpenerApplicationURLs.count);
		
		if (defaultOpenerApplicationURL != (self.combinedDefaultOpenerApplicationURL)) {
			(self.combinedDefaultOpenerApplicationURL) = nil;
		}
		
		if (countBefore != countAfter) {
			[self didChangeCombinedOpenerApplicationURLs];
		}
	}
	
	(self.combinedCountSoFar)++;
}

- (void)recombineAllFileURLs
{
	[self clearCombinedApplicationURLs];
	
	NSSet *fileURLs = (self.fileURLs);
	for (NSURL *fileURL in fileURLs) {
		[self combineOpenerApplicationURLsForFileURL:fileURL loadIfNeeded:YES];
	}
}

- (void)didChangeCombinedOpenerApplicationURLs
{
	NSNotification *note = [NSNotification notificationWithName:GLAFileURLOpenerApplicationCombinerDidChangeNotification object:self];
	
	// Allows notifications to be sent as one, and common mode allows it to work during menu tracking.
	NSNotificationQueue *nq = [NSNotificationQueue defaultQueue];
	[nq enqueueNotification:note postingStyle:NSPostASAP coalesceMask:(NSNotificationCoalescingOnName & NSNotificationCoalescingOnSender) forModes:@[NSRunLoopCommonModes]];
}

#pragma mark File Info Retriever Delegate

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didRetrieveApplicationURLsToOpenURL:(NSURL *)URL
{
	NSArray *applicationURLs = [fileInfoRetriever applicationsURLsToOpenURL:URL];
	[self setOpenerApplicationURLs:applicationURLs forFileURL:URL];
	
	NSURL *defaultApplicationURL = [fileInfoRetriever defaultApplicationURLToOpenURL:URL];
	if (defaultApplicationURL) {
		[self setDefaultOpenerApplicationURL:defaultApplicationURL forFileURL:URL];
	}
	
	if ([self hasFileURL:URL]) {
		[self combineOpenerApplicationURLsForFileURL:URL loadIfNeeded:NO];
	}
}

#pragma mark -

+ (void)openFileURLs:(NSArray *)fileURLs withApplicationURL:(NSURL *)applicationURL useSecurityScope:(BOOL)useSecurityScope
{
	NSMutableArray *accessedURLs = [NSMutableArray new];
	if (useSecurityScope) {
		for (NSURL *fileURL in fileURLs) {
			if ([fileURL startAccessingSecurityScopedResource]) {
				[accessedURLs addObject:fileURL];
			}
		}
	}
	
	const LSLaunchURLSpec launchURLSpec = {
		.appURL =  (__bridge CFURLRef)(applicationURL),
		.itemURLs = (__bridge CFArrayRef)fileURLs,
		.passThruParams = NULL,
		.launchFlags = kLSLaunchDefaults,
		.asyncRefCon = NULL
	};
	
	LSOpenFromURLSpec(&launchURLSpec, NULL);
	
	if (useSecurityScope) {
		[accessedURLs makeObjectsPerformSelector:@selector(stopAccessingSecurityScopedResource)];
	}
}

+ (void)openFileURLs:(NSArray *)fileURLs withApplicationURL:(NSURL *)applicationURL
{
	const LSLaunchURLSpec launchURLSpec = {
		.appURL =  (__bridge CFURLRef)(applicationURL),
		.itemURLs = (__bridge CFArrayRef)fileURLs,
		.passThruParams = NULL,
		.launchFlags = kLSLaunchDefaults,
		.asyncRefCon = NULL
	};
	
	LSOpenFromURLSpec(&launchURLSpec, NULL);
}

- (void)openFileURLsUsingDefaultApplications
{
	NSArray *fileURLs = (self.fileURLs.allObjects);
	[[self class] openFileURLs:fileURLs withApplicationURL:nil useSecurityScope:YES];
}

@end

NSString *GLAFileURLOpenerApplicationCombinerDidChangeNotification = @"GLAFileURLOpenerApplicationCombinerDidChangeNotification";


@implementation GLAFileOpenerApplicationFinder (MenuAdditions)

- (NSMenuItem *)newMenuItemForApplicationURL:(NSURL *)applicationURL target:(id)target action:(SEL)action
{
	NSError *error = nil;
	NSDictionary *values = [applicationURL resourceValuesForKeys:@[NSURLLocalizedNameKey, NSURLEffectiveIconKey] error:&error];
	if (!values) {
		return nil;
	}
	
	NSImage *iconImage = values[NSURLEffectiveIconKey];
	iconImage = [iconImage copy];
	(iconImage.size) = NSMakeSize(16.0, 16.0);
	
	NSMenuItem *menuItem = [NSMenuItem new];
	(menuItem.title) = values[NSURLLocalizedNameKey];
	(menuItem.image) = iconImage;
	(menuItem.toolTip) = (applicationURL.path);
	
	(menuItem.representedObject) = applicationURL;
	
	(menuItem.target) = target;
	(menuItem.action) = action;
	
	return menuItem;
}

- (void)updateOpenerApplicationsMenu:(NSMenu *)menu target:(id)target action:(SEL)action preferredApplicationURL:(NSURL *)preferredApplicationURL forPopUpMenu:(BOOL)forPopUpMenu
{
	NSSet *combinedOpenerApplicationURLs = (self.combinedOpenerApplicationURLs);
	NSURL *combinedDefaultOpenerApplicationURL = (self.combinedDefaultOpenerApplicationURL);
	
	NSMenuItem *preferredApplicationMenuItem = nil;
	NSMenuItem *defaultApplicationMenuItem = nil;
	NSMutableArray *menuItems = [NSMutableArray new];
	
	BOOL (^ applicationURLsAreEqual)(NSURL *, NSURL *) = ^ BOOL (NSURL *URL1, NSURL *URL2) {
		return [(URL1.path) isEqual:(URL2.path)];
	};
	
	BOOL preferredApplicationIsAlsoDefault = (preferredApplicationURL) && (combinedDefaultOpenerApplicationURL) && applicationURLsAreEqual(preferredApplicationURL, combinedDefaultOpenerApplicationURL);
	
	if (preferredApplicationURL) {
		preferredApplicationMenuItem = [self newMenuItemForApplicationURL:preferredApplicationURL target:target action:action];
		if (preferredApplicationIsAlsoDefault) {
			(preferredApplicationMenuItem.title) = [NSString localizedStringWithFormat:NSLocalizedString(@"%@ (preferred & default)", @"Menu item title format for preferred application which is also the default."), (preferredApplicationMenuItem.title)];
		}
		else {
			(preferredApplicationMenuItem.title) = [NSString localizedStringWithFormat:NSLocalizedString(@"%@ (preferred)", @"Menu item title format for preferred application."), (preferredApplicationMenuItem.title)];
		}
	}
	
	if (combinedDefaultOpenerApplicationURL && !preferredApplicationIsAlsoDefault) {
		defaultApplicationMenuItem = [self newMenuItemForApplicationURL:combinedDefaultOpenerApplicationURL target:target action:action];
		(defaultApplicationMenuItem.title) = [NSString localizedStringWithFormat:NSLocalizedString(@"%@ (default)", @"Menu item title format for default application."), (defaultApplicationMenuItem.title)];
	}
	
	if ((combinedOpenerApplicationURLs.count) > 0) {
		for (NSURL *applicationURL in combinedOpenerApplicationURLs) {
			if (applicationURLsAreEqual(combinedDefaultOpenerApplicationURL, applicationURL)) {
				continue;
			}
			
			if ((preferredApplicationURL != nil) && applicationURLsAreEqual(preferredApplicationURL, applicationURL)) {
				continue;
			}
			
			NSMenuItem *menuItem = [self newMenuItemForApplicationURL:applicationURL target:target action:action];
			if (!menuItem) {
				continue;
			}
			
			[menuItems addObject:menuItem];
		}
		
		NSSortDescriptor *titleSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
		
		[menuItems sortUsingDescriptors:@[titleSortDescriptor]];
	}
	
	[menu removeAllItems];
	
	if ((preferredApplicationMenuItem != nil) || (defaultApplicationMenuItem != nil)) {
		if (preferredApplicationMenuItem) {
			[menu addItem:preferredApplicationMenuItem];
			
			if ((menuItems.count) > 0) {
				[menu addItem:[NSMenuItem separatorItem]];
			}
		}
		
		if (defaultApplicationMenuItem) {
			[menu addItem:defaultApplicationMenuItem];
			
			if ((menuItems.count) > 0) {
				[menu addItem:[NSMenuItem separatorItem]];
			}
		}
	}
	else if ((menuItems.count) == 0) {
		NSMenuItem *menuItem = [NSMenuItem new];
		(menuItem.title) = NSLocalizedString(@"No Application", @"Menu item title when no application is available to open the selected files.");
		(menuItem.enabled) = NO;
		[menu addItem:menuItem];
	}
	
	for (NSMenuItem *menuItem in menuItems) {
		[menu addItem:menuItem];
	}
	
	if (forPopUpMenu) {
		// Duplicate the first item, so it appears as the button's content.
		NSMenuItem *firstItem = (menu.itemArray)[0];
		if (firstItem) {
			NSMenuItem *titleMenuItem = [firstItem copy];
			(titleMenuItem.title) = NSLocalizedString(@"Open in", @"Title for 'Open in' application menu");
			[menu insertItem:titleMenuItem atIndex:0];
		}
	}
}

- (void)updateOpenerApplicationsMenu:(NSMenu *)menu target:(id)target action:(SEL)action preferredApplicationURL:(NSURL *)preferredApplicationURL
{
	[self updateOpenerApplicationsMenu:menu target:target action:action preferredApplicationURL:preferredApplicationURL forPopUpMenu:NO];
}

- (void)updatePreferredOpenerApplicationsChoiceMenu:(NSMenu *)menu target:(id)target action:(SEL)action chosenPreferredApplicationURL:(NSURL *)preferredApplicationURL
{
	NSSet *combinedOpenerApplicationURLs = (self.combinedOpenerApplicationURLs);
	NSURL *combinedDefaultOpenerApplicationURL = (self.combinedDefaultOpenerApplicationURL);
	
	NSMutableArray *menuItems = [NSMutableArray new];
	
	BOOL (^ applicationURLsAreEqual)(NSURL *, NSURL *) = ^ BOOL (NSURL *URL1, NSURL *URL2) {
		return [(URL1.path) isEqual:(URL2.path)];
	};
	
	if ((combinedOpenerApplicationURLs.count) > 0) {
		for (NSURL *applicationURL in combinedOpenerApplicationURLs) {
			NSMenuItem *menuItem = [self newMenuItemForApplicationURL:applicationURL target:target action:action];
			if (!menuItem) {
				continue;
			}
			
			if ((preferredApplicationURL != nil) && applicationURLsAreEqual(preferredApplicationURL, applicationURL)) {
				(menuItem.state) = NSOnState;
			}
			
			if (applicationURLsAreEqual(combinedDefaultOpenerApplicationURL, applicationURL)) {
				(menuItem.title) = [NSString localizedStringWithFormat:NSLocalizedString(@"%@ (default)", @"Menu item title format for default application."), (menuItem.title)];
			}
			
			[menuItems addObject:menuItem];
		}
		
		NSSortDescriptor *titleSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
		
		[menuItems sortUsingDescriptors:@[titleSortDescriptor]];
	}
	
	[menu removeAllItems];
	
	for (NSMenuItem *menuItem in menuItems) {
		[menu addItem:menuItem];
	}
	
	if ((menuItems.count) == 0) {
		NSMenuItem *menuItem = [NSMenuItem new];
		(menuItem.title) = NSLocalizedString(@"No Application", @"Menu item title when no application is available to open the selected files.");
		(menuItem.enabled) = NO;
		[menu addItem:menuItem];
	}
	else {
		[menu addItem:[NSMenuItem separatorItem]];
		
		NSMenuItem *menuItem = [NSMenuItem new];
		(menuItem.title) = NSLocalizedString(@"Default Application", @"Menu item title for choosing no preferred application, just using default.");
		(menuItem.action) = action;
		(menuItem.target) = target;
		
		if (!preferredApplicationURL) {
			(menuItem.state) = NSOnState;
		}
		
		[menu addItem:menuItem];
	}
}


- (NSURL *)openerApplicationURLForMenuItem:(NSMenuItem *)menuItem
{
	id representedObject = (menuItem.representedObject);
	if ((!representedObject) || ![representedObject isKindOfClass:[NSURL class]]) {
		return nil;
	}
	
	return (NSURL *)representedObject;
}

- (void)openFileURLsUsingMenuItem:(NSMenuItem *)menuItem
{
	NSSet *fileURLsSet = (self.fileURLs);
	if (fileURLsSet.count == 0) {
		return;
	}
	
	NSURL *applicationURL = [self openerApplicationURLForMenuItem:menuItem];
	if (!applicationURL) {
		return;
	}
	
	NSArray *fileURLsArray = (fileURLsSet.allObjects);
	[[self class] openFileURLs:fileURLsArray withApplicationURL:applicationURL useSecurityScope:YES];
}

- (void)openFileURLsUsingChosenOpenerApplicationPopUpButton:(NSPopUpButton *)popUpButton
{
	NSMenuItem *selectedItem = (popUpButton.selectedItem);
	if (!selectedItem) {
		return;
	}
	
	[self openFileURLsUsingMenuItem:selectedItem];
}

@end
