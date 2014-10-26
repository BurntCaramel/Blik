//
//  GLAPrototypeAWindowController.h
//  Blik
//
//  Created by Patrick Smith on 2/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLAPrototypeAFilesViewController.h"

@interface GLAPrototypeAWindowController : NSWindowController

@property (nonatomic) IBOutlet NSButton *mainImageButton;

@property (nonatomic) GLAPrototypeAFilesViewController *workingFilesViewController;
@property (nonatomic) NSPopover *workingFilesPopover;

- (IBAction)showWorkingFiles:(id)sender;

@end
