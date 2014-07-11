//
//  GLAPrototypeBWindowController.h
//  Glance Prototype A
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAMainNavigationBarController.h"
#import "GLAPrototypeBProjectViewController.h"
#import "GLAMainNavigationBarController.h"
#import "GLAView.h"

@interface GLAPrototypeBWindowController : NSWindowController <GLAMainNavigationBarControllerDelegate>

@property (nonatomic) GLAMainNavigationBarController *mainNavigationBarController;
@property (nonatomic) GLAPrototypeBProjectViewController *projectViewController;

@property (nonatomic) GLAMainNavigationSection currentSection;

@property (nonatomic) IBOutlet NSView *barHolderView;
@property (nonatomic) IBOutlet NSView *contentView;



@end
