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
#import "GLAProjectView.h"
#import "GLATextField.h"
// MODEL
#import "GLAProject.h"
#import "GLACollection.h"
#import "GLAReminder.h"

@class GLAProjectViewController;
@class GLAChooseRemindersViewController;


@interface GLAProjectPlanViewController : GLAViewController <NSTableViewDelegate, NSTableViewDataSource>

@property(nonatomic) IBOutlet NSTableView *tableView;
@property(nonatomic) IBOutlet NSLayoutConstraint *scrollLeadingConstraint;

@property(weak) IBOutlet GLAProjectViewController *parentViewController;

@property(nonatomic) GLATableActionsViewController *editingActionsViewController;
@property(nonatomic) IBOutlet NSView *editingActionsView;
@property(nonatomic) IBOutlet GLAButton *chooseExistingRemindersButton;
@property(nonatomic) IBOutlet GLAButton *makeNewReminderButton;

@property(nonatomic) GLAProject *project;
@property(copy, nonatomic) NSMutableArray *mutableReminders;

@property(nonatomic) NSDateFormatter *dueDateFormatter;

@property(nonatomic) BOOL editing;
@property(nonatomic) BOOL showsDoesNotHaveAccessToReminders;

//- (void)remindersDidChange;
- (void)reloadReminders;

- (IBAction)chooseExistingReminders:(id)sender;
- (IBAction)makeNewReminder:(id)sender;

@end
