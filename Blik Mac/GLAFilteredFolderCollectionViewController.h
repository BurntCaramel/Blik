//
//  GLAFilteredFolderCollectedViewController.h
//  Blik
//
//  Created by Patrick Smith on 19/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLACollection.h"
#import "GLAFolderQuery.h"
#import "GLAFolderQueryResults.h"
#import "GLAPopUpButton.h"


@interface GLAFilteredFolderCollectionViewController : GLAViewController <NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate>

@property(nonatomic) IBOutlet NSTableView *sourceFilesListTableView;
@property(strong, nonatomic) IBOutlet NSMenu *sourceFilesListContextualMenu;

@property(nonatomic) IBOutlet GLAPopUpButton *sortPriorityPopUpButton;
@property(strong, nonatomic) IBOutlet GLAPopUpButton *openerApplicationsPopUpButton;
@property(strong, nonatomic) IBOutlet GLAButton *shareButton;

@property(nonatomic) IBOutlet NSView *previewHolderView;

@property(nonatomic) GLACollection *filteredFolderCollection;

@end
