//
//  GLAAppDelegate.m
//  Blik
//
//  Created by Patrick Smith on 2/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAAppDelegate.h"
#import <objc/runtime.h>
#import "GLAProjectManager.h"


@interface GLAAppDelegate ()

@property(nonatomic) BOOL hasPrepared;

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
	//[self toggleShowingPrototypeA:self];
	[self toggleShowingMainWindow:self];
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	(projectManager.shouldLoadTestProjects) = YES;
}

- (void)prepareIfNeeded
{
	if (self.hasPrepared) {
		return;
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	(self.statusItemController) = [GLAStatusItemController new];
	[nc addObserver:self selector:@selector(toggleShowingMainWindowAndApplicationHidden:) name:GLAStatusItemControllerToggleNotification object:(self.statusItemController)];
	
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

- (void)createPrototypeA
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		(self.prototypeAWindowController) = [[GLAPrototypeAWindowController alloc] initWithWindowNibName:@"GLAPrototypeAWindowController"];
	});
}

- (BOOL)isShowingPrototypeA
{
	return [self isShowingWindowController:(self.prototypeAWindowController)];
}

- (void)createMainWindowController
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		(self.mainWindowController) = [[GLAMainWindowController alloc] initWithWindowNibName:@"GLAMainWindowController"];
	});
}

- (BOOL)isShowingMainWindowController
{
	return [self isShowingWindowController:(self.mainWindowController)];
}

- (void)updatePrototypeMenuItems
{
	(self.prototypeAMenuItem.state) = (self.isShowingPrototypeA) ? NSOnState : NSOffState;
	(self.prototypeBMenuItem.state) = (self.isShowingMainWindowController) ? NSOnState : NSOffState;
}

#pragma mark Actions

- (IBAction)toggleShowingPrototypeA:(id)sender
{
	if (!(self.isShowingPrototypeA)) {
		[self createPrototypeA];
		
		//[(self.prototypeAWindowController) showWindow:self];
		[(self.prototypeAWindowController.window) makeKeyAndOrderFront:self];
	}
	else {
		[(self.prototypeAWindowController.window) close];
	}
	
	[self updatePrototypeMenuItems];
}

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
		
		[self createMainWindowController];
		
		//[(self.prototypeAWindowController) showWindow:self];
		[(self.mainWindowController.window) makeKeyAndOrderFront:self];
	}
	else {
		if (toggleApplicationHidden) {
			[app hide:nil];
		}
		else {
			[(self.mainWindowController.window) close];
		}
	}
	
	[self updatePrototypeMenuItems];
}

- (void)toggleShowingStatusItem:(id)sender
{
	[(self.statusItemController) toggleShowing:sender];
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
