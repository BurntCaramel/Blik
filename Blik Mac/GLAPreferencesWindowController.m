//
//  GLAPreferencesWindowController.m
//  Blik
//
//  Created by Patrick Smith on 6/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAPreferencesWindowController.h"
#import "GLAUIStyle.h"

@interface GLAPreferencesWindowController ()

@end

@implementation GLAPreferencesWindowController

+ (instancetype)sharedPreferencesWindowController
{
	static GLAPreferencesWindowController *sharedPreferencesWindowController;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedPreferencesWindowController = [[GLAPreferencesWindowController alloc] initWithWindowNibName:NSStringFromClass([GLAPreferencesWindowController class])];
	});
	
	return sharedPreferencesWindowController;
}


- (void)windowDidLoad
{
	[super windowDidLoad];

	NSWindow *window = (self.window);
	(window.preservesContentDuringLiveResize) = NO;
	
#if 1
	// TODO: check if this will run on 10.9 ok.
	// Dark title bar
	(window.appearance) = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
	
	//GLAUIStyle *style = [GLAUIStyle activeStyle];
	//(window.backgroundColor) = (style.contentBackgroundColor);
#endif
	
	GLAPreferencesSectionNavigator *sectionNavigator = [GLAPreferencesSectionNavigator new];
	
	//GLAPreferencesMainViewController *mainViewController = [[GLAPreferencesMainViewController alloc] initWithNibName:nil bundle:nil];
	GLAPreferencesMainViewController *mainViewController = (self.mainViewController);
	//(mainViewController.view) = (self.mainView);
	(mainViewController.sectionNavigator) = sectionNavigator;
	//(self.mainViewController) = mainViewController;
	
	(self.navigationViewController.sectionNavigator) = sectionNavigator;
	
	
	[sectionNavigator goToSectionWithIdentifier:GLAPreferencesSectionChoose];
}

#pragma mark Window Delegate

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	[[GLAUIStyle activeStyle] secondaryWindowDidBecomeMain:(self.window)];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
	[[GLAUIStyle activeStyle] secondaryWindowDidResignMain:(self.window)];
}

@end
