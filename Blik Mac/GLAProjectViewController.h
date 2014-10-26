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

@class GLAProjectCollectionsViewController;
@class GLAProjectPlanViewController;
@class GLAProjectHighlightsViewController;
@class GLAChooseRemindersViewController;


@interface GLAProjectViewController : GLAViewController <GLAViewDelegate, NSTextFieldDelegate>

@property(readonly, nonatomic) GLAProjectView *projectView;

@property(strong, nonatomic) IBOutlet GLAProjectCollectionsViewController *collectionsViewController;
@property(strong, nonatomic) IBOutlet GLAProjectHighlightsViewController *highlightsViewController;
//@property(strong, nonatomic) IBOutlet GLAProjectPlanViewController *planViewController;

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
- (IBAction)addNewCollection:(id)sender;

- (IBAction)editPlan:(id)sender;
@property(readonly, nonatomic) BOOL editingPlan;

- (IBAction)chooseExistingReminders:(id)sender;
@property(readonly, nonatomic) BOOL choosingExistingReminders;
@property(nonatomic) GLAChooseRemindersViewController *chooseRemindersViewController;

- (void)clearName;
- (void)focusNameTextField;
- (IBAction)changeName:(id)sender;

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

extern NSString *GLAProjectViewControllerRequestAddNewCollectionNotification;
