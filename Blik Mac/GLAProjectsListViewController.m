//
//  GLAProjectsListViewController.m
//  Blik
//
//  Created by Patrick Smith on 11/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAProjectsListViewController.h"
// MODEL
#import "GLAProjectManager.h"
// VIEW
#import "GLAUIStyle.h"
#import "GLAProjectOverviewTableCellView.h"
#import "GLAArrayEditorTableDraggingHelper.h"


NSString *GLAProjectsListViewControllerDidChooseProjectNotification = @"GLA.projectListViewController.didChooseProject";
NSString *GLAProjectListsViewControllerDidPerformWorkOnProjectNowNotification = @"GLA.projectListViewController.didPerformWorkOnProjectNow";


@interface GLAProjectsListViewController () <GLAArrayEditorTableDraggingHelperDelegate>

@property(nonatomic) GLAArrayEditorTableDraggingHelper *tableDraggingHelper;

@end

@implementation GLAProjectsListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc
{
	[self stopProjectManagingObserving];
}

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	NSTableView *tableView = (self.tableView);
	(tableView.backgroundColor) = (uiStyle.contentBackgroundColor);
	(tableView.enclosingScrollView.backgroundColor) = (uiStyle.contentBackgroundColor);
	(tableView.menu) = (self.contextualMenu);
	
	[tableView registerForDraggedTypes:@[[GLAProject objectJSONPasteboardType]]];
	
	NSScrollView *scrollView = [tableView enclosingScrollView];
	(scrollView.wantsLayer) = YES;
	
	(self.tableDraggingHelper) = [[GLAArrayEditorTableDraggingHelper alloc] initWithDelegate:self];
	
	[self startProjectManagingObserving];
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	[self startProjectManagingObserving];
	[self reloadAllProjects];
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	NSTableView *tableView = (self.tableView);
	NSScrollView *scrollView = [tableView enclosingScrollView];
	[scrollView flashScrollers];
}

- (void)viewWillDisappear
{
	[super viewWillDisappear];
	
	[self stopProjectManagingObserving];
}

- (void)startProjectManagingObserving
{
	[self stopProjectManagingObserving];
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Project Collection List
	[nc addObserver:self selector:@selector(allProjectsDidChangeNotification:) name:GLAProjectManagerAllProjectsDidChangeNotification object:pm];
}

- (void)stopProjectManagingObserving
{
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Stop observing any notifications on the project manager.
	[nc removeObserver:self name:nil object:pm];
}

- (void)allProjectsDidChangeNotification:(NSNotification *)note
{
	[self reloadAllProjects];
}

#pragma mark Actions

@synthesize projects = _projects;

- (void)reloadAllProjects
{
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	[projectManager loadAllProjectsIfNeeded];
	NSArray *projects = [projectManager copyAllProjects];
	
	if (!projects) {
		projects = @[];
	}
	(self.projects) = projects;
	
	[(self.tableView) reloadData];
}

- (GLAProject *)clickedProject
{
	NSInteger clickedRow = (self.tableView.clickedRow);
	if (clickedRow == -1) {
		return nil;
	}
	
	GLAProject *project = (self.projects)[clickedRow];
	
	return project;
}

- (IBAction)tableViewClicked:(id)sender
{
	GLAProject *project = (self.clickedProject);
	if (!project) {
		return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectsListViewControllerDidChooseProjectNotification object:self userInfo:@{@"project": project}];
}

- (IBAction)permanentlyDeleteClickedProject:(id)sender
{
	GLAProject *project = (self.clickedProject);
	if (!project) {
		return;
	}
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	NSAlert *alert = [NSAlert new];
	[alert addButtonWithTitle:NSLocalizedString(@"Delete", @"Button title to delete project.")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Button title to cancel deleting project.")];
	(alert.messageText) = NSLocalizedString(@"Delete the project?", @"Message for deleting a project.");
	(alert.informativeText) = NSLocalizedString(@"The project and its collections will permanently deleted and not able to be restored.", @"Informative text for deleting a project and its collections.");
	(alert.alertStyle) = NSWarningAlertStyle;
	
	[alert beginSheetModalForWindow:(self.view.window) completionHandler:^(NSModalResponse returnCode) {
		if (returnCode == NSAlertFirstButtonReturn) {
			[projectManager permanentlyDeleteProject:project];
		}
	}];
}

- (IBAction)workOnProjectNowClicked:(NSButton *)senderButton
{
	NSInteger projectIndex = (senderButton.tag);
	if (projectIndex == -1) {
		return;
	}
	
	id project = (self.projects)[projectIndex];
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectListsViewControllerDidPerformWorkOnProjectNowNotification object:self userInfo:@{@"project": project}];
}

#pragma mark Table Dragging Helper Delegate

- (void)arrayEditorTableDraggingHelper:(GLAArrayEditorTableDraggingHelper *)tableDraggingHelper makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock
{
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	[pm editAllProjectsUsingBlock:editBlock];
}

- (BOOL)arrayEditorTableDraggingHelper:(GLAArrayEditorTableDraggingHelper *)tableDraggingHelper canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard
{
	return [GLAProject canCopyObjectsFromPasteboard:draggingPasteboard];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.projects.count);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAProject *project = (self.projects)[row];
	return project;
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
	GLAProject *project = (self.projects)[row];
	return project;
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes
{
	return [(self.tableDraggingHelper) tableView:tableView draggingSession:session willBeginAtPoint:screenPoint forRowIndexes:rowIndexes];
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	return [(self.tableDraggingHelper) tableView:tableView draggingSession:session endedAtPoint:screenPoint operation:operation];
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	return [(self.tableDraggingHelper) tableView:tableView validateDrop:info proposedRow:row proposedDropOperation:dropOperation];
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	return [(self.tableDraggingHelper) tableView:tableView acceptDrop:info row:row dropOperation:dropOperation];
}

#pragma mark Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAProjectOverviewTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
	
	GLAUIStyle *activeStyle = [GLAUIStyle activeStyle];
	
	GLAProject *project = (self.projects)[row];
	NSString *displayName = (project.name);
	(cellView.objectValue) = displayName;
	(cellView.textField.stringValue) = displayName;
	
	NSTextField *plannedDateTextField = (cellView.plannedDateTextField);
	(plannedDateTextField.textColor) = (activeStyle.lightTextDisabledColor);
	//(plannedDateTextField.textColor) = (activeStyle.lightTextSecondaryColor);
	
	GLANavigationButton *workOnNowButton = (cellView.workOnNowButton);
	//(workOnNowButton.alwaysHighlighted) = YES;
	(workOnNowButton.target) = self;
	(workOnNowButton.action) = @selector(workOnProjectNowClicked:);
	(workOnNowButton.tag) = row;
	//(workOnNowButton.textHighlightColor) = ([GLAUIStyle activeStyle].deleteProjectButtonColor);
	
	return cellView;
}

@end
