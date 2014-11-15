//
//  GLAProjectHighlightsViewController.m
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAProjectHighlightsViewController.h"
// VIEW
#import "GLAProjectViewController.h"
#import "GLAUIStyle.h"
#import "GLAView.h"
#import "GLAHighlightsTableCellView.h"
#import "GLAArrayEditorTableDraggingHelper.h"
// MODEL
#import "GLAProjectManager.h"
#import "GLAFileOpenerApplicationCombiner.h"


@interface GLAProjectHighlightsViewController () <GLAArrayEditorTableDraggingHelperDelegate>

@property(nonatomic) BOOL doNotUpdateViews;

@property(nonatomic) GLAHighlightsTableCellView *measuringTableCellView;

@property(nonatomic) GLAArrayEditorTableDraggingHelper *tableDraggingHelper;

@end

@implementation GLAProjectHighlightsViewController

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	NSTableView *tableView = (self.tableView);
	(tableView.menu) = (self.contextualMenu);
	[uiStyle prepareContentTableView:tableView];
	
	[tableView registerForDraggedTypes:@[[GLAHighlightedCollectedFile objectJSONPasteboardType]]];
	
	NSScrollView *scrollView = (tableView.enclosingScrollView);
	// I think Apple says this is better for scrolling performance.
	(scrollView.wantsLayer) = YES;
	
	NSTableColumn *mainColumn = (tableView.tableColumns)[0];
	(self.measuringTableCellView) = [tableView makeViewWithIdentifier:(mainColumn.identifier) owner:nil];
	
	[self wrapScrollView];
	
	NSMenu *openerApplicationMenu = (self.openerApplicationMenu);
	(openerApplicationMenu.delegate) = self;
	
	NSMenu *preferredOpenerApplicationMenu = (self.preferredOpenerApplicationMenu);
	(preferredOpenerApplicationMenu.delegate) = self;
	
	(self.tableDraggingHelper) = [[GLAArrayEditorTableDraggingHelper alloc] initWithDelegate:self];
	
	[self setUpFileHelpers];
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
	(holderView.identifier) = @"highlightsListHolderView";
	(holderView.translatesAutoresizingMaskIntoConstraints) = NO;
	
	GLAProjectViewController *projectViewController = (self.parentViewController);
	NSLayoutConstraint *planViewTrailingConstraint = (projectViewController.planViewTrailingConstraint);
	NSLayoutConstraint *planViewBottomConstraint = (projectViewController.planViewBottomConstraint);
	
	[projectViewController wrapChildViewKeepingOutsideConstraints:scrollView withView:holderView constraintVisitor:^ (NSLayoutConstraint *oldConstraint, NSLayoutConstraint *newConstraint) {
		if (oldConstraint == planViewTrailingConstraint) {
			(newConstraint.identifier) = [GLAViewController layoutConstraintIdentifierWithBaseIdentifier:@"trailing" forChildView:holderView];
			(projectViewController.planViewTrailingConstraint) = newConstraint;
		}
		else if (oldConstraint == planViewBottomConstraint) {
			(newConstraint.identifier) = [GLAViewController layoutConstraintIdentifierWithBaseIdentifier:@"bottom" forChildView:holderView];
			(projectViewController.planViewBottomConstraint) = newConstraint;
		}
	}];
	
	(self.view) = holderView;
	
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeWidth withChildView:scrollView identifier:@"width"];
	[self addLayoutConstraintToMatchAttribute:NSLayoutAttributeTop withChildView:scrollView identifier:@"top"];
	(self.scrollLeadingConstraint) = [self addLayoutConstraintToMatchAttribute:NSLayoutAttributeLeading withChildView:scrollView identifier:@"leading"];
}

- (void)setUpFileHelpers
{
	GLAFileOpenerApplicationCombiner * openerApplicationCombiner = [GLAFileOpenerApplicationCombiner new];
	(self.openerApplicationCombiner) = openerApplicationCombiner;
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(openerApplicationCombinerDidChangeNotification:) name:GLAFileURLOpenerApplicationCombinerDidChangeNotification object:openerApplicationCombiner];
}

- (void)dealloc
{
	[self stopProjectObserving];
}

@synthesize project = _project;

- (void)setProject:(GLAProject *)project
{
	if (_project == project) {
		return;
	}
	
	BOOL isSameProject = (_project != nil) && (project != nil) && [(_project.UUID) isEqual:(project.UUID)];
	
	[self stopProjectObserving];
	
	_project = project;
	
	[self startProjectObserving];
	
	if (!isSameProject) {
		GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
		[projectManager loadCollectionsForProjectIfNeeded:project];
		[projectManager loadHighlightsForProjectIfNeeded:project];
		
		[self reloadHighlightedItems];
	}
}

- (void)startProjectObserving
{
	GLAProject *project = (self.project);
	if (!project) {
		return;
	}
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Project Collection List
	[nc addObserver:self selector:@selector(projectHighlightsDidChangeNotification:) name:GLAProjectHighlightsDidChangeNotification object:[pm notificationObjectForProject:project]];
}

- (void)stopProjectObserving
{
	GLAProject *project = (self.project);
	if (!project) {
		return;
	}
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// Stop observing any notifications on the project manager.
	[nc removeObserver:self name:nil object:[pm notificationObjectForProject:project]];
}

- (void)startCollectionObserving
{
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	for (GLAHighlightedItem *highlightedItem in (self.highlightedItems)) {
		NSUUID *collectionUUID = nil;
		
		if ([highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
			GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
			collectionUUID = (highlightedCollectedFile.holdingCollectionUUID);
		}
		
		if (!collectionUUID) {
			continue;
		}
		
		[nc addObserver:self selector:@selector(collectionDidChangeNotification:) name:GLACollectionDidChangeNotification object:[pm notificationObjectForCollectionUUID:collectionUUID]];
		[nc addObserver:self selector:@selector(collectionDidChangeNotification:) name:GLACollectionFilesListDidChangeNotification object:[pm notificationObjectForCollectionUUID:collectionUUID]];
	}
}

- (void)stopCollectionObserving
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:GLACollectionDidChangeNotification object:nil];
}

- (void)showInstructions
{
	NSView *instructionsView = (self.instructionsViewController.view);
	if (!(instructionsView.superview)) {
		[self fillViewWithChildView:instructionsView];
	}
	else {
		(instructionsView.hidden) = NO;
	}
}

- (void)hideInstructions
{
	NSView *instructionsView = (self.instructionsViewController.view);
	if ((instructionsView.superview)) {
		(instructionsView.hidden) = YES;
	}
}

- (void)showTable
{
	(self.tableView.enclosingScrollView.hidden) = NO;
}

- (void)hideTable
{
	(self.tableView.enclosingScrollView.hidden) = YES;
}

- (void)reloadHighlightedItems
{
	if (self.doNotUpdateViews) {
		return;
	}
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	NSArray *highlightedItems = [projectManager copyHighlightsForProject:(self.project)];
	
	if (!highlightedItems) {
		highlightedItems = @[];
	}
	(self.highlightedItems) = highlightedItems;
	
	[self stopCollectionObserving];
	[self startCollectionObserving];
	
	if ((highlightedItems.count) > 0) {
		[self showTable];
		[self hideInstructions];
		
		[(self.tableView) reloadData];
	}
	else {
		[self showInstructions];
		[self hideTable];
	}
}

- (void)projectHighlightsDidChangeNotification:(NSNotification *)note
{
	[self reloadHighlightedItems];
}

- (void)collectionDidChangeNotification:(NSNotification *)note
{
	[self reloadHighlightedItems];
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	(self.doNotUpdateViews) = NO;
	
	[self reloadHighlightedItems];
	[self startProjectObserving];
}

- (void)viewWillDisappear
{
	[super viewWillDisappear];
	
	(self.doNotUpdateViews) = YES;
	
	[self stopProjectObserving];
	[self stopCollectionObserving];
}

#pragma mark -

- (GLAHighlightedItem *)clickedHighlightedItem
{
	NSTableView *tableView = (self.tableView);
	NSInteger clickedRow = (tableView.clickedRow);
	if (clickedRow == -1) {
		return nil;
	}
	
	return (self.highlightedItems)[clickedRow];
}

- (GLACollectedFile *)collectedFileForHighlightedItem:(GLAHighlightedItem *)highlightedItem
{
	if (![highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
		return nil;
	}
	
	GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	GLACollectedFile *collectedFile = [pm collectedFileForHighlightedCollectedFile:highlightedCollectedFile loadIfNeeded:YES];
	
	return collectedFile;
}

- (NSURL *)fileURLForHighlightedItem:(GLAHighlightedItem *)highlightedItem
{
	GLACollectedFile *collectedFile = [self collectedFileForHighlightedItem:highlightedItem];
	if (!collectedFile) {
		return nil;
	}
	
	return (collectedFile.URL);
}

- (void)updateOpenerApplicationsUIMenu
{
	GLAFileOpenerApplicationCombiner *openerApplicationCombiner = (self.openerApplicationCombiner);
	
	GLAHighlightedItem *highlightedItem = (self.clickedHighlightedItem);
	if (![highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
		return;
	}
	GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
	
	
	NSURL *fileURL = [self fileURLForHighlightedItem:highlightedItem];
	(openerApplicationCombiner.fileURLs) = [NSSet setWithObject:fileURL];
	
	NSURL *preferredApplicationURL = nil;
	GLACollectedFile *collectedFileForPreferredApplication = (highlightedCollectedFile.applicationToOpenFile);
	if (collectedFileForPreferredApplication) {
		preferredApplicationURL = (collectedFileForPreferredApplication.URL);
	}

	NSMenu *openerApplicationMenu = (self.openerApplicationMenu);
	[openerApplicationCombiner updateOpenerApplicationsMenu:openerApplicationMenu target:self action:@selector(openWithChosenApplication:) preferredApplicationURL:preferredApplicationURL];
	
	
	NSMenu *preferredOpenerApplicationMenu = (self.preferredOpenerApplicationMenu);
	[openerApplicationCombiner updatePreferredOpenerApplicationsChoiceMenu:preferredOpenerApplicationMenu target:self action:@selector(changePreferredOpenerApplication:) chosenPreferredApplicationURL:preferredApplicationURL];
}

#pragma mark Actions

- (IBAction)removedClickedItem:(id)sender
{
	NSTableView *tableView = (self.tableView);
	NSInteger clickedRow = (tableView.clickedRow);
	if (clickedRow == -1) {
		return;
	}
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	[projectManager editHighlightsOfProject:(self.project) usingBlock:^(id<GLAArrayEditing> highlightsEditor) {
		[highlightsEditor removeChildrenAtIndexes:[NSIndexSet indexSetWithIndex:clickedRow]];
	}];
}

- (IBAction)openClickedItem:(id)sender
{
	GLAHighlightedItem *highlightedItem = (self.clickedHighlightedItem);
	if ((!highlightedItem) || ![highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
		return;
	}
	
	GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
	
	NSURL *fileURL = [self fileURLForHighlightedItem:highlightedCollectedFile];
	if (!fileURL) {
		return;
	}
		
	NSURL *applicationURL = nil;
	GLACollectedFile *applicationToOpenFileCollected = (highlightedCollectedFile.applicationToOpenFile);
	if (applicationToOpenFileCollected) {
		applicationURL = (applicationToOpenFileCollected.URL);
	}
	
	if (!applicationURL) {
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		applicationURL = [workspace URLForApplicationToOpenURL:fileURL];
	}
	
	[fileURL startAccessingSecurityScopedResource];
	
	[GLAFileOpenerApplicationCombiner openFileURLs:@[fileURL] withApplicationURL:applicationURL];
	
	[fileURL stopAccessingSecurityScopedResource];
}

- (IBAction)openWithChosenApplication:(NSMenuItem *)menuItem
{
	id representedObject = (menuItem.representedObject);
	if ((!representedObject) || ![representedObject isKindOfClass:[NSURL class]]) {
		return;
	}
	
	NSURL *applicationURL = representedObject;
	
	GLAHighlightedItem *highlightedItem = (self.clickedHighlightedItem);
	
	NSURL *fileURL = [self fileURLForHighlightedItem:highlightedItem];
	if (!fileURL) {
		return;
	}
	
	[fileURL startAccessingSecurityScopedResource];
	
	[GLAFileOpenerApplicationCombiner openFileURLs:@[fileURL] withApplicationURL:applicationURL];
	
	[fileURL stopAccessingSecurityScopedResource];
}

- (IBAction)changePreferredOpenerApplication:(NSMenuItem *)menuItem
{
	id representedObject = (menuItem.representedObject);
	if ((representedObject != nil) && ![representedObject isKindOfClass:[NSURL class]]) {
		return;
	}
	NSURL *applicationURL = representedObject;
	
	GLAHighlightedItem *highlightedItem = (self.clickedHighlightedItem);
	if (![highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
		return;
	}
	GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	[pm editHighlightedCollectedFile:highlightedCollectedFile usingBlock:^(id<GLAHighlightedCollectedFileEditing> editor) {
		if (applicationURL) {
			(editor.applicationToOpenFile) = [[GLACollectedFile alloc] initWithFileURL:applicationURL];
		}
		else {
			(editor.applicationToOpenFile) = nil;
		}
	}];
}

#pragma mark Notifications

- (void)openerApplicationCombinerDidChangeNotification:(NSNotification *)note
{
	[self updateOpenerApplicationsUIMenu];
}

#pragma mark - Table Dragging Helper Delegate

- (BOOL)arrayEditorTableDraggingHelper:(GLAArrayEditorTableDraggingHelper *)tableDraggingHelper canUseDraggingPasteboard:(NSPasteboard *)draggingPasteboard
{
	return [GLAHighlightedCollectedFile canCopyObjectsFromPasteboard:draggingPasteboard];
}

- (void)arrayEditorTableDraggingHelper:(GLAArrayEditorTableDraggingHelper *)tableDraggingHelper makeChangesUsingEditingBlock:(GLAArrayEditingBlock)editBlock
{
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	[projectManager editHighlightsOfProject:(self.project) usingBlock:editBlock];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (self.highlightedItems.count);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAHighlightedItem *highlightedItem = (self.highlightedItems)[row];
	return highlightedItem;
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
	GLAHighlightedItem *highlightedItem = (self.highlightedItems)[row];
	return highlightedItem;
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

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView
{
	return NO;
}

- (void)setUpTableCellView:(GLAHighlightsTableCellView *)cellView forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	(cellView.backgroundStyle) = NSBackgroundStyleDark;
	
	NSTextField *textField = (cellView.textField);
	
	(cellView.canDrawSubviewsIntoLayer) = YES;
	(cellView.alphaValue) = 1.0;
	
	GLAHighlightedItem *highlightedItem = (self.highlightedItems)[row];
	(cellView.objectValue) = highlightedItem;
	
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	NSString *name = @"Loading…";
	
	if ([highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
		GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
		
		GLACollection *holdingCollection = [pm collectionForHighlightedCollectedFile:highlightedCollectedFile loadIfNeeded:YES];
		GLACollectedFile *collectedFile = [pm collectedFileForHighlightedCollectedFile:highlightedCollectedFile loadIfNeeded:YES];
		if (collectedFile) {
			name = (collectedFile.name);
			
			if (collectedFile.isMissing) {
				(cellView.alphaValue) = 0.5;
			}
		}
		
		GLACollectionIndicationButton *collectionIndicationButton = (cellView.collectionIndicationButton);
		(collectionIndicationButton.collection) = holdingCollection;
	}
	else {
		NSAssert(NO, @"highlightedItem not a valid class.");
	}
	
	//name = [NSString stringWithFormat:@"%@ %@ %@", name, name, name];
	
	GLAUIStyle *activeStyle = [GLAUIStyle activeStyle];
	
	NSFont *titleFont = (activeStyle.smallReminderFont);
	
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	(paragraphStyle.alignment) = NSRightTextAlignment;
	(paragraphStyle.maximumLineHeight) = 18.0;
	
	NSColor *textColor = (activeStyle.lightTextColor);
	
	NSDictionary *titleAttributes =
	@{
	  NSFontAttributeName: titleFont,
	  NSParagraphStyleAttributeName: paragraphStyle,
	  NSForegroundColorAttributeName: textColor
	  };
	
	NSAttributedString *wholeAttrString = [[NSAttributedString alloc] initWithString:name attributes:titleAttributes];
	
	(textField.attributedStringValue) = wholeAttrString;
	
	//(textField.preferredMaxLayoutWidth) = (tableColumn.width);
}

#if 1
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	GLAHighlightsTableCellView *cellView = (self.measuringTableCellView);
	[self setUpTableCellView:cellView forTableColumn:nil row:row];
	
	NSTableColumn *tableColumn = (tableView.tableColumns)[0];
	CGFloat cellWidth = (tableColumn.width);
	(cellView.frameSize) = NSMakeSize(cellWidth, 100.0);
	[cellView layoutSubtreeIfNeeded];
	
	NSTextField *textField = (cellView.textField);
	//(textField.preferredMaxLayoutWidth) = (tableColumn.width);
	(textField.preferredMaxLayoutWidth) = NSWidth(textField.bounds);
#if 0
	NSLog(@"textField.intrinsicContentSize %@ %f %f", [textField valueForKey:@"intrinsicContentSize"], (textField.preferredMaxLayoutWidth), (tableColumn.width));
#endif
	
	CGFloat extraPadding = 13.0;
	
	return (textField.intrinsicContentSize.height) + extraPadding;
}
#endif

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	GLAHighlightsTableCellView *cellView = [tableView makeViewWithIdentifier:(tableColumn.identifier) owner:nil];
#if 1
	[self setUpTableCellView:cellView forTableColumn:tableColumn row:row];
#else
	(cellView.canDrawSubviewsIntoLayer) = YES;
	(cellView.alphaValue) = 1.0;
	
	GLAHighlightedItem *highlightedItem = (self.highlightedItems)[row];
	GLAProjectManager *pm = [GLAProjectManager sharedProjectManager];
	NSString *name = @"Loading…";
	
	if ([highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
		GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
		
		GLACollection *holdingCollection = [pm collectionForHighlightedCollectedFile:highlightedCollectedFile loadIfNeeded:YES];
		GLACollectedFile *collectedFile = [pm collectedFileForHighlightedCollectedFile:highlightedCollectedFile loadIfNeeded:YES];
		if (collectedFile) {
			name = (collectedFile.name);
			
			if (collectedFile.isMissing) {
				(cellView.alphaValue) = 0.5;
			}
		}
		
		GLACollectionIndicationButton *collectionIndicationButton = (cellView.collectionIndicationButton);
		(collectionIndicationButton.collection) = holdingCollection;
	}
	else {
		NSAssert(NO, @"highlightedItem not a valid class.");
	}
	
	name = [NSString stringWithFormat:@"%@ %@ %@", name, name, name];
	
	(cellView.objectValue) = highlightedItem;
	
	if (name) {
		(cellView.textField.stringValue) = name;
	}
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	(cellView.textField.textColor) = (uiStyle.lightTextColor);
	//(cellView.textField.textColor) = [uiStyle colorForCollectionColor:(collection.color)];
#endif
	
	return cellView;
}

#pragma mark Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if ((menu == (self.openerApplicationMenu)) || (menu == (self.preferredOpenerApplicationMenu))) {
		[self updateOpenerApplicationsUIMenu];
	}
}

@end
