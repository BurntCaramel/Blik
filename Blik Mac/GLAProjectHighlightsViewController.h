//
//  GLAProjectHighlightsViewController.h
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAInstructionsViewController.h"
#import "GLAProject.h"
#import "GLAHighlightedItem.h"
#import "GLAFileOpenerApplicationCombiner.h"

@class GLAProjectViewController;


@interface GLAProjectHighlightsViewController : GLAViewController <NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate>

@property(nonatomic) IBOutlet NSTableView *tableView;
@property(nonatomic) IBOutlet NSLayoutConstraint *scrollLeadingConstraint;

@property(nonatomic) IBOutlet NSMenu *contextualMenu;
@property(nonatomic) IBOutlet NSMenu *openerApplicationMenu;
@property(nonatomic) IBOutlet NSMenu *preferredOpenerApplicationMenu;

@property(weak) IBOutlet GLAProjectViewController *parentViewController;

@property(strong, nonatomic) IBOutlet GLAInstructionsViewController *instructionsViewController;

@property(nonatomic) GLAProject *project;
@property(nonatomic) NSArray *highlightedItems;

@property(nonatomic) GLAFileOpenerApplicationCombiner *openerApplicationCombiner;

- (IBAction)removedClickedItem:(id)sender;

@end
