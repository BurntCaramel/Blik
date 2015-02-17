//
//  GLAAppDelegate.m
//  Blik
//
//  Created by Patrick Smith on 2/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAAppDelegate.h"
#import <objc/runtime.h>
#import "GLAProjectManager.h"
#import "GLAPreferencesWindowController.h"
#import "GLAApplicationSettingsManager.h"

#define DO_FOLDER_QUERY_TEST 1 && DEBUG

#import "GLAFolderQuery.h"
#import "GLAFolderQueryResults.h"


@interface GLAAppDelegate ()

@property(nonatomic) BOOL hasPrepared;

#if DO_FOLDER_QUERY_TEST
@property(nonatomic) GLAFolderQueryResults *folderQueryResults;
#endif

@end

@implementation GLAAppDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self prepareIfNeeded];
    }
    return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self prepareIfNeeded];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self showMainWindow];
	
#if 0
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	(projectManager.shouldLoadTestProjects) = YES;
#endif
	
	[[GLAApplicationSettingsManager sharedApplicationSettingsManager] ensureAccessToPermittedApplicationsFolders];
	
#if DO_FOLDER_QUERY_TEST
	GLAFolderQuery *folderQuery = [[GLAFolderQuery alloc] initCreatingByEditing:^(id<GLAFolderQueryEditing> editor) {
		(editor.tagNames) = [NSSet setWithObject:@"Backburner"];
	}];
	
	NSURL *folderURL = [NSURL fileURLWithPath:NSHomeDirectory()];
	GLAFolderQueryResults *folderQueryResults = [[GLAFolderQueryResults alloc] initWithFolderQuery:folderQuery folderURLs:@[folderURL]];
	
	[folderQueryResults startSearching];
	(self.folderQueryResults) = folderQueryResults;
#endif
}

- (void)prepareIfNeeded
{
	if (self.hasPrepared) {
		return;
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	(self.statusItemController) = [GLAStatusItemController new];
	[nc addObserver:self selector:@selector(toggleShowingMainWindowAndApplicationHidden:) name:GLAStatusItemControllerItemWasClickedNotification object:(self.statusItemController)];
	
	[nc addObserver:self selector:@selector(helpMenuDidBeginTracking:) name:NSMenuDidBeginTrackingNotification object:(self.mainHelpMenu)];
	
	(self.hasPrepared) = YES;
}

- (BOOL)isShowingWindowController:(NSWindowController *)windowController
{
	if ((windowController != nil) && (windowController.isWindowLoaded)) {
		return [(windowController.window) isVisible];
	}
	else {
		return NO;
	}
}

- (void)createMainWindowController
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		(self.mainWindowController) = [[GLAMainWindowController alloc] initWithWindowNibName:@"GLAMainWindowController"];
	});
}

- (void)showMainWindow
{
	[self createMainWindowController];
	
	[(self.mainWindowController.window) makeKeyAndOrderFront:self];
}

- (void)hideMainWindow
{
	[(self.mainWindowController.window) close];
}

- (BOOL)isShowingMainWindowController
{
	return [self isShowingWindowController:(self.mainWindowController)];
}

#pragma mark Actions

- (IBAction)toggleShowingMainWindow:(id)sender
{
	[self toggleShowingMainWindowToggleApplicationHiddenAlso:NO];
}

- (IBAction)toggleShowingMainWindowAndApplicationHidden:(id)sender
{
	[self toggleShowingMainWindowToggleApplicationHiddenAlso:YES];
}

- (IBAction)toggleShowingMainWindowToggleApplicationHiddenAlso:(BOOL)toggleApplicationHidden
{
	NSApplication *app = NSApp;
	
	BOOL isShowing = (self.isShowingMainWindowController);
	if (toggleApplicationHidden) {
		isShowing = isShowing && (app.isActive);
	}
	
	if (!isShowing) {
		if (toggleApplicationHidden) {
			[app activateIgnoringOtherApps:YES];
		}
		
		[self showMainWindow];
	}
	else {
		if (toggleApplicationHidden) {
			[app hide:nil];
		}
		else {
			[self hideMainWindow];
		}
	}
}

- (void)toggleShowingStatusItem:(id)sender
{
	[(self.statusItemController) toggleShowingItem:sender];
}

- (IBAction)showAppPreferences:(id)sender
{
	GLAPreferencesWindowController *sharedPreferencesWindowController = [GLAPreferencesWindowController sharedPreferencesWindowController];
	//[(sharedPreferencesWindowController.window) display];
	[sharedPreferencesWindowController showWindow:nil];
}

#pragma mark Help Menu

- (void)updateActivityStatusMenuItem
{
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	NSMenuItem *activityStatusMenuItem = (self.activityStatusMenuItem);
	
	NSString *status = (projectManager.statusOfCompletedActivity);
#if DEBUG
	NSLog(@"%@", status);
#endif
	/*NSArray *actionStati = [status componentsSeparatedByString:@"\n"];
	for (NSString *actionStatus in actionStati) {
		
	}*/
	(activityStatusMenuItem.title) = status;
}

- (void)helpMenuDidBeginTracking:(NSNotification *)note
{
	//[self updateActivityStatusMenuItem];
}

#pragma mark Validating UI Items

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
	SEL action = (anItem.action);
	
	if ([(NSObject *)anItem isKindOfClass:[NSMenuItem class]]) {
		NSMenuItem *menuItem = (NSMenuItem *)anItem;
		BOOL stateAsBool = NO;
		
		if (sel_isEqual(@selector(toggleShowingStatusItem:), action)) {
			GLAStatusItemController *statusItemController = (self.statusItemController);
			stateAsBool = (statusItemController.showsItem);
		}
		
		(menuItem.state) = stateAsBool ? NSOnState : NSOffState;
	}
	
	return YES;
}

@end
