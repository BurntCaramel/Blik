//
//  GLAPrototypeBProjectViewController.m
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import QuartzCore;
#import "GLAProjectPlanViewController.h"
#import "GLAProjectViewController.h"
#import "GLAUIStyle.h"
#import "GLAProjectManager.h"
#import "GLAReminderManager.h"
#import "GLAChooseRemindersViewController.h"
#import <objc/runtime.h>


@interface GLAProjectPlanViewController ()
{
	GLAProject *_project;
}

@property(nonatomic) BOOL private_editing;

@property(nonatomic) NSTableCellView *measuringTableCellView;

@end

@implementation GLAProjectPlanViewController

@synthesize project = _project;

- (void)setProject:(GLAProject *)project
{
	if (_project != project) {
		_project = project;
		
		[self prepareDummyContent];
	}
}


- (void)prepareDummyContent
{
	(self.mutableReminders) =
	[
	 @[
	   //[GLAReminder dummyReminderWithTitle:@"About page redesign blah blah blah blah longer name"],
	   [GLAReminder dummyReminderWithTitle:@"About page"],
	   [GLAReminder dummyReminderWithTitle:@"Straight to the point"],
	   [GLAReminder dummyReminderWithTitle:@"Prototyping landing page blah blah blah longer name oh so long long long long"],
	   [GLAReminder dummyReminderWithTitle:@"Brief Stage D completed blah blah blah longer name blah blah"],
	   [GLAReminder dummyReminderWithTitle:@"Brief Stage E completed blah blah blah longer name blah blah"],
	   [GLAReminder dummyReminderWithTitle:@"Brief Stage F completed blah blah blah longer name blah blah"],
	   ] mutableCopy];
	
	[self reloadReminders];
}

- (void)reloadReminders
{
	[(self.tableView) reloadData];
}

- (void)prepareView
{
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	NSTableView *tableView = (self.tableView);
	[uiStyle prepareContentTableView:tableView];
	
	NSScrollView *scrollView = (tableView.enclosingScrollView);
	// I think Apple says this is better for scrolling performance.
	(scrollView.wantsLayer) = YES;
	
	NSTableColumn *mainColumn = (tableView.tableColumns)[0];
	(self.measuringTableCellView) = [tableView makeViewWithIdentifier:(mainColumn.identifier) owner:nil];
	
	[self wrapScrollView];
	[self setUpEditingActionsView];
	
	
	NSDateFormatter *dueDateFormatter = [NSDateFormatter new];
	(dueDateFormatter.timeStyle) = NSDateFormatterShortStyle;
	(dueDateFormatter.dateStyle) = NSDateFormatterMediumStyle;
	//(dueDateFormatter.doesRelativeDateFormatting) = YES;
	NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEE h:mm a" options:0 locale:[NSLocale autoupdatingCurrentLocale]];
	(dueDateFormatter.dateFormat) = dateFormat;
	(self.dueDateFormatter) = dueDateFormatter;
	
	
	GLAReminderManager *reminderManager = [GLAReminderManager sharedReminderManager];
	[reminderManager createEventStoreIfNeeded];
}

- (void)wrapScrollView
{
	// Wrap the plan scroll view with a holder view
	// to allow constraints to be more easily worked with
	// and enable an actions view to be added underneath.
	
	NSScrollView *scrollView = (self.tableView.enclosingScrollView);
	(scrollView.identifier) = @"tableScrollView";
	(scrollView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	GLAView *holderView = [[GLAView alloc] init];
	(holderView.identifier) = @"planListHolderView";
	(holderView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	GLAProjectViewController *projectViewController = (self.parentViewController);
	NSLayoutConstraint *planViewTrailingConstraint = (projectViewController.highlightsViewTrailingConstraint);
	NSLayoutConstraint *planViewBottomConstraint = (projectViewController.highlightsViewBottomConstraint);
	
	[projectViewController wrapChildViewKeepingOutsideConstraints:scrollView withView:holderView constraintVisitor:^ (NSLayoutConstraint *oldConstraint, NSLayoutConstraint *newConstraint) {
		if (oldConstraint == planViewTrailingConstraint) {
			(newConstraint.identifier) = [GLAViewController layoutConstraintIdentifierWithBaseIdentifier:@"trailing" forChildView:holderView];
			(projectViewController.highlightsViewTrailingConstraint) = newConstraint;
		}
		else if (oldConstraint == planViewBottomConstraint) {
			(newConstraint.identifier) = [GLAViewController layoutConstraintIdentifierWithBaseIdentifier:@"bottom" forChildView:holderView];
			(projectViewController.highlightsViewBottomConstraint) = newConstraint;
		}
	}];
	
	(self.view) = holderView;
	
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeWidth withChildView:scrollView identifier:@"width"];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeTop withChildView:scrollView identifier:@"top"];
	(self.scrollLeadingConstraint) = [self addLayoutConstraintToMatchAttribute:NSLayoutAttributeLeading withChildView:scrollView identifier:@"leading"];
}

- (void)setUpEditingActionsView
{
	GLATableActionsViewController *editingActionsViewController = [GLATableActionsViewController new];
	(self.editingActionsViewController) = editingActionsViewController;
	
	NSView *editingActionsView = (self.editingActionsView);
	(editingActionsView.identifier) = @"planEditingActions";
	(editingActionsView.translatesAutoresizingMaskIntoConstraints) = NO;
	(editingActionsViewController.view) = editingActionsView;
	
	NSScrollView *scrollView = (self.tableView.enclosingScrollView);
	NSView *view = (self.view);
	
	[editingActionsViewController addInsideView:view underRelativeToView:scrollView];
	[editingActionsViewController addBottomConstraintToView:view];
}

- (BOOL)editing
{
	return (self.private_editing);
}

- (void)setEditing:(BOOL)editing
{
	(self.private_editing) = editing;
	
	[self reloadReminders];
	
	GLATableActionsViewController *editingActionsViewController = (self.editingActionsViewController);
	NSView *editingActionsView = (editingActionsViewController.view);
	NSLayoutConstraint *actionsHeightConstraint = (editingActionsViewController.heightConstraint);
	NSLayoutConstraint *scrollToActionsConstraint = (editingActionsViewController.topConstraint);
	NSLayoutConstraint *actionsBottomConstraint = (editingActionsViewController.bottomConstraint);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		(context.duration) = 3.0 / 12.0;
		
		if (editing) {
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
			(editingActionsView.alphaValue) = 0.0;
			(editingActionsView.animator.alphaValue) = 1.0;
			(actionsHeightConstraint.animator.constant) = 70.0;
			(scrollToActionsConstraint.animator.constant) = 8.0;
			(actionsBottomConstraint.animator.constant) = 12.0;
		}
		else {
			(context.timingFunction) = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
			(editingActionsView.animator.alphaValue) = 0.0;
			(actionsHeightConstraint.animator.constant) = 0.0;
			(scrollToActionsConstraint.animator.constant) = 0.0;
			(actionsBottomConstraint.animator.constant) = 0.0;
		}
		
		//[projectView layoutSubtreeIfNeeded];
	} completionHandler:^ {
		//(self.animatingFocusChange) = NO;
	}];
}

- (IBAction)chooseExistingReminders:(id)sender
{
	//[(self.parentViewController) chooseExistingReminders:sender];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.mutableReminders.count);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAReminder *reminderItem = (self.mutableReminders)[row];
	return (reminderItem.title);
}

#pragma mark Table View Delegate

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView
{
	return NO;
}

- (void)setUpTableCellView:(NSTableCellView *)cellView forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	(cellView.backgroundStyle) = NSBackgroundStyleDark;
	
	NSTextField *textField = (cellView.textField);
	
	GLAReminder *reminderItem = (self.mutableReminders)[row];
	NSString *title = (reminderItem.title);
	NSString *dividerText = @" \u00b7 ";
	NSString *dueDateText = @"";
	//NSString *dividerText = @" ";
	
	BOOL hasDueDate = (reminderItem.dueDateComponents) != nil;
	if (hasDueDate) {
		NSDateFormatter *dueDateFormatter = (self.dueDateFormatter);
		NSDateComponents *dateComponents = (reminderItem.dueDateComponents);
		dueDateText = [dueDateFormatter stringFromDate:(dateComponents.date)];
#if 0
		NSLog(@"DUE DATE %@ %@; %@", dateComponents, (dateComponents.date), dueDateFormatter);
#endif
		//dueDateText = @"4PM today";
	}
	
	GLAUIStyle *activeStyle = [GLAUIStyle activeStyle];
	
	NSFont *titleFont = (activeStyle.smallReminderFont);
	NSFont *dueDateFont = (activeStyle.smallReminderDueDateFont);
	
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	(paragraphStyle.alignment) = NSRightTextAlignment;
	(paragraphStyle.maximumLineHeight) = 18.0;
	
	NSColor *textColor = (self.editing) ? (activeStyle.lightTextColor) : [activeStyle lightTextColorAtLevel:row];
	
	BOOL firstLineBigger = YES;
	
	if ((row == 0) && firstLineBigger) {
		titleFont = (activeStyle.highlightedReminderFont);
		dueDateFont = (activeStyle.highlightedReminderDueDateFont);
		(paragraphStyle.maximumLineHeight) = 21.0; //(font.pointSize);
		(paragraphStyle.lineSpacing) = 0.0;
	}
	
	NSDictionary *titleAttributes =
	@{
	  NSFontAttributeName: titleFont,
	  NSParagraphStyleAttributeName: paragraphStyle,
	  NSForegroundColorAttributeName: textColor
	  };
	
	NSDictionary *dueDateAttributes =
	@{
	  NSFontAttributeName: dueDateFont,
	  NSParagraphStyleAttributeName: paragraphStyle,
	  NSForegroundColorAttributeName: textColor
	  };
	
	NSMutableAttributedString *wholeAttrString = [NSMutableAttributedString new];
	if (hasDueDate) {
		// Due date
		NSRange dueDateRange = NSMakeRange((wholeAttrString.length), (dueDateText.length) + (dividerText.length));
		[(wholeAttrString.mutableString) appendString:dueDateText];
		[(wholeAttrString.mutableString) appendString:dividerText];
		[wholeAttrString setAttributes:dueDateAttributes range:dueDateRange];
	}
	
	// Title
	NSRange titleRange = NSMakeRange((wholeAttrString.length), (title.length));
	[(wholeAttrString.mutableString) appendString:title];
	[wholeAttrString setAttributes:titleAttributes range:titleRange];
	
	(textField.attributedStringValue) = wholeAttrString;
	
	//(textField.preferredMaxLayoutWidth) = (tableColumn.width);
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	NSTableCellView *cellView = (self.measuringTableCellView);
	[self setUpTableCellView:cellView forTableColumn:nil row:row];
	
	NSTableColumn *tableColumn = (tableView.tableColumns)[0];
	CGFloat cellWidth = (tableColumn.width);
	(cellView.frameSize) = NSMakeSize(cellWidth, 100.0);
	[cellView layoutSubtreeIfNeeded];
	
	NSTextField *textField = (cellView.textField);
	//(textField.preferredMaxLayoutWidth) = (tableColumn.width);
	(textField.preferredMaxLayoutWidth) = NSWidth(textField.bounds);
	
	CGFloat extraPadding = 8.0;
	
	return (textField.intrinsicContentSize.height) + extraPadding;

	/*
	if (row == 0) {
		return 2.0 * 21.0;
	}
	else {
		//return 2.0 * 18.0;
		return 2.0 * 21.0;
	}*/
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	(cellView.canDrawSubviewsIntoLayer) = YES;
	
	[self setUpTableCellView:cellView forTableColumn:tableColumn row:row];
	
	//(cellView.layer.backgroundColor) = [NSColor redColor].CGColor;
	
	return cellView;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	return [tableView makeViewWithIdentifier:NSTableViewRowViewKey owner:nil];
}

@end