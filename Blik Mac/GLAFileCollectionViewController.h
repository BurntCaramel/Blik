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
// Model
#import "GLACollection.h"
#import "GLAFileInfoRetriever.h"
#import "GLAFileOpenerApplicationCombiner.h"
// Frameworks
@import Quartz;


@interface GLAFileCollectionViewController : GLAViewController <NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate, GLAFileInfoRetrieverDelegate>

@property(nonatomic) IBOutlet NSTableView *sourceFilesListTableView;
@property(strong, nonatomic) IBOutlet NSMenu *sourceFilesListContextualMenu;

@property(strong, nonatomic) IBOutlet GLAPopUpButton *openerApplicationsPopUpButton;
@property(strong, nonatomic) IBOutlet NSTextField *openerApplicationsTextLabel;

@property(strong, nonatomic) IBOutlet GLAButton *addToHighlightsButton;

@property(nonatomic) IBOutlet GLAViewController *previewHolderViewController;
@property(nonatomic) IBOutlet NSView *previewHolderView;
@property(nonatomic) QLPreviewView *quickLookPreviewView;

@property(nonatomic) GLACollection *filesListCollection;
@property(nonatomic) GLAProject *project;

@property(nonatomic) GLAFileInfoRetriever *fileInfoRetriever;
@property(nonatomic) GLAFileOpenerApplicationCombiner *openerApplicationCombiner;

- (void)makeSourceFilesListFirstResponder;

- (IBAction)openSelectedFiles:(id)sender;
- (IBAction)revealSelectedFilesInFinder:(id)sender;
- (IBAction)removeSelectedFilesFromList:(id)sender;

- (IBAction)addSelectedFilesToHighlights:(id)sender;

@end
