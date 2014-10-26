//
//  GLAPrototypeAWindowController.m
//  Blik
//
//  Created by Patrick Smith on 2/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAPrototypeAWindowController.h"

@interface GLAPrototypeAWindowController ()

@end

@implementation GLAPrototypeAWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (void)createWorkingFiles
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		GLAPrototypeAFilesViewController *workingFilesViewController = [[GLAPrototypeAFilesViewController alloc] initWithNibName:@"GLAPrototypeAFilesViewController" bundle:nil];
		
		NSPopover *workingFilesPopover = [NSPopover new];
		(workingFilesPopover.contentViewController) = workingFilesViewController;
		(workingFilesPopover.appearance) = NSPopoverAppearanceHUD;
		
		(self.workingFilesViewController) = workingFilesViewController;
		(self.workingFilesPopover) = workingFilesPopover;
	});
}

- (IBAction)showWorkingFiles:(id)sender
{
	NSLog(@"SOHW OWKRING FILES");
	[self createWorkingFiles];
	NSPopover *workingFilesPopover = (self.workingFilesPopover);
	if (!(workingFilesPopover.isShown)) {
		NSButton *mainButton = (self.mainImageButton);
		NSRect positioningRect = NSMakeRect(20.0, 90.0, 140.0, 40.0);
		[workingFilesPopover showRelativeToRect:positioningRect ofView:mainButton preferredEdge:NSMinYEdge];
	}
	else {
		[workingFilesPopover close];
	}
}

@end
