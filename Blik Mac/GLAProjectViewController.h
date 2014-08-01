//
//  GLAPrototypeBProjectViewController.h
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAView.h"
#import "GLAProjectActionsBarController.h"
#import "GLAProjectView.h"
#import "GLAProject.h"
#import "GLACollection.h"
#import "GLAReminder.h"

@class GLAProjectCollectionsViewController;
@class GLAProjectPlanViewController;


@interface GLAProjectViewController : GLAViewController <GLAViewDelegate, NSTextFieldDelegate>

@property(readonly, nonatomic) GLAProjectView *projectView;

@property(strong, nonatomic) IBOutlet GLAProjectCollectionsViewController *itemsViewController;
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

@property(strong, nonatomic) IBOutlet NSTextField *nameTextField;

@property(nonatomic) GLAProject *project;

- (IBAction)editItems:(id)sender;
- (IBAction)editPlan:(id)sender;

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

@property(readonly, nonatomic) NSTableView *tableView;

@property(nonatomic) GLAProject *project;
@property(copy, nonatomic) NSArray *collections;

@property(nonatomic) BOOL editing;

- (void)reloadCollections;

@end

extern NSString *GLAProjectCollectionsViewControllerDidClickCollectionNotification;



@interface GLAProjectPlanViewController : GLAViewController <NSTableViewDelegate, NSTableViewDataSource>

@property(readonly, nonatomic) NSTableView *tableView;

@property(nonatomic) GLAProject *project;
@property(copy, nonatomic) NSMutableArray *mutableReminders;

@property(nonatomic) BOOL editing;
@property(nonatomic) BOOL showsDoesNotHaveAccessToReminders;

//- (void)remindersDidChange;
- (void)reloadReminders;

@end
