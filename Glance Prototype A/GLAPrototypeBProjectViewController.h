//
//  GLAPrototypeBProjectViewController.h
//  Glance Prototype A
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLAPrototypeBProjectView.h"
#import "GLAReminderItem.h"

@class GLAPrototypeBProjectItemsViewController;
@class GLAPrototypeBProjectPlanViewController;


@interface GLAPrototypeBProjectViewController : NSViewController

@property (readonly, nonatomic) IBOutlet GLAPrototypeBProjectView *projectView;

@property (strong, nonatomic) IBOutlet GLAPrototypeBProjectItemsViewController *itemsViewController;
@property (strong, nonatomic) IBOutlet GLAPrototypeBProjectPlanViewController *planViewController;

- (IBAction)editItems:(id)sender;

@end



@interface GLAPrototypeBProjectItemsViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>

@property (readonly, nonatomic) NSTableView *tableView;

@property (copy, nonatomic) NSMutableArray *mutableItems;

@end



@interface GLAPrototypeBProjectPlanViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>

@property (readonly, nonatomic) NSTableView *tableView;

@property (copy, nonatomic) NSMutableArray *mutableReminders;

@end