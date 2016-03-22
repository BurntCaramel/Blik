//
//  GLAPrototypeBProjectViewController.h
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;
#import "GLAViewController.h"
// VIEW
#import "GLAView.h"
#import "GLAProjectActionsBarController.h"
#import "GLATableActionsViewController.h"
#import "GLACollectionColorPickerPopover.h"
#import "GLACollectionColorPickerViewController.h"
#import "GLATextField.h"
#import "GLAInstructionsViewController.h"
#import "GLAAddCollectedFilesChoiceActions.h"
// MODEL
#import "GLAProject.h"
#import "GLACollection.h"
#import "Blik-Swift.h"

@class GLAProjectViewController;


@interface GLAProjectCollectionsViewController : GLAViewController <NSTableViewDelegate, NSTableViewDataSource, CollectionItemAssistantDelegate>

@property(weak, nonatomic) id<GLAAddCollectedFilesChoiceActionsDelegate> addCollectedFilesChoiceActionsDelegate;

@property(nonatomic) IBOutlet NSTableView *tableView;

@property(weak) IBOutlet GLAProjectViewController *parentViewController;

@property(strong, nonatomic) IBOutlet GLAInstructionsViewController *instructionsViewController;

@property(readonly, nonatomic) GLACollectionColorPickerPopover *colorPickerPopover;
@property(nonatomic) NSPopover *colorChoicePopover;
@property(nonatomic) GLACollectionColorPickerViewController *colorPickerViewController;

@property(nonatomic) GLATableActionsViewController *editingActionsViewController;
@property(nonatomic) IBOutlet NSView *editingActionsView;
@property(nonatomic) IBOutlet GLAButton *makeNewCollectionButton;

@property(nonatomic) GLAProject *project;

@property(nonatomic) BOOL editing;

@property(nonatomic) CollectionItemAssistant *collectionItemAssistant;

- (void)reloadCollections;

//- (IBAction)makeNewCollection:(id)sender;

- (void)deleteCollection:(GLACollection *)collection atRow:(NSInteger)collectionRow;
- (IBAction)permanentlyDeleteClickedCollection:(id)sender;
- (IBAction)renameClickedCollection:(id)sender;

@property(nonatomic) GLACollection *collectionWithDetailsBeingEdited;
- (void)editDetailsOfCollection:(GLACollection *)collection atRow:(NSInteger)collectionRow;
- (void)chooseColorForCollection:(GLACollection *)collection atRow:(NSInteger)collectionRow;

@end

extern NSString *GLAProjectCollectionsViewControllerDidClickCollectionNotification;
extern NSString *GLAProjectCollectionsViewControllerDidClickPrimaryFoldersNotification;
