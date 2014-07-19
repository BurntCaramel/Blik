//
//  GLAAppDelegate.m
//  Blik
//
//  Created by Patrick Smith on 2/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAAppDelegate.h"


@implementation GLAAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self toggleShowingPrototypeA:self];
	[self toggleShowingPrototypeB:self];
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

- (void)createPrototypeB
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		(self.prototypeBWindowController) = [[GLAMainWindowController alloc] initWithWindowNibName:@"GLAMainWindowController"];
	});
}

- (BOOL)isShowingPrototypeB
{
	return [self isShowingWindowController:(self.prototypeBWindowController)];
}

- (void)updatePrototypeMenuItems
{
	(self.prototypeAMenuItem.state) = (self.isShowingPrototypeA) ? NSOnState : NSOffState;
	(self.prototypeBMenuItem.state) = (self.isShowingPrototypeB) ? NSOnState : NSOffState;
}

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

- (IBAction)toggleShowingPrototypeB:(id)sender
{
	if (!(self.isShowingPrototypeB)) {
		[self createPrototypeB];
		
		//[(self.prototypeAWindowController) showWindow:self];
		[(self.prototypeBWindowController.window) makeKeyAndOrderFront:self];
	}
	else {
		[(self.prototypeBWindowController.window) close];
	}
	
	[self updatePrototypeMenuItems];
}

@end
