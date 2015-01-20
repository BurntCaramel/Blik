//
//  GLAProjectEditPrimaryFoldersViewController.h
//  Blik
//
//  Created by Patrick Smith on 17/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLACollectedFilesSetting.h"
#import "GLACollectedFileListHelper.h"
#import "GLAArrayTableDraggingHelper.h"


@interface GLAProjectEditPrimaryFoldersViewController : GLAViewController

@property(nonatomic) IBOutlet GLAViewController *mainHolderViewController;
@property(nonatomic) IBOutlet NSView *mainHolderView;

@property(nonatomic) IBOutlet NSTextField *mainLabel;
@property(nonatomic) IBOutlet NSButton *addFoldersButton;

@property(nonatomic) IBOutlet NSTableView *primaryFoldersTableView;
@property(nonatomic) IBOutlet NSMenu *primaryFoldersTableMenu;

@property(nonatomic) GLACollectedFilesSetting *collectedFilesSetting;

@property(nonatomic) GLACollectedFileListHelper *primaryCollectedFoldersListHelper;
@property(nonatomic) GLAArrayTableDraggingHelper *tableDraggingHelper;

@property(nonatomic) GLAProject *project;

- (IBAction)addFolder:(id)sender;
- (IBAction)revealSelectedFoldersInFinder:(id)sender;
- (IBAction)removeSelectedFoldersFromList:(id)sender;

@end
