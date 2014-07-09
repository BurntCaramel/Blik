//
//  GLAPrototypeBProjectViewController.m
//  Glance Prototype A
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAPrototypeBProjectViewController.h"
#import "GLAUIStyle.h"

@interface GLAPrototypeBProjectViewController ()

@end

@implementation GLAPrototypeBProjectViewController

- (GLAPrototypeBProjectView *)projectView
{
	return (id)(self.view);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		
	}
    return self;
}


- (void)loadView
{
	[super loadView];
	
	
}

- (void)awakeFromNib
{
	
}

- (void)editItems:(id)sender
{
	
}

@end



@implementation GLAPrototypeBProjectItemsViewController

- (NSTableView *)tableView
{
	return (id)(self.view);
}

- (void)prepareDummyContent
{
	(self.mutableItems) =
	[
	 @[
	   @"Working Items",
	   @"Briefs",
	   @"Contacts",
	   @"Apps",
	   @"Research"
	   ] mutableCopy];
	
	[(self.tableView) reloadData];
}

- (void)prepareViews
{
	NSTableView *tableView = (self.tableView);
	(tableView.backgroundColor) = ([GLAUIStyle styleA].contentBackgroundColor);
	(tableView.enclosingScrollView.backgroundColor) = ([GLAUIStyle styleA].contentBackgroundColor);
}

- (void)loadView
{
	[super loadView];
	
	[self prepareViews];
}

- (void)awakeFromNib
{
	[self prepareViews];
	[self prepareDummyContent];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.mutableItems.count);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return (self.mutableItems)[row];
}

#pragma mark Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	NSString *displayName = (self.mutableItems)[row];
	(cellView.objectValue) = displayName;
	(cellView.textField.stringValue) = displayName;
	
	return cellView;
}

@end



@implementation GLAPrototypeBProjectPlanViewController

- (NSTableView *)tableView
{
	return (id)(self.view);
}

- (void)prepareDummyContent
{
	(self.mutableReminders) =
	[
	 @[
	   [GLAReminderItem dummyReminderItemWithTitle:@"About page redesign blah blah blah blah longer name"],
	   [GLAReminderItem dummyReminderItemWithTitle:@"Double check Muted Light logo and gallery sliders"],
	   [GLAReminderItem dummyReminderItemWithTitle:@"Prototyping landing page blah blah blah longer name blah blah"],
	   [GLAReminderItem dummyReminderItemWithTitle:@"Brief Stage D completed blah blah blah longer name blah blah"],
	   [GLAReminderItem dummyReminderItemWithTitle:@"Brief Stage E completed blah blah blah longer name blah blah"],
	   [GLAReminderItem dummyReminderItemWithTitle:@"Brief Stage F completed blah blah blah longer name blah blah"],
	   ] mutableCopy];
	
	[(self.tableView) reloadData];
}

- (void)prepareViews
{
	NSTableView *tableView = (self.tableView);
	(tableView.backgroundColor) = ([GLAUIStyle styleA].contentBackgroundColor);
	(tableView.enclosingScrollView.backgroundColor) = ([GLAUIStyle styleA].contentBackgroundColor);
}

- (void)loadView
{
	[super loadView];
	
	[self prepareViews];
}

- (void)awakeFromNib
{
	[self prepareViews];
	[self prepareDummyContent];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.mutableReminders.count);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAReminderItem *reminderItem = (self.mutableReminders)[row];
	return (reminderItem.title);
}

#pragma mark Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	
	GLAReminderItem *reminderItem = (self.mutableReminders)[row];
	NSString *title = (reminderItem.title);
	(cellView.objectValue) = title;
	(cellView.textField.stringValue) = title;
	NSFont *font;
	
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	(paragraphStyle.alignment) = NSRightTextAlignment;
	
	if (row == 0) {
		font = ([GLAUIStyle styleA]).highlightedReminderFont;
		(paragraphStyle.maximumLineHeight) = 21.0; //(font.pointSize);
		(paragraphStyle.lineSpacing) = 0.0;
	}
	else {
		font = ([GLAUIStyle styleA]).smallReminderFont;
		(paragraphStyle.maximumLineHeight) = 18.0; //(font.pointSize);
	}
	
	NSDictionary *attributes =
  @{
	NSFontAttributeName: font,
	NSParagraphStyleAttributeName: paragraphStyle
	};
	(cellView.textField.attributedStringValue) = [[NSMutableAttributedString alloc] initWithString:title attributes:attributes];
	//(cellView.textField.font) = font;
	
	return cellView;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	if (row == 0) {
		return 2.0 * 21.0;
	}
	else {
		//return 2.0 * 18.0;
		return 2.0 * 21.0;
	}
}

@end