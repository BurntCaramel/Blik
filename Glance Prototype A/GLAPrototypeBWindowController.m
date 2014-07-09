//
//  GLAPrototypeBWindowController.m
//  Glance Prototype A
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAPrototypeBWindowController.h"

@interface GLAPrototypeBWindowController ()

@end

@implementation GLAPrototypeBWindowController

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
	(self.window.movableByWindowBackground) = YES;
	
	
	(self.projectViewController) = [[GLAPrototypeBProjectViewController alloc] initWithNibName:@"GLAPrototypeBProjectViewController" bundle:nil];
	NSView *projectView = (self.projectViewController.view);
	
	NSView *contentView = (self.contentView);
	[contentView addSubview:projectView];
	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[projectView]|" options:NSLayoutConstraintOrientationHorizontal metrics:nil views:@{@"projectView": projectView}]];
	
}

- (IBAction)changeMainSection:(id)sender
{
	
}

@end
