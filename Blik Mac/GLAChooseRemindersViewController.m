//
//  GLAChooseRemindersViewController.m
//  Blik
//
//  Created by Patrick Smith on 7/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAChooseRemindersViewController.h"
#import "GLAUIStyle.h"


@interface GLAChooseRemindersViewController ()

@property(nonatomic) BOOL loadingReminders;

@property(nonatomic) NSTableCellView *heightMeasuringTableViewCell;

@end

@implementation GLAChooseRemindersViewController

- (void)loadView
{
	[super loadView];
	
	
}

- (void)awakeFromNib
{
	GLAUIStyle *activeStyle = [GLAUIStyle activeStyle];
	
	NSTableView *tableView = (self.tableView);
	(tableView.dataSource) = self;
	(tableView.delegate) = self;
	[activeStyle prepareContentTableView:tableView];
	
	NSTableColumn *tableColumn = (tableView.tableColumns)[0];
	(self.heightMeasuringTableViewCell) = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	
	[activeStyle prepareContentTextField:(self.instructionsTextField)];
}

- (void)reloadReminders
{
	if (self.loadingReminders) {
		return;
	}
	
	(self.loadingReminders) = YES;
	
	[self updateCalendarChoiceUI];
	
	//return;
	GLAReminderManager *reminderManager = [GLAReminderManager sharedReminderManager];
	CFAbsoluteTime startTimeUse = CFAbsoluteTimeGetCurrent();
	[reminderManager useAllReminders:^(NSArray *allReminders) {
		CFAbsoluteTime endTimeUse = CFAbsoluteTimeGetCurrent();
		NSLog(@"Took %fs to get all reminders", endTimeUse - startTimeUse);
#if 0
		CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
		NSArray *incompleteReminders = [allReminders filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed = NO"]];
		CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
		NSLog(@"Took %fs to filter reminders", endTime - startTime);
#else
		NSArray *incompleteReminders = allReminders;
#endif
		
		(self.reminders) = incompleteReminders;
		
		[self updateFilteredReminders];
		
		(self.loadingReminders) = NO;
	}];
}

- (void)updateFilteredReminders
{
	NSArray *reminders = (self.reminders);
	NSArray *filteredReminders = reminders;
	
	EKCalendar *calendar = (self.calendarToFilterWith);
	if (calendar) {
		filteredReminders = [reminders filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"calendar = %@", calendar]];
	}
	
	(self.filteredReminders) = filteredReminders;
	
	[(self.tableView) reloadData];
}

- (void)updateCalendarChoiceUI
{
	NSPopUpButton *popUpButton = (self.calendarPopUpButton);
	GLAReminderManager *reminderManager = [GLAReminderManager sharedReminderManager];
	[reminderManager useCurrentAllReminderCalendars:^(NSArray *allReminderCalendars) {
		[popUpButton removeAllItems];
		(popUpButton.target) = self;
		(popUpButton.action) = @selector(selectedCalendarDidChange:);
		
		NSMenu *menu = (popUpButton.menu);
		(menu.autoenablesItems) = NO;
		
		for (EKCalendar *calendar in allReminderCalendars) {
			NSString *title = (calendar.title);
			//NSMenuItem *menuItem = [menu addItemWithTitle:title action:@selector(selectedCalendarDidChange:) keyEquivalent:@""];
			NSMenuItem *menuItem = [menu addItemWithTitle:title action:nil keyEquivalent:@""];
			(menuItem.representedObject) = calendar;
		}
		
		[popUpButton synchronizeTitleAndSelectedItem];
		
		NSMenuItem *selectedMenuItem = (popUpButton.selectedItem);
		if (selectedMenuItem) {
			[self selectedCalendarDidChange:selectedMenuItem];
		}
		else {
			(self.calendarToFilterWith) = nil;
			[self updateFilteredReminders];
		}
	}];
}

- (IBAction)selectedCalendarDidChange:(id)sender
{
	NSMenuItem *menuItem = (self.calendarPopUpButton.selectedItem);
	EKCalendar *calendar = nil;
	if (menuItem) {
		calendar = (menuItem.representedObject);
	}
	
	(self.calendarToFilterWith) = calendar;
	[self updateFilteredReminders];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	return YES;
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	[self reloadReminders];
}

#pragma mark Actions

- (void)exit:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAChooseRemindersViewControllerDidPerformExitNotification object:self];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.filteredReminders.count);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	EKReminder *reminder = (self.filteredReminders)[row];
	return reminder;
}

- (void)setUpTableViewCell:(NSTableCellView *)cellView forColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	EKReminder *reminder = (self.filteredReminders)[row];
	NSString *title = (reminder.title);
	//NSString *middleDot = @"\u00b7";
	//NSString *displayText = [NSString stringWithFormat:@"4PM Today %@ %@", middleDot, title];
	//(cellView.objectValue) = displayText;
	NSString *displayText = title;
	(cellView.textField.stringValue) = displayText;
	
	GLAUIStyle *activeStyle = [GLAUIStyle activeStyle];
	
	NSFont *font;
	NSColor *textColor;
	
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	(paragraphStyle.alignment) = NSLeftTextAlignment;
	
	font = (activeStyle.smallReminderFont);
	(paragraphStyle.maximumLineHeight) = 18.0; //(font.pointSize);
	
	textColor = (activeStyle.lightTextColor);
	
	NSDictionary *attributes =
	@{
	  NSFontAttributeName: font,
	  NSParagraphStyleAttributeName: paragraphStyle,
	  NSForegroundColorAttributeName: textColor
	  };
	(cellView.textField.attributedStringValue) = [[NSMutableAttributedString alloc] initWithString:displayText attributes:attributes];
	//(cellView.textField.font) = font;
	
	(cellView.textField.preferredMaxLayoutWidth) = (tableColumn.width);
}
/*
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	NSTableCellView *cellView = (self.heightMeasuringTableViewCell);
	NSTableColumn *tableColumn = (tableView.tableColumns)[0];
	[self setUpTableViewCell:cellView forColumn:tableColumn row:row];
	
	return (cellView.textField.intrinsicContentSize).height;
}
*/
#pragma mark Table View Delegate

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView
{
	return NO;
}

// http://stackoverflow.com/questions/7504546/view-based-nstableview-with-rows-that-have-dynamic-heights

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	(cellView.canDrawSubviewsIntoLayer) = YES;
	
	[self setUpTableViewCell:cellView forColumn:tableColumn row:row];
	
	return cellView;
}

@end

NSString *GLAChooseRemindersViewControllerDidPerformExitNotification = @"GLAChooseRemindersViewControllerDidPerformExitNotification";
