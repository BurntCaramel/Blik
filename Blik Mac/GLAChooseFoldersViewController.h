//
//  GLAChooseFoldersViewController.h
//  Blik
//
//  Created by Patrick Smith on 6/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLACollectedFileListHelper.h"
#import "GLAArrayTableDraggingHelper.h"
#import "GLAInstructionsViewController.h"


// For project primary folders, permitted application folders, etc.
@interface GLAChooseFoldersViewController : GLAViewController <NSTableViewDataSource, NSTableViewDelegate, GLACollectedFileListHelperDelegate, GLAArrayTableDraggingHelperDelegate>

@property(nonatomic) IBOutlet GLAViewController *mainHolderViewController;
@property(nonatomic) IBOutlet NSView *mainHolderView;

@property(nonatomic) IBOutlet NSTextField *mainLabel;
@property(nonatomic) IBOutlet NSButton *addFoldersButton;

@property(nonatomic) IBOutlet NSTableView *foldersTableView;
@property(nonatomic) IBOutlet NSMenu *foldersTableMenu;

@property(nonatomic) IBOutlet GLAInstructionsViewController *instructionsViewController;


@property(nonatomic) NSArray *collectedFolders;

@property(nonatomic) GLACollectedFileListHelper *foldersListHelper;
@property(nonatomic) GLAArrayTableDraggingHelper *tableDraggingHelper;


 // Needs subclassing:
- (BOOL)canViewFolders;
- (BOOL)hasLoadedFolders;
- (NSArray *)copyFolders;

 // Needs subclassing:
- (void)makeChangesToFoldersUsingEditingBlock:(GLAArrayEditingBlock)editingBlock;

- (BOOL)tableHasDarkBackground;

#pragma mark -

- (void)reloadFolders;


- (void)insertFolderURLs:(NSArray *)folderURLs atOptionalIndex:(NSUInteger)index;
- (void)addFolderURLs:(NSArray *)folderURLs;

- (void)removeFoldersAtIndexes:(NSIndexSet *)indexes;

- (IBAction)addFolder:(id)sender;
- (IBAction)revealSelectedFoldersInFinder:(id)sender;
- (IBAction)removeSelectedFoldersFromList:(id)sender;

@end
