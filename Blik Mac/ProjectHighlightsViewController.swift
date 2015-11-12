//
//  ProjectHighlightsViewController.swift
//  Blik
//
//  Created by Patrick Smith on 31/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntFoundation


private let collectionGroupHeight: CGFloat = 18.0

private func attributedStringForName(name: String) -> NSAttributedString {
	let activeStyle = GLAUIStyle.activeStyle()
	
	let titleFont = activeStyle.highlightItemFont
	
	let paragraphStyle = NSMutableParagraphStyle()
	paragraphStyle.alignment = NSRightTextAlignment
	paragraphStyle.maximumLineHeight = 18.0
	
	let textColor = activeStyle.lightTextColor
	
	let titleAttributes = [
		NSFontAttributeName: titleFont,
		NSParagraphStyleAttributeName: paragraphStyle,
		NSForegroundColorAttributeName: textColor
	];
	
	return NSAttributedString(string: name, attributes: titleAttributes)
}

private func attributedStringForMasterFoldersHeading() -> NSAttributedString {
	let activeStyle = GLAUIStyle.activeStyle()
	
	let titleFont = activeStyle.highlightGroupFont
	
	let paragraphStyle = NSMutableParagraphStyle()
	paragraphStyle.alignment = NSRightTextAlignment
	paragraphStyle.maximumLineHeight = collectionGroupHeight
	
	let textColor = activeStyle.primaryFoldersItemColor
	
	let titleAttributes = [
		NSFontAttributeName: titleFont,
		NSParagraphStyleAttributeName: paragraphStyle,
		NSForegroundColorAttributeName: textColor
	];
	
	let displayName = NSLocalizedString("Master Folders", comment: "Display name for Master Folders heading")
	
	return NSAttributedString(string: displayName.uppercaseString, attributes: titleAttributes)
}

private func attributedStringForCollectionGroup(collection: GLACollection) -> NSAttributedString {
	let activeStyle = GLAUIStyle.activeStyle()
	
	let titleFont = activeStyle.highlightGroupFont
	
	let paragraphStyle = NSMutableParagraphStyle()
	paragraphStyle.alignment = NSRightTextAlignment
	paragraphStyle.maximumLineHeight = collectionGroupHeight
	
	let textColor = activeStyle.colorForCollectionColor(collection.color)
	
	let titleAttributes = [
		NSFontAttributeName: titleFont,
		NSParagraphStyleAttributeName: paragraphStyle,
		NSForegroundColorAttributeName: textColor
	];
	
	return NSAttributedString(string: collection.name.uppercaseString, attributes: titleAttributes)
}


@objc(GLAProjectHighlightsViewController) public class ProjectHighlightsViewController: GLAViewController {
	@IBOutlet public var tableView: NSTableView!
	@IBOutlet public var scrollLeadingConstraint: NSLayoutConstraint!
	
	@IBOutlet public var openAllHighlightsButton: GLAButton!
	@IBOutlet public var instructionsViewController: GLAInstructionsViewController!
	
	var contextualMenu = NSMenu()
	
	var measuringHighlightTableCellView: GLAHighlightsTableCellView!
	var tableDraggingHelper: GLAArrayTableDraggingHelper?
	
	var assistant: ProjectHighlightsAssistant?
	var fileListHelper: GLACollectedFileListHelper!
	var collectedFileMenuCreator: GLACollectedFileMenuCreator!
	
	var itemWithDetailsBeingEdited: GLAHighlightedItem?
	
	func setUpFileHelpersIfNeeded() {
		guard fileListHelper == nil else { return }
		
		fileListHelper = GLACollectedFileListHelper(delegate: self)
	}
	
	var project: GLAProject? {
		didSet(oldProject) {
			setUpFileHelpersIfNeeded()
			fileListHelper.project = project
			
			if let project = project {
				self.assistant = nil
				
				let assistant = ProjectHighlightsAssistant(project: project, projectManager: GLAProjectManager.sharedProjectManager())
				assistant.reloadItems()
				assistant.changesNotifier = { [weak self] in
					self?.reloadViews()
				}
				
				tableDraggingHelper = GLAArrayTableDraggingHelper(delegate: assistant)
				
				self.assistant = assistant
			}
			
			reloadViews()
		}
	}
	
	var projectManager: GLAProjectManager {
		return GLAProjectManager.sharedProjectManager()
	}
	
	var doNotUpdateViews: Bool = false
	
	var tableScrollView: NSScrollView {
		return tableView.enclosingScrollView!
	}
	
	override public func prepareView() {
		super.prepareView()
		
		let uiStyle = GLAUIStyle.activeStyle()
		
		uiStyle.prepareContentTableView(tableView)
		
		/*let contextualMenu = NSMenu();
		contextualMenu.delegate = self
		self.contextualMenu = contextualMenu
		tableView.menu = contextualMenu*/
		
		tableView.registerForDraggedTypes([GLAHighlightedCollectedFile.objectJSONPasteboardType()])
		
		measuringHighlightTableCellView = tableView.makeViewWithIdentifier("highlightedItem", owner: nil) as! GLAHighlightsTableCellView
		
		prepareScrollView()
		
		tableView.setDataSource(self)
		tableView.setDelegate(self)
		
		let collectedFileMenuCreator = GLACollectedFileMenuCreator()
		collectedFileMenuCreator.context = .InHighlights
		collectedFileMenuCreator.target = self
		collectedFileMenuCreator.openInApplicationAction = "openWithChosenApplication:"
		collectedFileMenuCreator.changePreferredOpenerApplicationAction = "changePreferredOpenerApplication:"
		collectedFileMenuCreator.showInFinderAction = "showItemInFinder:"
		collectedFileMenuCreator.changeCustomNameHighlightsAction = "changeCustomNameOfClickedItem:"
		collectedFileMenuCreator.removeFromHighlightsAction = "removedClickedItem:"
		
		let nc = NSNotificationCenter.defaultCenter()
		
		nc.addObserverForName(GLACollectedFileMenuCreatorNeedsUpdateNotification, object: collectedFileMenuCreator, queue: nil) { _ in
			self.updateMenu(self.contextualMenu)
		}
		self.collectedFileMenuCreator = collectedFileMenuCreator
		
		contextualMenu.delegate = self
		tableView.menu = contextualMenu
		
		setUpFileHelpersIfNeeded()
	}
	
	func prepareScrollView() {
		// Wrap the highlights scroll view with a holder view
		// to allow constraints to be more easily worked with
		// and enable an actions view to be added underneath.

		let scrollView = self.tableScrollView
		scrollView.identifier = "tableScrollView"
		
		// I think Apple says this is better for scrolling performance.
		scrollView.wantsLayer = true

		fillViewWithChildView(scrollView)
	}
	
	func showInstructions() {
		let instructionsView = instructionsViewController.view
		if instructionsView.superview == nil {
			fillViewWithChildView(instructionsView)
		}
		else {
			instructionsView.hidden = false
		}
	}
	
	func hideInstructions() {
		let instructionsView = instructionsViewController.view
		if instructionsView.superview != nil {
			instructionsView.hidden = true
		}
	}
	
	func showTable() {
		tableScrollView.hidden = false
	}
	
	func hideTable() {
		tableScrollView.hidden = true
	}
	
	func reloadViews() {
		if let assistant = assistant where assistant.itemCount > 0 {
			showTable()
			hideInstructions()
			
			tableView.reloadData()
			
			openAllHighlightsButton.enabled = assistant.hasUngroupedItems
		}
		else {
			showInstructions()
			hideTable()
			
			openAllHighlightsButton.enabled = false
		}
	}
	
	override public func viewWillTransitionIn() {
		super.viewWillTransitionIn()
		
		doNotUpdateViews = false
		
		reloadViews()
	}
	
	override public func viewWillTransitionOut() {
		super.viewWillTransitionOut()
		
		doNotUpdateViews = true
		
		assistant?.stopObserving()
	}
}

extension ProjectHighlightsViewController {
	func collectedFileForHighlightedItem(highlightedItem: GLAHighlightedItem) -> GLACollectedFile? {
		guard let highlightedCollectedFile = highlightedItem as?GLAHighlightedCollectedFile else { return nil }
	
		return projectManager.collectedFileForHighlightedCollectedFile(highlightedCollectedFile, loadIfNeeded: true)
	}
}

extension ProjectHighlightsViewController: GLACollectedFileListHelperDelegate {
	public func collectedFileListHelperDidInvalidate(helper: GLACollectedFileListHelper) {
		reloadViews()
	}
}

extension ProjectHighlightsViewController {
	var clickedRow: Int? {
		let clickedRow = tableView.clickedRow
		guard clickedRow != -1 else { return nil }
		
		return clickedRow
	}
	
	var clickedItem: HighlightItemSource? {
		return clickedRow.flatMap({ assistant?[$0] })
	}
	
	var clickedItemDetails: HighlightItemDetails? {
		return clickedRow.flatMap({ assistant?.details[AnyRandomAccessIndex($0)] })
	}
	
	var clickedFileURL: NSURL? {
		return clickedRow.flatMap({ assistant?.fileURLAtIndex($0) })
	}
	
	func openClickedItemWithBehaviour(behaviour: OpeningBehaviour) {
		guard let source = clickedItem else { return }
		
		switch source {
		case let .Item(highlightedCollectedFile as GLAHighlightedCollectedFile, _):
			projectManager.openHighlightedCollectedFile(highlightedCollectedFile, behaviour: behaviour)
		case let .MasterFolder(collectedFolder):
			projectManager.openCollectedFile(collectedFolder, behaviour: behaviour)
		default:
			return
		}
	}
	
	@IBAction func openClickedItem(sender: AnyObject?) {
		openClickedItemWithBehaviour(OpeningBehaviour(modifierFlags: NSEvent.modifierFlags()))
	}
	
	@IBAction func openAllItems(sender: AnyObject?) {
		
	}
	
	@IBAction func openWithChosenApplication(menuItem: NSMenuItem) {
		guard let
			applicationURL = menuItem.representedObject as? NSURL,
			fileURL = clickedFileURL
			else { return }
		
		GLAFileOpenerApplicationFinder.openFileURLs([fileURL], withApplicationURL: applicationURL, useSecurityScope: true)
	}
	
	@IBAction func changePreferredOpenerApplication(menuItem: NSMenuItem) {
		guard let applicationURL = menuItem.representedObject as? NSURL? else { return }
	
		guard let
			source = clickedItem,
			case let HighlightItemSource.Item(highlightedCollectedFile as GLAHighlightedCollectedFile, _) = source
			else { return }
		
		projectManager.editHighlightedCollectedFile(highlightedCollectedFile) { editor in
			if let applicationURL = applicationURL {
				editor.applicationToOpenFile = GLACollectedFile(fileURL: applicationURL)
			}
			else {
				editor.applicationToOpenFile = nil;
			}
		}
	}
	
	@IBAction func showItemInFinder(menuItem: NSMenuItem) {
		openClickedItemWithBehaviour(.ShowInFinder)
	}
	
	@IBAction func changeCustomNameOfClickedItem(sender: AnyObject?) {
		guard let
			row = clickedRow,
			source = clickedItem,
			case let HighlightItemSource.Item(highlightedItem, _) = source
			else { return }
		
		chooseCustomNameForHighlightedItem(highlightedItem, atRow: row)
	}
	
	private func chooseCustomNameForHighlightedItem(highlightedItem: GLAHighlightedItem, atRow row: Int) {
		itemWithDetailsBeingEdited = highlightedItem;
		
		let popover = HighlightCustomNamePopover.sharedPopover
		
		if popover.shown {
			popover.close()
		}
		else {
			let observer = NotificationObserver<HighlightCustomNamePopover.Notification>(object: popover)
			
			observer.observe(.CustomNameDidChange) { [weak self] _ in
				self?.changeCustomName(popover.chosenCustomName, forHighlightedItem: highlightedItem)
			}
			
			let nc = NSNotificationCenter.defaultCenter()
			var closeObserver: AnyObject!
			closeObserver = nc.addObserverForName(NSPopoverDidCloseNotification, object: popover, queue: nil) { [weak self] _ in
				observer.stopObserving()
				self?.itemWithDetailsBeingEdited = nil
				
				nc.removeObserver(closeObserver)
			}
			
			popover.setUpWithHighlightedItem(highlightedItem)
			
			let rowRect = tableView.rectOfRow(row)
			// Show underneath.
			popover.showRelativeToRect(rowRect, ofView: tableView, preferredEdge: .MaxY)
		}
	}
	
	private func changeCustomName(var name: String, forHighlightedItem highlightedItem: GLAHighlightedItem) {
		guard let project = project else { return }
		
		name = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
		
		let projectManager = GLAProjectManager.sharedProjectManager()
		
		projectManager.editHighlightsOfProjectWithUUID(project.UUID) { highlightsEditor in
			highlightsEditor.replaceFirstChildWhoseKey("UUID", hasValue: highlightedItem.UUID) { originalItem in
				return originalItem.copyWithChangesFromEditing { editor in
					if name  == "" {
						editor.customName = nil
					}
					else {
						editor.customName = name
					}
				}
			}
		}
	}
	
	@IBAction func removedClickedItem(sender: AnyObject?) {
		guard let
			project = project,
			row = clickedRow
			else { return }
		
		projectManager.editHighlightsOfProject(project) { highlightsEditor in
			highlightsEditor.removeChildrenAtIndexes(NSIndexSet(index: row))
		}
	}
}

extension ProjectHighlightsViewController {
	public func updateMenu(menu: NSMenu) {
		guard let fileURL = clickedFileURL else { return }
		let highlightedCollectedFile: GLAHighlightedCollectedFile? = clickedItem.flatMap {
			switch $0 {
			case let .Item(highlightedItem, _):
				return highlightedItem as? GLAHighlightedCollectedFile
			default:
				return nil
			}
		}

		collectedFileMenuCreator.fileURL = fileURL;
		collectedFileMenuCreator.highlightedCollectedFile = highlightedCollectedFile
		collectedFileMenuCreator.updateMenu(menu)
	}
}

extension ProjectHighlightsViewController: NSTableViewDataSource {
	public func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		return assistant?.itemCount ?? 0
	}
	
	public func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
		return row
	}
}

extension ProjectHighlightsViewController: NSTableViewDelegate {
	public func selectionShouldChangeInTableView(tableView: NSTableView) -> Bool {
		return false
	}
	
	public func tableView(tableView: NSTableView, isGroupRow row: NSInteger) -> Bool {
		switch assistant![row] {
		case .GroupedCollectionHeading:
			return true
		default:
			return false
		}
	}
	
	public func tableView(tableView: NSTableView, heightOfRow row: NSInteger) -> CGFloat {
		var height: CGFloat = 0.0
		
		autoreleasepool {
			let cellView: NSTableCellView
			
			switch assistant!.details[AnyRandomAccessIndex(row)] {
			case let .Item(_, displayName, isFolder, _, collection):
				measuringHighlightTableCellView.removeFromSuperview()
				
				setUpTableCellView(measuringHighlightTableCellView, displayName: displayName, isFolder: isFolder, collection: collection)
				
				cellView = measuringHighlightTableCellView
			case .GroupedCollectionHeading(_), .MasterFoldersHeading:
				height = collectionGroupHeight
				return
			case let .MasterFolder(displayName, _):
				measuringHighlightTableCellView.removeFromSuperview()
				
				setUpTableCellView(measuringHighlightTableCellView, displayName: displayName, isFolder: true, collection: nil)
				
				cellView = measuringHighlightTableCellView
			}
			
			let tableColumn = tableView.tableColumns[0]
			let cellWidth = tableColumn.width
			cellView.setFrameSize(NSSize(width: cellWidth, height: 100.0))
			cellView.layoutSubtreeIfNeeded()
			
			let textField = cellView.textField!
			textField.preferredMaxLayoutWidth = textField.bounds.width
			
			let extraPadding: CGFloat = 13.0
			
			height = textField.intrinsicContentSize.height + extraPadding
		}
		
		return height
	}
	
	public func setUpTableCellView(cellView: GLAHighlightsTableCellView, displayName: String?, isFolder: Bool?, collection: GLACollection?) {
		cellView.backgroundStyle = .Dark
		cellView.alphaValue = 1.0
		
		cellView.textField!.attributedStringValue = attributedStringForName(displayName ?? "Loading…")
		
		let collectionIndicationButton = cellView.collectionIndicationButton
		collectionIndicationButton.collection = collection
		collectionIndicationButton.isFolder = isFolder ?? false
		
		cellView.needsLayout = true
	}
	
	public func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: NSInteger) -> NSView? {
		switch assistant!.details[AnyRandomAccessIndex(row)] {
		case let .Item(_, displayName, isFolder, _, collection):
			let cellView = tableView.makeViewWithIdentifier("highlightedItem", owner: nil) as! GLAHighlightsTableCellView
			
			setUpTableCellView(cellView, displayName: displayName, isFolder: isFolder, collection: collection)
			
			return cellView
		case let .GroupedCollectionHeading(collection):
			let cellView = tableView.makeViewWithIdentifier("collectionGroup", owner: nil) as! NSTableCellView
			
			cellView.textField!.attributedStringValue = attributedStringForCollectionGroup(collection)
			
			return cellView
		case .MasterFoldersHeading:
			let cellView = tableView.makeViewWithIdentifier("collectionGroup", owner: nil) as! NSTableCellView
			
			cellView.textField!.attributedStringValue = attributedStringForMasterFoldersHeading()
			
			return cellView
		case let .MasterFolder(displayName, _):
			let cellView = tableView.makeViewWithIdentifier("highlightedItem", owner: nil) as! GLAHighlightsTableCellView
			
			setUpTableCellView(cellView, displayName: displayName, isFolder: true, collection: nil)
			
			return cellView
		}
	}
	
	public func tableView(tableView: NSTableView, pasteboardWriterForRow row:Int) -> NSPasteboardWriting? {
		guard let assistant = assistant else { return nil }
		
		switch assistant[row] {
		case let .Item(highlightedItem, isGrouped: false):
			return highlightedItem
		default:
			return nil
		}
	}
	
	public func tableView(tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint, forRowIndexes rowIndexes: NSIndexSet) {
		tableDraggingHelper?.tableView(tableView, draggingSession: session, willBeginAtPoint: screenPoint, forRowIndexes: rowIndexes)
	}
	
	public func tableView(tableView: NSTableView, draggingSession session: NSDraggingSession, endedAtPoint screenPoint: NSPoint, operation: NSDragOperation) {
		tableDraggingHelper?.tableView(tableView, draggingSession: session, endedAtPoint: screenPoint, operation: operation)
	}
	
	public func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: NSInteger, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
		guard let
			assistant = assistant,
			tableDraggingHelper = tableDraggingHelper
			else { return .None }
		
		switch assistant[row] {
		case .Item(_, isGrouped: false):
			// FIXME:
			// <= Less than or equal to allow dragging to bottom of highlighted items.
			return tableDraggingHelper.tableView(tableView, validateDrop: info, proposedRow: row, proposedDropOperation: dropOperation)
		default:
			break
		}
		
		guard row > 0 else { return .None }
		
		switch assistant[row - 1] {
		case .Item(_, isGrouped: false):
			return tableDraggingHelper.tableView(tableView, validateDrop: info, proposedRow: row, proposedDropOperation: dropOperation)
		default:
			return .None
		}
	}
	
	public func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: NSInteger, dropOperation: NSTableViewDropOperation) -> Bool {
	return tableDraggingHelper!.tableView(tableView, acceptDrop: info, row: row, dropOperation: dropOperation)
	}
}

extension ProjectHighlightsViewController: NSMenuDelegate {
	public func menuNeedsUpdate(menu: NSMenu) {
		updateMenu(menu)
	}
}
