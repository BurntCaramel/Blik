//
//  GLAAppDelegate.h
//  Blik
//
//  Created by Patrick Smith on 2/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAPrototypeAWindowController.h"
#import "GLAMainWindowController.h"
#import "GLAStatusItemController.h"


@interface GLAAppDelegate : NSObject <NSApplicationDelegate, NSUserInterfaceValidations>

//@property (assign) IBOutlet NSWindow *window;

@property (assign, nonatomic) IBOutlet NSMenuItem *prototypeAMenuItem;
@property (nonatomic) GLAPrototypeAWindowController *prototypeAWindowController;

@property (assign, nonatomic) IBOutlet NSMenuItem *prototypeBMenuItem;
@property (nonatomic) GLAMainWindowController *mainWindowController;

@property (nonatomic) GLAStatusItemController *statusItemController;

- (IBAction)toggleShowingPrototypeA:(id)sender;
- (IBAction)toggleShowingMainWindow:(id)sender;

- (IBAction)toggleShowingStatusItem:(id)sender;

@end
