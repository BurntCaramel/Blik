//
//  GLAFileCollectionViewController.h
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAViewController.h"
// View
#import "GLAPopUpButton.h"
#import "GLAQuickLookPreviewHelper.h"
// Model
#import "GLACollection.h"
#import "GLACollectedFilesSetting.h"
#import "GLAFileInfoRetriever.h"
#import "GLAFileOpenerApplicationCombiner.h"


@interface GLAFileCollectionViewController : GLAViewController <NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate, GLAFileInfoRetrieverDelegate>

@property(nonatomic) IBOutlet NSTableView *sourceFilesListTableView;
@property(strong, nonatomic) IBOutlet NSMenu *sourceFilesListContextualMenu;
@property(strong, nonatomic) IBOutlet NSMenuItem *addToHighlightsMenuItem;

@property(strong, nonatomic) IBOutlet GLAPopUpButton *openerApplicationsPopUpButton;
@property(strong, nonatomic) IBOutlet GLAButton *shareButton;
@property(strong, nonatomic) IBOutlet GLAButton *addToHighlightsButton;

@property(nonatomic) IBOutlet NSView *previewHolderView;

@property(nonatomic) GLACollection *filesListCollection;
@property(nonatomic) GLAProject *project;

- (void)makeSourceFilesListFirstResponder;

- (IBAction)openSelectedFiles:(id)sender;
- (IBAction)revealSelectedFilesInFinder:(id)sender;
- (IBAction)removeSelectedFilesFromList:(id)sender;

- (IBAction)addSelectedFilesToHighlights:(id)sender;

@end
