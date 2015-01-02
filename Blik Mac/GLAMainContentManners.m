//
//  GLAMainContentManners.m
//  Blik
//
//  Created by Patrick Smith on 15/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAMainContentManners.h"


@implementation GLAMainContentManners

+ (instancetype)sharedManners
{
	static GLAMainContentManners *sharedManners;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedManners = [[GLAMainContentManners alloc] initWithProjectManager:[GLAProjectManager sharedProjectManager]];
	});
	
	return sharedManners;
}

@synthesize projectManager = _projectManager;

- (instancetype)initWithProjectManager:(GLAProjectManager *)projectManager
{
	self = [super init];
	if (self) {
		_projectManager = projectManager;
	}
	return self;
}

#pragma mark -

- (void)askToPermanentlyDeleteProject:(GLAProject *)project fromView:(NSView *)view sectionNavigator:(GLAMainSectionNavigator *)navigator
{
	GLAProjectManager *projectManager = (self.projectManager);
	
	NSAlert *alert = [NSAlert new];
	[alert addButtonWithTitle:NSLocalizedString(@"Delete", @"Button title to delete project.")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Button title to cancel deleting project.")];
	(alert.messageText) = NSLocalizedString(@"Delete the project?", @"Message for deleting a project.");
	(alert.informativeText) = NSLocalizedString(@"If you wish to restore the project and its collections you must do so manually.", @"Informative text for deleting a project and its collections.");
	(alert.alertStyle) = NSWarningAlertStyle;
	
	[alert beginSheetModalForWindow:(view.window) completionHandler:^(NSModalResponse returnCode) {
		if (returnCode == NSAlertFirstButtonReturn) {
			[projectManager permanentlyDeleteProject:project];
		}
	}];
}

@end
