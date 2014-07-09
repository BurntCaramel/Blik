//
//  GLAAppDelegate.h
//  Glance Prototype A
//
//  Created by Patrick Smith on 2/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLAPrototypeAWindowController.h"
#import "GLAPrototypeBWindowController.h"

@interface GLAAppDelegate : NSObject <NSApplicationDelegate>

//@property (assign) IBOutlet NSWindow *window;

@property (assign, nonatomic) IBOutlet NSMenuItem *prototypeAMenuItem;
@property (nonatomic) GLAPrototypeAWindowController *prototypeAWindowController;

@property (assign, nonatomic) IBOutlet NSMenuItem *prototypeBMenuItem;
@property (nonatomic) GLAPrototypeBWindowController *prototypeBWindowController;

- (IBAction)toggleShowingPrototypeA:(id)sender;
- (IBAction)toggleShowingPrototypeB:(id)sender;

@end
