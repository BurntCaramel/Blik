//
//  GLAChooseRemindersViewController.h
//  Blik
//
//  Created by Patrick Smith on 7/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAButton.h"
#import "GLAReminderManager.h"



@interface GLAChooseRemindersViewController : GLAViewController <NSTableViewDataSource, NSTableViewDelegate, NSUserInterfaceValidations>

@property(nonatomic) IBOutlet NSTableView *tableView;

@property(nonatomic) IBOutlet GLAButton *backButton;
@property(nonatomic) IBOutlet NSTextField *instructionsTextField;
@property(nonatomic) IBOutlet NSPopUpButton *calendarPopUpButton;

@property(nonatomic) NSArray *reminders;
@property(nonatomic) NSArray *filteredReminders;
@property(nonatomic) EKCalendar *calendarToFilterWith;

- (IBAction)exit:(id)sender;

@end

extern NSString *GLAChooseRemindersViewControllerDidPerformExitNotification;
