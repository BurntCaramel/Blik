//
//  GLAPrototypeBProjectViewController.h
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAViewController.h"
// VIEW
#import "GLAView.h"
#import "GLAProjectActionsBarController.h"
#import "GLATableActionsViewController.h"
#import "GLAProjectView.h"
#import "GLATextField.h"
// MODEL
#import "GLAProject.h"
#import "GLACollection.h"
#import "GLAReminder.h"

@class GLAProjectCollectionsViewController;
@class GLAProjectPlanViewController;
@class GLAChooseRemindersViewController;


@interface GLAProjectViewController : GLAViewController <GLAViewDelegate, NSTextFieldDelegate>

@property(readonly, nonatomic) GLAProjectView *projectView;

@property(strong, nonatomic) IBOutlet GLAProjectCollectionsViewController *collectionsViewController;
@property(strong, nonatomic) IBOutlet GLAProjectPlanViewController *planViewController;

@property(strong, nonatomic) IBOutlet NSLayoutConstraint *itemsViewLeadingConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *itemsViewHeightConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *itemsViewBottomConstraint;

@property(strong, nonatomic) IBOutlet NSLayoutConstraint *planViewTrailingConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *planViewHeightConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *planViewBottomConstraint;

@property(strong, nonatomic) IBOutlet GLAProjectActionsBarController *actionsBarController;
@property(strong, nonatomic) IBOutlet GLAView *actionsBarHolder;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *actionsBarHolderBottomConstraint;

@property(strong, nonatomic) IBOutlet GLATextField *nameTextField;

@property(nonatomic) GLAProject *project;

- (IBAction)editCollections:(id)sender;
@property(readonly, nonatomic) BOOL editingCollections;

- (IBAction)editPlan:(id)sender;
@property(readonly, nonatomic) BOOL editingPlan;

- (IBAction)chooseExistingReminders:(id)sender;
@property(readonly, nonatomic) BOOL choosingExistingReminders;
@property(nonatomic) GLAChooseRemindersViewController *chooseRemindersViewController;

- (void)clearName;
- (void)focusNameTextField;

@property(readonly, nonatomic) NSScrollView *itemsScrollView;
@property(readonly, nonatomic) NSScrollView *planScrollView;

- (void)matchWithOtherProjectViewController:(GLAProjectViewController *)otherController;

@end

// Notifications

extern NSString *GLAProjectViewControllerDidBeginEditingItemsNotification;
extern NSString *GLAProjectViewControllerDidEndEditingItemsNotification;

extern NSString *GLAProjectViewControllerDidBeginEditingPlanNotification;
extern NSString *GLAProjectViewControllerDidEndEditingPlanNotification;

extern NSString *GLAProjectViewControllerDidEnterCollectionNotification;



@interface GLAProjectCollectionsViewController : GLAViewController <NSTableViewDelegate, NSTableViewDataSource>

@property(nonatomic) IBOutlet NSTableView *tableView;

@property(weak) IBOutlet GLAProjectViewController *parentViewController;

@property(strong, nonatomic) IBOutlet NSMenu *contextualMenu;

@property(nonatomic) GLATableActionsViewController *editingActionsViewController;
@property(nonatomic) IBOutlet NSView *editingActionsView;
@property(nonatomic) IBOutlet GLAButton *makeNewCollectionButton;

@property(nonatomic) GLAProject *project;
@property(copy, nonatomic) NSArray *collections;

@property(nonatomic) BOOL editing;

- (void)reloadCollections;

- (IBAction)makeNewCollection:(id)sender;

@end

extern NSString *GLAProjectCollectionsViewControllerDidClickCollectionNotification;



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
