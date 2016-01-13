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
#import "GLAMainSectionNavigator.h"
#import "GLAProjectActionsBarController.h"
#import "GLATableActionsViewController.h"
#import "GLACollectionColorPickerPopover.h"
#import "GLACollectionColorPickerViewController.h"
#import "GLAProjectView.h"
#import "GLATextField.h"
#import "GLAPendingAddedCollectedFilesInfo.h"
// MODEL
#import "GLAProject.h"
#import "GLACollection.h"
#import "GLAReminder.h"
//#import "Blik-Swift.h"

@class GLAProjectViewController;
@class GLAProjectCollectionsViewController;
@class GLAProjectPlanViewController;
@class GLAProjectHighlightsViewController;
@class GLAInstructionsViewController;
@class GLAChooseRemindersViewController;


@protocol GLAProjectViewControllerDelegate <NSObject>

- (void)projectViewController:(GLAProjectViewController *)projectViewController performAddCollectedFilesToNewCollection:(GLAPendingAddedCollectedFilesInfo *)info;

@end


@interface GLAProjectViewController : GLAViewController <GLAViewDelegate, NSTextFieldDelegate>

@property(nonatomic) GLAProject *project;

@property(nonatomic) GLAMainSectionNavigator *sectionNavigator;

@property(weak, nonatomic) id<GLAProjectViewControllerDelegate> delegate;

#pragma mark -

@property(readonly, nonatomic) GLAProjectView *projectView;

@property(strong, nonatomic) IBOutlet GLAProjectCollectionsViewController *collectionsViewController;
@property(strong, nonatomic) IBOutlet GLAProjectHighlightsViewController *highlightsViewController;
//@property(strong, nonatomic) IBOutlet GLAProjectPlanViewController *planViewController;

@property(strong, nonatomic) IBOutlet NSLayoutConstraint *collectionsViewLeadingConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *collectionsViewHeightConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *collectionsViewBottomConstraint;

@property(strong, nonatomic) IBOutlet NSLayoutConstraint *highlightsViewTrailingConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *highlightsViewHeightConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *highlightsViewBottomConstraint;

@property(strong, nonatomic) IBOutlet GLAProjectActionsBarController *actionsBarController;
@property(strong, nonatomic) IBOutlet GLAView *actionsBarHolder;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *actionsBarHolderBottomConstraint;

@property(strong, nonatomic) IBOutlet GLATextField *nameTextField;

#pragma mark -

- (IBAction)editCollections:(id)sender;
@property(readonly, nonatomic) BOOL editingCollections;
- (IBAction)addNewCollection:(id)sender;
- (IBAction)addNewFilesListCollection:(id)sender;

//- (IBAction)editPlan:(id)sender;
@property(readonly, nonatomic) BOOL editingPlan;

//- (IBAction)chooseExistingReminders:(id)sender;
@property(readonly, nonatomic) BOOL choosingExistingReminders;
@property(nonatomic) GLAChooseRemindersViewController *chooseRemindersViewController;

- (void)clearName;
- (void)focusNameTextField;
- (IBAction)changeName:(id)sender;

@property(readonly, nonatomic) NSScrollView *collectionsScrollView;
@property(readonly, nonatomic) NSScrollView *highlightsScrollView;

- (void)matchWithOtherProjectViewController:(GLAProjectViewController *)otherController;

@end

// Notifications

extern NSString *GLAProjectViewControllerDidBeginEditingCollectionsNotification;
extern NSString *GLAProjectViewControllerDidEndEditingCollectionsNotification;

extern NSString *GLAProjectViewControllerDidBeginEditingPlanNotification;
extern NSString *GLAProjectViewControllerDidEndEditingPlanNotification;

extern NSString *GLAProjectViewControllerDidEnterCollectionNotification;
extern NSString *GLAProjectViewControllerDidRequestPrimaryFoldersNotification;

extern NSString *GLAProjectViewControllerRequestAddNewCollectionNotification;
