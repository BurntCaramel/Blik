//
//  GLACollectedFileMenuCreator.m
//  Blik
//
//  Created by Patrick Smith on 15/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLACollectedFileMenuCreator.h"
#import "NSMenu+GLAMenuItemConvenience.h"


@interface GLACollectedFileMenuCreator ()

@property(nonatomic) GLAFileOpenerApplicationFinder *fileOpeningApplicationFinder;

@property(nonatomic) NSMenuItem *openInApplicationMenuItem;
@property(nonatomic) NSMenuItem *preferredOpenerApplicationMenuItem;

@end

@implementation GLACollectedFileMenuCreator

- (instancetype)init
{
	self = [super init];
	if (self) {
		_fileOpeningApplicationFinder = [GLAFileOpenerApplicationFinder new];
		
		[self startObservingFileOpeningApplicationFinder];
	}
	return self;
}

- (void)dealloc
{
	[self stopObservingFileOpeningApplicationFinder];
}

- (void)startObservingFileOpeningApplicationFinder
{
	GLAFileOpenerApplicationFinder *fileOpeningApplicationFinder = (self.fileOpeningApplicationFinder);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self selector:@selector(openerApplicationCombinerDidChangeNotification:) name:GLAFileURLOpenerApplicationCombinerDidChangeNotification object:fileOpeningApplicationFinder];
}

- (void)stopObservingFileOpeningApplicationFinder
{
	GLAFileOpenerApplicationFinder *fileOpeningApplicationFinder = (self.fileOpeningApplicationFinder);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc removeObserver:self name:nil object:fileOpeningApplicationFinder];
}

#pragma mark -

- (void)setFileURL:(NSURL *)fileURL
{
	if (fileURL) {
		fileURL = [fileURL copy];
	}
	
	_fileURL = fileURL;
	
	GLAFileOpenerApplicationFinder *fileOpeningApplicationFinder = (self.fileOpeningApplicationFinder);
	if (fileURL) {
		(fileOpeningApplicationFinder.fileURLs) = [NSSet setWithObject:fileURL];
	}
	else {
		(fileOpeningApplicationFinder.fileURLs) = nil;
	}
}

#pragma mark -

- (void)addMenuItemsForOpeningInApplicationToMenu:(NSMenu *)menu chosenPreferredApplicationURL:(NSURL *)preferredApplicationURL
{
	GLAFileOpenerApplicationFinder *fileOpeningApplicationFinder = (self.fileOpeningApplicationFinder);
	id target = (self.target);
	SEL openInApplicationAction = (self.openInApplicationAction);
	
	
	NSMenuItem *openInApplicationMenuItem = (self.openInApplicationMenuItem);
	NSMenu *openInApplicationMenu = nil;
	
	if (!openInApplicationMenuItem) {
		openInApplicationMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open With", @"'Open With' menu title for collected files") action:nil keyEquivalent:@""];
		
		openInApplicationMenu = [[NSMenu alloc] init];
		(openInApplicationMenuItem.submenu) = openInApplicationMenu;
		
		(self.openInApplicationMenuItem) = openInApplicationMenuItem;
	}
	else {
		openInApplicationMenu = (openInApplicationMenuItem.submenu);
	}
	
	[fileOpeningApplicationFinder updateOpenerApplicationsMenu:openInApplicationMenu target:target action:openInApplicationAction preferredApplicationURL:preferredApplicationURL];
	
	[menu addItem:openInApplicationMenuItem];
}

- (void)addMenuItemsForChoosingPreferredApplicationToMenu:(NSMenu *)menu chosenPreferredApplicationURL:(NSURL *)preferredApplicationURL
{
	GLAHighlightedCollectedFile *highlightedCollectedFile = (self.highlightedCollectedFile);
	
	if (highlightedCollectedFile) {
		GLAFileOpenerApplicationFinder *fileOpeningApplicationFinder = (self.fileOpeningApplicationFinder);
		id target = (self.target);
		SEL changePreferredOpenerApplicationAction = (self.changePreferredOpenerApplicationAction);
		
		NSMenuItem *preferredOpenerApplicationMenuItem = (self.preferredOpenerApplicationMenuItem);
		NSMenu *preferredOpenerApplicationMenu = nil;
		
		if (!preferredOpenerApplicationMenuItem) {
			preferredOpenerApplicationMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Prefer to Open With", @"'Prefer to Open With' menu title for highlighted collected files") action:nil keyEquivalent:@""];
			
			preferredOpenerApplicationMenu = [[NSMenu alloc] init];
			(preferredOpenerApplicationMenuItem.submenu) = preferredOpenerApplicationMenu;
			
			(self.preferredOpenerApplicationMenuItem) = preferredOpenerApplicationMenuItem;
		}
		else {
			preferredOpenerApplicationMenu = (preferredOpenerApplicationMenuItem.submenu);
		}
		
		[fileOpeningApplicationFinder updatePreferredOpenerApplicationsChoiceMenu:preferredOpenerApplicationMenu target:target action:changePreferredOpenerApplicationAction chosenPreferredApplicationURL:preferredApplicationURL];
		
		[menu addItem:preferredOpenerApplicationMenuItem];
	}
}

- (void)addMenuItemsForShowInFinderToMenu:(NSMenu *)menu
{
	id target = (self.target);
	SEL showInFinderAction = (self.showInFinderAction);
	
	NSMenuItem *showInFinderMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Show in Finder…", @"'Show in Finder…' menu title for collected files") action:showInFinderAction keyEquivalent:@""];
	(showInFinderMenuItem.target) = target;
	
	[menu addItem:showInFinderMenuItem];
}

- (void)updateMenu:(NSMenu *)menu
{
	[menu removeAllItems];
	
	GLACollectedFileMenuContext context = (self.context);
	GLAHighlightedCollectedFile *highlightedCollectedFile = (self.highlightedCollectedFile);
	id target = (self.target);
	
	NSURL *preferredApplicationURL = nil;
	
	if (highlightedCollectedFile) {
		GLACollectedFile *collectedFileForPreferredApplication = (highlightedCollectedFile.applicationToOpenFile);
		if (collectedFileForPreferredApplication) {
			GLAAccessedFileInfo *preferredApplicationAccessedFile = [collectedFileForPreferredApplication accessFile];
			preferredApplicationURL = (preferredApplicationAccessedFile.filePathURL);
		}
	}
	
#if 0
	if (context == GLACollectedFileMenuContextInCollection) {
		SEL removeFromHighlightsAction = (self.removeFromHighlightsAction);
		
		NSMenuItem *changeInHighlightsMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove from Highlights", @"Remove highlighted file from highlights menu title") action:removeFromHighlightsAction keyEquivalent:@""];
		(changeInHighlightsMenuItem.target) = target;
		[menu addItem:changeInHighlightsMenuItem];
		
		[menu addItem:[NSMenuItem separatorItem]];
	}
#endif
	
	// Open With
	[self addMenuItemsForOpeningInApplicationToMenu:menu chosenPreferredApplicationURL:preferredApplicationURL];
	
	// Prefer to Open With
	[self addMenuItemsForChoosingPreferredApplicationToMenu:menu chosenPreferredApplicationURL:preferredApplicationURL];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[self addMenuItemsForShowInFinderToMenu:menu];

	if (context == GLACollectedFileMenuContextInCollection) {
		[menu addItem:[NSMenuItem separatorItem]];
		
		SEL removeFromHighlightsAction = (self.removeFromHighlightsAction);
		
		NSMenuItem *removeFromHighlightsMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove from Collection", @"Remove collected file from collection menu title for collected files") action:removeFromHighlightsAction keyEquivalent:@""];
		(removeFromHighlightsMenuItem.target) = target;
		[menu addItem:removeFromHighlightsMenuItem];
	}
	else if (context == GLACollectedFileMenuContextInHighlights) {
		// Remove from Highlights
		if (highlightedCollectedFile) {
			[menu addItem:[NSMenuItem separatorItem]];
			
			SEL changeCustomNameHighlightsAction = (self.changeCustomNameHighlightsAction);
			NSMenuItem *changeCustomNameHighlightsMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Use Custom Name…", @"Change custom name highlights menu title") action:changeCustomNameHighlightsAction keyEquivalent:@""];
			(changeCustomNameHighlightsMenuItem.target) = target;
			[menu addItem:changeCustomNameHighlightsMenuItem];
			
			[menu addItem:[NSMenuItem separatorItem]];
			
			SEL removeFromHighlightsAction = (self.removeFromHighlightsAction);
			
			NSMenuItem *removeFromHighlightsMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove from Highlights", @"Remove highlighted file from highlights menu title") action:removeFromHighlightsAction keyEquivalent:@""];
			(removeFromHighlightsMenuItem.target) = target;
			[menu addItem:removeFromHighlightsMenuItem];
		}
	}
}

#pragma mark Notifications

- (void)openerApplicationCombinerDidChangeNotification:(NSNotification *)note
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLACollectedFileMenuCreatorNeedsUpdateNotification object:self];
}

@end

NSString *GLACollectedFileMenuCreatorNeedsUpdateNotification = @"GLACollectedFileMenuCreatorNeedsUpdateNotification";
