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
#import "GLAPrototypeBProjectView.h"
#import "GLAReminderItem.h"

@class GLAProjectItemsViewController;
@class GLAProjectPlanViewController;


@interface GLAProjectViewController : GLAViewController <GLAViewDelegate, NSTextFieldDelegate>

@property(readonly, nonatomic) GLAPrototypeBProjectView *projectView;

@property(strong, nonatomic) IBOutlet GLAProjectItemsViewController *itemsViewController;
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

@property(nonatomic) id project;

- (IBAction)editItems:(id)sender;
- (IBAction)editPlan:(id)sender;

@end

extern NSString *GLAProjectViewControllerDidBeginEditingItemsNotification;
extern NSString *GLAProjectViewControllerDidEndEditingItemsNotification;

extern NSString *GLAProjectViewControllerDidBeginEditingPlanNotification;
extern NSString *GLAProjectViewControllerDidEndEditingPlanNotification;



@interface GLAProjectItemsViewController : GLAViewController <NSTableViewDelegate, NSTableViewDataSource>

@property (readonly, nonatomic) NSTableView *tableView;

@property (copy, nonatomic) NSMutableArray *mutableItems;

@end



@interface GLAProjectPlanViewController : GLAViewController <NSTableViewDelegate, NSTableViewDataSource>

@property (readonly, nonatomic) NSTableView *tableView;

@property (copy, nonatomic) NSMutableArray *mutableReminders;

@end