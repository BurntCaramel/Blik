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

private func attributedStringForName(_ name: String, textAlignment: NSTextAlignment = NSRightTextAlignment) -> NSAttributedString {
	let activeStyle = GLAUIStyle.active()
	
	let titleFont = activeStyle.highlightItemFont
	
	let paragraphStyle = NSMutableParagraphStyle()
	paragraphStyle.alignment = textAlignment
	paragraphStyle.maximumLineHeight = 18.0
	
	let textColor = activeStyle.lightTextColor
	
	let titleAttributes = [
		NSFontAttributeName: titleFont,
		NSParagraphStyleAttributeName: paragraphStyle,
		NSForegroundColorAttributeName: textColor
	] as [String : Any]
	
	return NSAttributedString(string: name, attributes: titleAttributes)
}

private func attributedStringForMasterFoldersHeading(textAlignment: NSTextAlignment = NSRightTextAlignment) -> NSAttributedString {
	let activeStyle = GLAUIStyle.active()
	
	let titleFont = activeStyle.highlightGroupFont
	
	let paragraphStyle = NSMutableParagraphStyle()
	paragraphStyle.alignment = textAlignment
	paragraphStyle.maximumLineHeight = collectionGroupHeight
	
	let textColor = activeStyle.primaryFoldersItemColor
	
	let titleAttributes = [
		NSFontAttributeName: titleFont,
		NSParagraphStyleAttributeName: paragraphStyle,
		NSForegroundColorAttributeName: textColor
	] as [String : Any];
	
	let displayName = NSLocalizedString("Master Folders", comment: "Display name for Master Folders heading")
	
	return NSAttributedString(string: displayName.uppercased(), attributes: titleAttributes)
}

private func attributedStringForCollectionGroup(_ collection: GLACollection, textAlignment: NSTextAlignment = NSRightTextAlignment) -> NSAttributedString {
	let activeStyle = GLAUIStyle.active()
	
	let titleFont = activeStyle.highlightGroupFont
	
	let paragraphStyle = NSMutableParagraphStyle()
	paragraphStyle.alignment = textAlignment
	paragraphStyle.maximumLineHeight = collectionGroupHeight
	
	let textColor = activeStyle.color(for: collection.color)
	
	let titleAttributes = [
		NSFontAttributeName: titleFont,
		NSParagraphStyleAttributeName: paragraphStyle,
		NSForegroundColorAttributeName: textColor
	] as [String : Any];
	
	return NSAttributedString(string: collection.name.uppercased(), attributes: titleAttributes)
}


@objc(GLAProjectHighlightsViewController) open class ProjectHighlightsViewController: GLAViewController {
	@IBOutlet open var tableView: NSTableView!
	//@IBOutlet public var scrollLeadingConstraint: NSLayoutConstraint!
	
	@IBOutlet open var openAllHighlightsButton: GLAButton?
	@IBOutlet open var instructionsViewController: GLAInstructionsViewController?
	
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
				
				let assistant = ProjectHighlightsAssistant(project: project, projectManager: GLAProjectManager.shared(), navigator: GLAMainSectionNavigator.shared())
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
		return GLAProjectManager.shared()
	}
	
	var doNotUpdateViews: Bool = false
	
	var tableScrollView: NSScrollView {
		return tableView.enclosingScrollView!
	}
	
	override open func prepareView() {
		super.prepareView()
		
		let uiStyle = GLAUIStyle.active()
		
		uiStyle.prepareContentTableView(tableView)
		
		/*let contextualMenu = NSMenu();
		contextualMenu.delegate = self
		self.contextualMenu = contextualMenu
		tableView.menu = contextualMenu*/
		
		tableView.register(forDraggedTypes: [GLAHighlightedCollectedFile.objectJSONPasteboardType()])
		
		measuringHighlightTableCellView = tableView.make(withIdentifier: "highlightedItem", owner: nil) as! GLAHighlightsTableCellView
		
		prepareScrollView()
		
		tableView.dataSource = self
		tableView.delegate = self
		
		tableView.target = self
		tableView.action = #selector(ProjectHighlightsViewController.openClickedItem(_:))
		
		let collectedFileMenuCreator = GLACollectedFileMenuCreator()
		collectedFileMenuCreator.context = .inHighlights
		collectedFileMenuCreator.target = self
		collectedFileMenuCreator.openInApplicationAction = #selector(ProjectHighlightsViewController.openWithChosenApplication(_:))
		collectedFileMenuCreator.changePreferredOpenerApplicationAction = #selector(ProjectHighlightsViewController.changePreferredOpenerApplication(_:))
		collectedFileMenuCreator.showInFinderAction = #selector(ProjectHighlightsViewController.showItemInFinder(_:))
		collectedFileMenuCreator.changeCustomNameHighlightsAction = #selector(ProjectHighlightsViewController.changeCustomNameOfClickedItem(_:))
		collectedFileMenuCreator.removeFromHighlightsAction = #selector(ProjectHighlightsViewController.removedClickedItem(_:))
		
		let nc = NotificationCenter.default
		
		nc.addObserver(forName: NSNotification.Name.GLACollectedFileMenuCreatorNeedsUpdate, object: collectedFileMenuCreator, queue: nil) { _ in
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

		fillView(withChildView: scrollView)
	}
	
	func showInstructions() {
		guard let instructionsViewController = instructionsViewController else { return }
		
		let instructionsView = instructionsViewController.view
		if instructionsView.superview == nil {
			fillView(withChildView: instructionsView)
		}
		else {
			instructionsView.isHidden = false
		}
	}
	
	func hideInstructions() {
		guard let instructionsViewController = instructionsViewController else { return }
		
		let instructionsView = instructionsViewController.view
		if instructionsView.superview != nil {
			instructionsView.isHidden = true
		}
	}
	
	func showTable() {
		tableScrollView.isHidden = false
	}
	
	func hideTable() {
		tableScrollView.isHidden = true
	}
	
	func reloadViews() {
		// Always reload table so it knows how many items there are, even if it gets hidden.
		// Resolves an out-of-bounds exception.
		tableView.reloadData()
		
		if let assistant = assistant , assistant.itemCount > 0 {
			showTable()
			hideInstructions()
			
			openAllHighlightsButton?.isEnabled = assistant.canOpenAllHighlights
		}
		else {
			showInstructions()
			hideTable()
			
			openAllHighlightsButton?.isEnabled = false
		}
	}
	
	override open func viewWillTransitionIn() {
		super.viewWillTransitionIn()
		
		doNotUpdateViews = false
		
		reloadViews()
	}
	
	override open func viewWillTransitionOut() {
		super.viewWillTransitionOut()
		
		doNotUpdateViews = true
		
		assistant?.stopObserving()
	}
}

extension ProjectHighlightsViewController {
	func collectedFileForHighlightedItem(_ highlightedItem: GLAHighlightedItem) -> GLACollectedFile? {
		guard let highlightedCollectedFile = highlightedItem as?GLAHighlightedCollectedFile else { return nil }
	
		return projectManager.collectedFile(for: highlightedCollectedFile, loadIfNeeded: true)
	}
}

extension ProjectHighlightsViewController: GLACollectedFileListHelperDelegate {
	public func collectedFileListHelperDidInvalidate(_ helper: GLACollectedFileListHelper) {
		reloadViews()
	}
}

func convertRowToOptional(_ row: Int) -> Int? {
	switch row {
	case -1:
		return nil
	default:
		return row
	}
}

extension ProjectHighlightsViewController {
	var clickedRow: Int? {
		return convertRowToOptional(tableView.clickedRow)
	}
	
	var clickedIndex: Int? {
		return clickedRow.flatMap { row in
			return assistant?.outputIndexesForTableRows(IndexSet(integer: row)).first
		}
	}
	
	var clickedItem: HighlightItemSource? {
		return clickedRow.flatMap({ assistant?[$0] })
	}
	
	var clickedItemDetails: HighlightItemDetails? {
		return clickedRow.flatMap({ assistant?.details[AnyIndex($0)] })
	}
	
	var clickedFileURL: URL? {
		return clickedRow.flatMap({ assistant?.fileURLAtIndex($0) })
	}
	
	func clickedRow(forSender sender: AnyObject?) -> Int? {
		return clickedRow ?? (sender as? NSView).flatMap{ convertRowToOptional(tableView.row(for: $0)) }
	}
	
	func openClickedItemWithBehaviour(_ behaviour: OpeningBehaviour, sender: AnyObject? = nil) {
		guard let
			clickedRow = clickedRow(forSender: sender),
			let assistant = self.assistant
			else { return }
		
		assistant.openItem(atIndex: clickedRow, withBehaviour: behaviour, activateIfNeeded: true)
	}
	
	@IBAction public func openClickedItem(_ sender: AnyObject?) {
		if let menu = (sender as? NSView)?.enclosingMenuItem?.menu {
			// Close launcher menu
			menu.cancelTracking()
		}

		openClickedItemWithBehaviour(OpeningBehaviour(modifierFlags: NSEvent.modifierFlags()), sender: sender)
	}
	
	@IBAction public func openAllItems(_ sender: AnyObject?) {
		assistant?.openAllHighlights()
	}
	
	@IBAction public func openWithChosenApplication(_ menuItem: NSMenuItem) {
		guard let
			applicationURL = menuItem.representedObject as? URL,
			let fileURL = clickedFileURL
			else { return }
		
		GLAFileOpenerApplicationFinder.openFileURLs([fileURL], withApplicationURL: applicationURL, useSecurityScope: true)
	}
	
	@IBAction public func changePreferredOpenerApplication(_ menuItem: NSMenuItem) {
		guard let applicationURL = menuItem.representedObject as? URL? else { return }
	
		guard let
			source = clickedItem,
			case let HighlightItemSource.item(highlightedCollectedFile as GLAHighlightedCollectedFile, _) = source
			else { return }
		
		projectManager.edit(highlightedCollectedFile) { editor in
			if let applicationURL = applicationURL {
				editor.applicationToOpenFile = GLACollectedFile(fileURL: applicationURL)
			}
			else {
				editor.applicationToOpenFile = nil;
			}
		}
	}
	
	@IBAction func showItemInFinder(_ menuItem: NSMenuItem) {
		openClickedItemWithBehaviour(.showInFinder)
	}
	
	@IBAction func changeCustomNameOfClickedItem(_ sender: AnyObject?) {
		guard let
			row = clickedRow,
			let source = clickedItem,
			case let HighlightItemSource.item(highlightedItem, _) = source
			else { return }
		
		chooseCustomNameForHighlightedItem(highlightedItem, atRow: row)
	}
	
	fileprivate func chooseCustomNameForHighlightedItem(_ highlightedItem: GLAHighlightedItem, atRow row: Int) {
		itemWithDetailsBeingEdited = highlightedItem;
		
		let popover = HighlightCustomNamePopover.sharedPopover
		
		if popover.isShown {
			popover.close()
		}
		else {
			let observer = NotificationObserver<HighlightCustomNamePopover.Notification>(object: popover)
			
			observer.observe(.CustomNameDidChange) { [weak self] _ in
				self?.changeCustomName(popover.chosenCustomName, forHighlightedItem: highlightedItem)
			}
			
			let nc = NotificationCenter.default
			var closeObserver: AnyObject!
			closeObserver = nc.addObserver(forName: NSNotification.Name.NSPopoverDidClose, object: popover, queue: nil) { [weak self] _ in
				observer.stopObserving()
				self?.itemWithDetailsBeingEdited = nil
				
				nc.removeObserver(closeObserver)
			}
			
			popover.setUpWithHighlightedItem(highlightedItem)
			
			let rowRect = tableView.rect(ofRow: row)
			// Show underneath.
			popover.show(relativeTo: rowRect, of: tableView, preferredEdge: .maxY)
		}
	}
	
	fileprivate func changeCustomName(_ name: String, forHighlightedItem highlightedItem: GLAHighlightedItem) {
		guard let project = project else { return }
		
		let name = name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		
		let projectManager = GLAProjectManager.shared()
		
		projectManager.editHighlightsOfProject(with: project.uuid) { highlightsEditor in
			highlightsEditor.replaceFirstChildWhoseKey("UUID", hasValue: highlightedItem.uuid) { originalItem in
				return (originalItem as! GLAHighlightedItem).copyWithChanges { editor in
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
	
	@IBAction func removedClickedItem(_ sender: AnyObject?) {
		guard
			let project = project,
			let uuid = clickedItem?.UUID
			else { return }
		
		projectManager.editHighlights(of: project) { highlightsEditor in
			let index = highlightsEditor.index(ofFirstChildWhoseKey: "UUID", hasValue: uuid)
			highlightsEditor.removeChildren(at: IndexSet(integer: Int(index)))
		}
	}
}

extension ProjectHighlightsViewController {
	public func updateMenu(_ menu: NSMenu) {
		guard let fileURL = clickedFileURL else {
			menu.removeAllItems()
			return
		}
		let highlightedCollectedFile: GLAHighlightedCollectedFile? = clickedItem.flatMap {
			switch $0 {
			case let .item(highlightedItem as GLAHighlightedCollectedFile, _): return highlightedItem
			default: return nil
			}
		}

		collectedFileMenuCreator.fileURL = fileURL;
		collectedFileMenuCreator.highlightedCollectedFile = highlightedCollectedFile
		collectedFileMenuCreator.update(menu)
	}
}

extension ProjectHighlightsViewController: NSTableViewDataSource {
	public func numberOfRows(in tableView: NSTableView) -> Int {
		return assistant?.itemCount ?? 0
	}
	
	public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		return row
	}
}

extension ProjectHighlightsViewController: NSTableViewDelegate {
	public func selectionShouldChange(in tableView: NSTableView) -> Bool {
		return false
	}
	
	public func tableView(_ tableView: NSTableView, isGroupRow row: NSInteger) -> Bool {
		switch assistant![row] {
		case .groupedCollectionHeading:
			return true
		default:
			return false
		}
	}
	
	public func tableView(_ tableView: NSTableView, heightOfRow row: NSInteger) -> CGFloat {
		var height: CGFloat = 0.0
		
		autoreleasepool {
			let cellView: NSTableCellView
			
			let inMenuItem = tableView.enclosingMenuItem != nil
			let textAlignment = inMenuItem ? NSLeftTextAlignment : NSRightTextAlignment
			
			switch assistant!.details[AnyIndex(row)] {
			case let .item(_, displayName, isFolder, _, collection):
				measuringHighlightTableCellView.removeFromSuperview()
				
				setUpTableCellView(measuringHighlightTableCellView, textAlignment: textAlignment, displayName: displayName, isFolder: isFolder, collection: collection)
				
				cellView = measuringHighlightTableCellView
			case .groupedCollectionHeading(_), .masterFoldersHeading:
				height = collectionGroupHeight
				return
			case let .masterFolder(displayName, _):
				measuringHighlightTableCellView.removeFromSuperview()
				
				setUpTableCellView(measuringHighlightTableCellView, textAlignment: textAlignment, displayName: displayName, isFolder: true, collection: nil)
				
				cellView = measuringHighlightTableCellView
			}
			
			let tableColumn = tableView.tableColumns[0]
			let cellWidth = tableColumn.width
			cellView.setFrameSize(NSSize(width: cellWidth, height: 100.0))
			cellView.layoutSubtreeIfNeeded()
			
			let textField = cellView.textField!
			textField.preferredMaxLayoutWidth = textField.bounds.width
			
			//let extraPadding: CGFloat = 13.0
			let extraPadding: CGFloat = inMenuItem ? 6.0 : 10.0
			
			height = textField.intrinsicContentSize.height + extraPadding
		}
		
		return height
	}
	
	public func setUpTableCellView(_ cellView: GLAHighlightsTableCellView, textAlignment: NSTextAlignment, displayName: String?, isFolder: Bool?, collection: GLACollection?) {
		cellView.backgroundStyle = .dark
		cellView.alphaValue = 1.0
		
		cellView.textField!.attributedStringValue = attributedStringForName(displayName ?? "Loading…", textAlignment: textAlignment)
		
		let collectionIndicationButton = cellView.collectionIndicationButton
		collectionIndicationButton?.collection = collection
		collectionIndicationButton?.isFolder = isFolder ?? false
		
		cellView.needsLayout = true
	}
	
	public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: NSInteger) -> NSView? {
		let inMenuItem = tableView.enclosingMenuItem != nil
		let textAlignment = inMenuItem ? NSLeftTextAlignment : NSRightTextAlignment
		
		switch assistant!.details[AnyIndex(row)] {
		case let .item(_, displayName, isFolder, _, collection):
			let cellView = tableView.make(withIdentifier: "highlightedItem", owner: nil) as! GLAHighlightsTableCellView
			
			setUpTableCellView(cellView, textAlignment: textAlignment, displayName: displayName, isFolder: isFolder, collection: collection)
			
			return cellView
		case let .groupedCollectionHeading(collection):
			let cellView = tableView.make(withIdentifier: "collectionGroup", owner: nil) as! NSTableCellView
			
			cellView.textField!.attributedStringValue = attributedStringForCollectionGroup(collection, textAlignment: textAlignment)
			
			return cellView
		case .masterFoldersHeading:
			let cellView = tableView.make(withIdentifier: "collectionGroup", owner: nil) as! NSTableCellView
			
			cellView.textField!.attributedStringValue = attributedStringForMasterFoldersHeading(textAlignment: textAlignment)
			
			return cellView
		case let .masterFolder(displayName, _):
			let cellView = tableView.make(withIdentifier: "highlightedItem", owner: nil) as! GLAHighlightsTableCellView
			
			setUpTableCellView(cellView, textAlignment: textAlignment, displayName: displayName, isFolder: true, collection: nil)
			
			return cellView
		}
	}
	
	public func tableView(_ tableView: NSTableView, pasteboardWriterForRow row:Int) -> NSPasteboardWriting? {
		guard let assistant = assistant else { return nil }
		
		switch assistant[row] {
		case let .item(highlightedItem, isGrouped: false):
			return highlightedItem
		default:
			return nil
		}
	}
	
	@objc(tableView:draggingSession:willBeginAtPoint:forRowIndexes:) public func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {
		tableDraggingHelper?.tableView(tableView, draggingSession: session, willBeginAt: screenPoint, forRowIndexes: rowIndexes)
	}
	
	@objc(tableView:draggingSession:endedAtPoint:operation:) public func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
		tableDraggingHelper?.tableView(tableView, draggingSession: session, endedAt: screenPoint, operation: operation)
	}
	
	public func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: NSInteger, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
		guard let
			assistant = assistant,
			let tableDraggingHelper = tableDraggingHelper
			else { return NSDragOperation() }
		
		if row < assistant.count {
			switch assistant[row] {
			case .item(_, isGrouped: false):
				// FIXME:
				// <= Less than or equal to allow dragging to bottom of highlighted items.
				return tableDraggingHelper.tableView(tableView, validateDrop: info, proposedRow: row, proposedDropOperation: dropOperation)
			default:
				break
			}
		}
		
		guard row > 0 else { return NSDragOperation() }
		
		switch assistant[row - 1] {
		case .item(_, isGrouped: false):
			return tableDraggingHelper.tableView(tableView, validateDrop: info, proposedRow: row, proposedDropOperation: dropOperation)
		default:
			return NSDragOperation()
		}
	}
	
	public func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: NSInteger, dropOperation: NSTableViewDropOperation) -> Bool {
	return tableDraggingHelper!.tableView(tableView, acceptDrop: info, row: row, dropOperation: dropOperation)
	}
}

extension ProjectHighlightsViewController: NSMenuDelegate {
	public func menuNeedsUpdate(_ menu: NSMenu) {
		updateMenu(menu)
	}
}
