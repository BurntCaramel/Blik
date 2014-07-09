//
//  GLAPrototypeBWindowController.h
//  Glance Prototype A
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAPrototypeBProjectViewController.h"

@interface GLAPrototypeBWindowController : NSWindowController

@property (nonatomic) GLAPrototypeBProjectViewController *projectViewController;

@property (nonatomic) IBOutlet NSView *contentView;

- (IBAction)changeMainSection:(id)sender;

@end
