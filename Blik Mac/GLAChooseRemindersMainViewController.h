//
//  GLAChooseRemindersMainViewController.h
//  Blik
//
//  Created by Patrick Smith on 7/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAButton.h"
#import "GLAReminderManager.h"
@class GLAChooseRemindersTableViewController;



@interface GLAChooseRemindersMainViewController : GLAViewController

@property(nonatomic) IBOutlet GLAChooseRemindersTableViewController *remindersTableViewController;

- (void)showRemindersTable;

@end


@interface GLAChooseRemindersTableViewController : GLAViewController <NSTableViewDataSource, NSTableViewDelegate, NSUserInterfaceValidations>

@property(nonatomic) IBOutlet NSTableView *tableView;

@property(nonatomic) IBOutlet GLAButton *backButton;
@property(nonatomic) IBOutlet NSTextField *titleField;
@property(nonatomic) IBOutlet NSPopUpButton *calendarPopUpButton;

@property(nonatomic) NSArray *reminders;
@property(nonatomic) NSArray *filteredReminders;
@property(nonatomic) EKCalendar *calendarToFilterWith;

@end
