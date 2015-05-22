//
//  GLACollectedFolderContentsViewController.swift
//  Blik
//
//  Created by Patrick Smith on 16/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntCocoaUI


@objc public class GLACollectedFolderContentsViewController: GLAViewController {
	
	var resourceKeyToSortBy = NSURLLocalizedNameKey
	var sortsAscending = true
	var hidesInvisibles = true
	
	@IBOutlet var folderContentOutlineView: NSOutlineView!
	
	public var assistant: GLAFolderContentsAssisting?
	
	var fileInfoRetriever: GLAFileInfoRetriever!
	var directoryURLToArrangedChildren = [NSURL: GLAArrangedDirectoryChildren]()
	
	var dateFormatter: NSDateFormatter = {
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateStyle = .MediumStyle
		dateFormatter.timeStyle = .ShortStyle
		dateFormatter.doesRelativeDateFormatting = true
		return dateFormatter
	}()
	
	var quickLookPreviewHelper: GLAQuickLookPreviewHelper!
	
	private enum MenuChoice: Int, UIChoiceRepresentative {
		case AddToCollection = 1
		case RemoveFromCollection
		case ShowInFinder
		
		var title: String {
			switch self {
			case AddToCollection:
				return "Add to Collection"
			case RemoveFromCollection:
				return "Remove from Collection"
			case ShowInFinder:
				return "Show in Finder…"
			}
		}
		
		typealias UniqueIdentifier = MenuChoice
		var uniqueIdentifier: UniqueIdentifier { return self }
	}
	private var contextualMenuAssistant: MenuAssistant<MenuChoice>!
	
	
	override public class func defaultNibName() -> String {
		return "GLACollectedFolderContentsViewController"
	}
	
	override public func prepareView() {
		insertIntoResponderChain()
		
		let defaultResourceKeys = [
			NSURLIsDirectoryKey,
			NSURLIsPackageKey,
			NSURLIsRegularFileKey,
			NSURLIsSymbolicLinkKey,
			NSURLLocalizedNameKey,
			NSURLEffectiveIconKey,
			NSURLIsHiddenKey,
			NSURLContentModificationDateKey
		]
		fileInfoRetriever = GLAFileInfoRetriever(delegate:self, defaultResourceKeysToRequest:defaultResourceKeys)
		
		let style = GLAUIStyle.activeStyle()
		
		let folderContentOutlineView = self.folderContentOutlineView
		
		let nameSortDescriptor = NSSortDescriptor(key:NSURLLocalizedNameKey, ascending:true)
		let dateModifiedSortDescriptor = NSSortDescriptor(key:NSURLContentModificationDateKey, ascending:false)
		
		let displayNameTableColumn = folderContentOutlineView.tableColumnWithIdentifier("displayNameAndIcon")!
		displayNameTableColumn.sortDescriptorPrototype = nameSortDescriptor
		
		let dateModifiedTableColumn = folderContentOutlineView.tableColumnWithIdentifier("dateModified")!
		dateModifiedTableColumn.sortDescriptorPrototype = dateModifiedSortDescriptor
		
		style.prepareContentTableColumn(displayNameTableColumn)
		style.prepareContentTableColumn(dateModifiedTableColumn)
		
		folderContentOutlineView.sortDescriptors = [nameSortDescriptor]
		
		// Individually autosaves each folder by URL.
		folderContentOutlineView.autosaveTableColumns = true
		//(folderContentOutlineView.autosaveExpandedItems) = YES;
		
		updateSortingFromOutlineView()
		
		folderContentOutlineView.setDataSource(self)
		folderContentOutlineView.setDelegate(self)
		style.prepareContentTableView(folderContentOutlineView)
		
		reloadContentsOfFolder()
		
		quickLookPreviewHelper = GLAQuickLookPreviewHelper()
		quickLookPreviewHelper.delegate = self;
		quickLookPreviewHelper.sourceTableView = folderContentOutlineView
		
		let contextualMenu = NSMenu()
		contextualMenu.delegate = self
		contextualMenuAssistant = MenuAssistant<MenuChoice>(menu: contextualMenu)
		updateContextualMenu(initial: true)
	}
	
	var collectedFolder: GLACollectedFile!
	var sourceDirectoryURL: NSURL! {
		didSet {
			// Make sure view has loaded
			let view = self.view
			
			if let sourceDirectoryURL = sourceDirectoryURL {
				folderContentOutlineView.autosaveName = "collectedFolderContentsOutlineView-\(sourceDirectoryURL.path)"
			}
			
			reloadContentsOfFolder()
		}
	}
	
	func reloadContentsOfFolder() {
		folderContentOutlineView.reloadData()
	}
	
	func updateSortingFromOutlineView() {
		let sortDescriptors = folderContentOutlineView.sortDescriptors
		if sortDescriptors.count > 0 {
			let firstSortDescriptor = sortDescriptors[0] as! NSSortDescriptor
			
			let sortingKey = firstSortDescriptor.key()!
			resourceKeyToSortBy = sortingKey
			sortsAscending = firstSortDescriptor.ascending
			
			updateAllArrangedChildrenWithSortingOptions()
		}
	}
	
	func arrangedChildrenForDirectoryURL(directoryURL: NSURL) -> [NSURL]? {
		let arrangedChildren = directoryURLToArrangedChildren[directoryURL] ?? {
			let arrangedChildren = GLAArrangedDirectoryChildren(directoryURL:directoryURL, delegate:self, fileInfoRetriever:self.fileInfoRetriever)
			self.directoryURLToArrangedChildren[directoryURL] = arrangedChildren
			
			self.updateArrangedChildrenWithSortingOptions(arrangedChildren)
			
			return arrangedChildren
		}()
		
		return arrangedChildren.arrangedChildren as! [NSURL]?
	}
	
	func updateArrangedChildrenWithSortingOptions(arrangedChildren: GLAArrangedDirectoryChildren)
	{
		arrangedChildren.updateAfterEditingOptions { editor in
			editor.resourceKeyToSortBy = self.resourceKeyToSortBy
			editor.sortsAscending = self.sortsAscending
			editor.hidesInvisibles = self.hidesInvisibles
		}
	}
	
	func updateAllArrangedChildrenWithSortingOptions() {
		for (directoryURL, arrangedChildren) in directoryURLToArrangedChildren {
			updateArrangedChildrenWithSortingOptions(arrangedChildren)
		}
	}
	
	public var selectedURLs: [NSURL] {
		let folderContentOutlineView = self.folderContentOutlineView
		
		let selectedRowIndexes = folderContentOutlineView.selectedRowIndexes
		var selectedURLs = [NSURL]()
		selectedRowIndexes.enumerateIndexesUsingBlock { rowIndex, stop in
			let fileURL = folderContentOutlineView.itemAtRow(rowIndex) as! NSURL
			selectedURLs.append(fileURL)
		}
	
		return selectedURLs
	}
	
	public var hasFirstResponder: Bool {
		let folderContentOutlineView = self.folderContentOutlineView
		
		if let firstResponder = folderContentOutlineView.window?.firstResponder as? NSView {
			return firstResponder.isDescendantOf(folderContentOutlineView)
		}
		
		return false
	}
	
	override public func keyDown(theEvent: NSEvent) {
		if theEvent.burnt_isSpaceKey {
			quickLookPreviewItems(self)
		}
	}
}

extension GLACollectedFolderContentsViewController {
	var fileURLsForContextualMenu: [NSURL]? {
		let row = folderContentOutlineView.clickedRow
		if row == -1 {
			return nil
		}
		
		if folderContentOutlineView.isRowSelected(row) {
			return selectedURLs
		}
		else if let fileURL = folderContentOutlineView.itemAtRow(row) as? NSURL {
			return [fileURL]
		}
		
		return nil
	}
	
	func updateContextualMenu(initial: Bool = false) {
		if initial {
			contextualMenuAssistant.customization.actionAndTarget = { [unowned self] choice in
				switch choice {
				case .AddToCollection:
					return (action: "addSelectedFileToCollection:", target: self)
				case .RemoveFromCollection:
					return (action: "removeSelectedFileFromCollection:", target: self)
				case .ShowInFinder:
					return (action: "showSelectedFileInFinder:", target: self)
				}
			}
		}
		
		var showAdd = true
		
		if let assistant = assistant, fileURLsForContextualMenu = fileURLsForContextualMenu {
			if assistant.fileURLsAreAllCollected(fileURLsForContextualMenu) {
				showAdd = false
			}
		}
		
		contextualMenuAssistant.menuItemRepresentatives = [
			showAdd ? .AddToCollection : .RemoveFromCollection,
			nil,
			.ShowInFinder
		]
		contextualMenuAssistant.update()
	}
	
	@IBAction func addSelectedFileToCollection(sender: AnyObject?) {
		if let fileURLsForContextualMenu = fileURLsForContextualMenu {
			assistant?.addFileURLsToCollection(fileURLsForContextualMenu)
		}
	}
	
	@IBAction func removeSelectedFileFromCollection(sender: AnyObject?) {
		if let fileURLsForContextualMenu = fileURLsForContextualMenu {
			assistant?.removeFileURLsFromCollection(fileURLsForContextualMenu)
		}
	}
	
	@IBAction func showSelectedFileInFinder(sender: AnyObject?) {
		if let fileURLsForContextualMenu = fileURLsForContextualMenu {
			NSWorkspace.sharedWorkspace().activateFileViewerSelectingURLs(fileURLsForContextualMenu)
		}
	}
}

extension GLACollectedFolderContentsViewController: GLAArrangedDirectoryChildrenDelegate {
	public func arrangedDirectoryChildrenDidUpdateChildren(arrangedDirectoryChildren: GLAArrangedDirectoryChildren) {
		let directoryURL = arrangedDirectoryChildren.directoryURL
		
		if directoryURL == sourceDirectoryURL {
			folderContentOutlineView.reloadData()
		}
		else {
			folderContentOutlineView.reloadItem(directoryURL, reloadChildren: true)
		}
	}
}

extension GLACollectedFolderContentsViewController: GLAFileInfoRetrieverDelegate {
	public func fileInfoRetriever(fileInfoRetriever: GLAFileInfoRetriever!, didRetrieveContentsOfDirectoryURL URL: NSURL!) {
		
	}
	
	public func fileInfoRetriever(fileInfoRetriever: GLAFileInfoRetriever!, didFailWithError error: NSError!, retrievingContentsOfDirectoryURL directoryURL: NSURL!) {
		if directoryURL == sourceDirectoryURL {
			folderContentOutlineView.reloadData()
		}
		else {
			folderContentOutlineView.reloadItem(directoryURL, reloadChildren: true)
		}
	}
}

extension GLACollectedFolderContentsViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
	public func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
		let directoryURL: NSURL
		if item == nil {
			if let sourceDirectoryURL = sourceDirectoryURL {
				directoryURL = sourceDirectoryURL
			}
			else {
				return 0
			}
		}
		else {
			directoryURL = item as! NSURL
		}
		
		if let childURLs = arrangedChildrenForDirectoryURL(directoryURL) {
			return childURLs.count
		}
		else {
			if let errorLoadingChildURLs = fileInfoRetriever.errorRetrievingChildURLsOfDirectoryWithURL(directoryURL) {
				// TODO: present error some way.
			}
			
			return 0
		}
	}
	
	public func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
		let fileInfoRetriever = self.fileInfoRetriever
		
		let fileURL = item as! NSURL
		
		if let
			isRegularFileValue = fileInfoRetriever.resourceValueForKey(NSURLIsRegularFileKey, forURL:fileURL) as? NSNumber,
			isPackageValue = fileInfoRetriever.resourceValueForKey(NSURLIsPackageKey, forURL:fileURL) as? NSNumber
		{
			let isRegularFile = isRegularFileValue.boolValue
			let isPackage = isPackageValue.boolValue
			let treatAsFile = (isRegularFile || isPackage)
			return !treatAsFile
		}
		
		return false
	}
	
	public func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
		let directoryURL: NSURL
		if item == nil {
			directoryURL = sourceDirectoryURL
		}
		else {
			directoryURL = item as! NSURL
		}
		
		let childURLs = arrangedChildrenForDirectoryURL(directoryURL)
		return childURLs![index]
	}
	
	public func outlineView(outlineView: NSOutlineView, sortDescriptorsDidChange oldDescriptors: [AnyObject]) {
		updateSortingFromOutlineView()
	}
	
	public func outlineView(outlineView: NSOutlineView, pasteboardWriterForItem item: AnyObject?) -> NSPasteboardWriting! {
		return item as? NSURL
	}
	
	// MARK: Delegate
	
	public func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
		if let identifier = tableColumn?.identifier {
			let cellView = outlineView.makeViewWithIdentifier(identifier, owner: nil) as! NSTableCellView
			
			let fileURL = item as! NSURL
			let fileInfoRetriever = self.fileInfoRetriever
			
			var text: String?
			var image: NSImage?
			let hasImageView = (cellView.imageView != nil)
			
			switch identifier {
			case "displayNameAndIcon":
				text = fileInfoRetriever.resourceValueForKey(NSURLLocalizedNameKey, forURL: fileURL) as? String
				if hasImageView {
					image = fileInfoRetriever.resourceValueForKey(NSURLEffectiveIconKey, forURL: fileURL) as? NSImage
				}
			case "dateModified":
				if let dateModified = fileInfoRetriever.resourceValueForKey(NSURLContentModificationDateKey, forURL: fileURL) as? NSDate {
					text = dateFormatter.stringFromDate(dateModified)
				}
			default:
				break
			}
			
			cellView.textField?.stringValue = text ?? "Loading…"
			cellView.imageView?.image = image
			
			cellView.menu = contextualMenuAssistant.menu
			
			return cellView
		}
		
		return nil
	}
	
	public func outlineViewSelectionDidChange(notification: NSNotification) {
		assistant?.folderContentsSelectionDidChange()
		
		quickLookPreviewHelper.updatePreviewAnimating(true)
	}
}

extension GLACollectedFolderContentsViewController: GLAQuickLookPreviewHelperDelegate {
	public func selectedURLsForQuickLookPreviewHelper(helper: GLAQuickLookPreviewHelper) -> [AnyObject] {
		return selectedURLs
	}
	
	public func quickLookPreviewHelper(helper: GLAQuickLookPreviewHelper, tableRowForSelectedURL fileURL: NSURL) -> Int {
		return folderContentOutlineView.rowForItem(fileURL)
	}
	
	override public func acceptsPreviewPanelControl(panel: QLPreviewPanel!) -> Bool {
		return true
	}
	
	override public func beginPreviewPanelControl(panel: QLPreviewPanel!) {
		quickLookPreviewHelper.beginPreviewPanelControl(panel)
	}
	
	override public func endPreviewPanelControl(panel: QLPreviewPanel!) {
		quickLookPreviewHelper.endPreviewPanelControl(panel)
	}
	
	override public func quickLookPreviewItems(sender: AnyObject?) {
		quickLookPreviewHelper.quickLookPreviewItems(sender)
	}
}

extension GLACollectedFolderContentsViewController: NSMenuDelegate {
	public func menuNeedsUpdate(menu: NSMenu) {
		updateContextualMenu()
	}
}
