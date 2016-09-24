//
//  GLACollectedFolderContentsViewController.swift
//  Blik
//
//  Created by Patrick Smith on 16/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntCocoaUI


private enum BrowseChoice {
	case hierarchy
	case loadingAvailableTags
	case filesWithTag(tagName: String)
	case zeroAvailableTags
}

extension BrowseChoice: UIChoiceRepresentative {
	var title: String {
		switch self {
		case .hierarchy:
			return NSLocalizedString("Content", comment: "Title for hierachy folder contents browsing choice.")
		case .loadingAvailableTags:
			return NSLocalizedString("(Loading Tags)", comment: "Title for hierachy folder contents browsing choice when loading tags.")
		case let .filesWithTag(tagName):
			return tagName
		case .zeroAvailableTags:
			return NSLocalizedString("(No Tags)", comment: "Title for hierachy folder contents browsing choice when there are no tags.")
		}
	}
	
	typealias UniqueIdentifier = String
	var uniqueIdentifier: UniqueIdentifier {
		switch self {
		case .hierarchy:
			return "hierarchy"
		case .loadingAvailableTags:
			return "loadingAvailableTags"
		case let .filesWithTag(tagName):
			return "filesWithTag-\(tagName)"
		case .zeroAvailableTags:
			return "zeroAvailableTags"
		}
	}
}


@objc open class GLACollectedFolderContentsViewController: GLAViewController {
	
	var resourceKeyToSortBy = URLResourceKey.localizedNameKey
	var sortsAscending = true
	var hidesInvisibles = true
	
	@IBOutlet var folderContentOutlineView: NSOutlineView!
	
	open var assistant: GLAFolderContentsAssisting?
	
	var fileInfoRetriever: GLAFileInfoRetriever!
	var directoryURLToArrangedChildren = [URL: GLAArrangedDirectoryChildren]()
	//var availableTagNames: Set<String>?
	
	fileprivate var browseChoice: BrowseChoice = .hierarchy
	@IBOutlet var browseChoicePopUpButton: NSPopUpButton!
	fileprivate var browseChoicePopUpButtonAssistant: PopUpButtonAssistant<BrowseChoice>!
	
	var dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .short
		dateFormatter.doesRelativeDateFormatting = true
		return dateFormatter
	}()
	
	var quickLookPreviewHelper: GLAQuickLookPreviewHelper!
	
	fileprivate enum MenuChoice: Int, UIChoiceRepresentative {
		case addToCollection = 1
		case removeFromCollection
		case showInFinder
		
		var title: String {
			switch self {
			case .addToCollection:
				return "Add to Collection"
			case .removeFromCollection:
				return "Remove from Collection"
			case .showInFinder:
				return "Show in Finder…"
			}
		}
		
		typealias UniqueIdentifier = MenuChoice
		var uniqueIdentifier: UniqueIdentifier { return self }
	}
	fileprivate var contextualMenuAssistant: MenuAssistant<MenuChoice>!
	
	
	override open class func defaultNibName() -> String {
		return "GLACollectedFolderContentsViewController"
	}
	
	override open func prepareView() {
		insertIntoResponderChain()
		
		let defaultResourceKeys = [
			URLResourceKey.isDirectoryKey,
			URLResourceKey.isPackageKey,
			URLResourceKey.isRegularFileKey,
			URLResourceKey.isSymbolicLinkKey,
			URLResourceKey.localizedNameKey,
			URLResourceKey.effectiveIconKey,
			URLResourceKey.isHiddenKey,
			URLResourceKey.contentModificationDateKey
		]
		fileInfoRetriever = GLAFileInfoRetriever(delegate:self, defaultResourceKeysToRequest:defaultResourceKeys)
		
		let style = GLAUIStyle.active()
		
		let folderContentOutlineView = self.folderContentOutlineView!
		
		let nameSortDescriptor = NSSortDescriptor(key:URLResourceKey.localizedNameKey.rawValue, ascending:true)
		let dateModifiedSortDescriptor = NSSortDescriptor(key:URLResourceKey.contentModificationDateKey.rawValue, ascending:false)
		
		let displayNameTableColumn = folderContentOutlineView.tableColumn(withIdentifier: "displayNameAndIcon")!
		displayNameTableColumn.sortDescriptorPrototype = nameSortDescriptor
		
		let dateModifiedTableColumn = folderContentOutlineView.tableColumn(withIdentifier: "dateModified")!
		dateModifiedTableColumn.sortDescriptorPrototype = dateModifiedSortDescriptor
		
		style.prepareContentTableColumn(displayNameTableColumn)
		style.prepareContentTableColumn(dateModifiedTableColumn)
		
		folderContentOutlineView.sortDescriptors = [nameSortDescriptor]
		
		// Individually autosaves each folder by URL.
		folderContentOutlineView.autosaveTableColumns = true
		//(folderContentOutlineView.autosaveExpandedItems) = YES;
		
		updateSortingFromOutlineView()
		
		folderContentOutlineView.dataSource = self
		folderContentOutlineView.delegate = self
		folderContentOutlineView.target = self
		folderContentOutlineView.doubleAction = #selector(GLACollectedFolderContentsViewController.openSelectedFiles(_:))
		style.prepareContentTableView(folderContentOutlineView)
		
		//browseChoicePopUpButtonAssistant = PopUpButtonAssistant<BrowseChoice>(popUpButton: browseChoicePopUpButton)
		
		reloadContentsOfFolder()
		
		quickLookPreviewHelper = GLAQuickLookPreviewHelper()
		quickLookPreviewHelper.delegate = self;
		quickLookPreviewHelper.sourceTableView = folderContentOutlineView
		
		let contextualMenu = NSMenu()
		contextualMenu.delegate = self
		contextualMenuAssistant = MenuAssistant<MenuChoice>(menu: contextualMenu)
		updateContextualMenu(true)
	}
	
	var directoryWatcher: GLADirectoryWatcher?
	
	var collectedFolder: GLACollectedFile!
	var sourceDirectoryURL: URL! {
		didSet {
			// Make sure view has loaded
			_ = self.view
			
			if let sourceDirectoryURL = sourceDirectoryURL {
				let directoryWatcher = self.directoryWatcher ?? GLADirectoryWatcher(delegate: self, previousStateData: nil)!
				directoryWatcher.directoryURLsToWatch = Set([sourceDirectoryURL])
				self.directoryWatcher = directoryWatcher
				
				// Use a specific autosave name for the columns using the directory path.
				folderContentOutlineView.autosaveName = "collectedFolderContentsOutlineView-\(sourceDirectoryURL.path)"
			}
			else {
				directoryWatcher = nil
			}
			
			//updateBrowseChoiceUI(initial: true)
			
			reloadContentsOfFolder()
		}
	}
	
	func reloadContentsOfFolder() {
		directoryURLToArrangedChildren.removeAll()
		
		folderContentOutlineView.reloadData()
	}
	
	func updateBrowseChoiceUI(_ initial: Bool = false) {
		if let sourceDirectoryURL = sourceDirectoryURL {
			var browseChoices: [BrowseChoice?] = [
				.hierarchy,
				nil
			]
			
			if let tagNames = fileInfoRetriever.availableTagNames(insideDirectoryURL: sourceDirectoryURL, requestIfNeeded: true) as? Set<String> {
				if tagNames.count > 0 {
					for tagName in tagNames {
						browseChoices.append(
							BrowseChoice.filesWithTag(tagName: tagName)
						)
					}
				}
				else {
					browseChoices.append(
						BrowseChoice.zeroAvailableTags
					)
				}
			}
			else {
				browseChoices.append(
					BrowseChoice.loadingAvailableTags
				)
			}
			
			if initial {
				browseChoicePopUpButtonAssistant.menuAssistant.customization.enabled = { choice in
					switch choice {
					case .hierarchy, .filesWithTag:
						return true
					default:
						return false
					}
				}
			}
			
			browseChoicePopUpButtonAssistant.menuItemRepresentatives = browseChoices
			browseChoicePopUpButtonAssistant.update()
		}
	}
	
	func updateSortingFromOutlineView() {
		let sortDescriptors = folderContentOutlineView.sortDescriptors
		if sortDescriptors.count > 0 {
			let firstSortDescriptor = sortDescriptors[0] 
			
			let sortingKey = firstSortDescriptor.key!
			resourceKeyToSortBy = URLResourceKey(rawValue: sortingKey)
			sortsAscending = firstSortDescriptor.ascending
			
			updateAllArrangedChildrenWithSortingOptions()
		}
	}
	
	func arrangedChildrenForDirectoryURL(_ directoryURL: URL) -> [URL]? {
		let arrangedChildren = directoryURLToArrangedChildren[directoryURL] ?? {
			let arrangedChildren = GLAArrangedDirectoryChildren(directoryURL:directoryURL, delegate:self, fileInfoRetriever:self.fileInfoRetriever)
			self.directoryURLToArrangedChildren[directoryURL] = arrangedChildren
			
			self.updateArrangedChildrenWithSortingOptions(arrangedChildren!)
			
			return arrangedChildren!
		}()
		
		return arrangedChildren.arrangedChildren as! [URL]?
	}
	
	func updateArrangedChildrenWithSortingOptions(_ arrangedChildren: GLAArrangedDirectoryChildren)
	{
		arrangedChildren.update { editor in
			editor?.resourceKeyToSortBy = self.resourceKeyToSortBy.rawValue
			editor?.sortsAscending = self.sortsAscending
			editor?.hidesInvisibles = self.hidesInvisibles
		}
	}
	
	func updateAllArrangedChildrenWithSortingOptions() {
		for (directoryURL, arrangedChildren) in directoryURLToArrangedChildren {
			updateArrangedChildrenWithSortingOptions(arrangedChildren)
		}
	}
	
	open var selectedURLs: [URL] {
    guard let folderContentOutlineView = self.folderContentOutlineView
        else { return [] }
    
    return folderContentOutlineView.selectedRowIndexes.map({ rowIndex in
      return folderContentOutlineView.item(atRow: rowIndex) as! URL
    })
	}
	
	open var hasFirstResponder: Bool {
		let folderContentOutlineView = self.folderContentOutlineView!
		
		if let firstResponder = folderContentOutlineView.window?.firstResponder as? NSView {
			return firstResponder.isDescendant(of: folderContentOutlineView)
		}
		
		return false
	}
	
	@IBAction internal func openSelectedFiles(_ sender: AnyObject?) {
		assistant?.openFolderContentsSelectedFiles()
	}
	
	override open func keyDown(with theEvent: NSEvent) {
		if theEvent.burnt_isSpaceKey {
			quickLookPreviewItems(self)
		}
	}
}

extension GLACollectedFolderContentsViewController {
	var fileURLsForContextualMenu: [URL]? {
		let row = folderContentOutlineView.clickedRow
		if row == -1 {
			return nil
		}
		
		if folderContentOutlineView.isRowSelected(row) {
			return selectedURLs
		}
		else if let fileURL = folderContentOutlineView.item(atRow: row) as? URL {
			return [fileURL]
		}
		
		return nil
	}
	
	func updateContextualMenu(_ initial: Bool = false) {
		if initial {
			contextualMenuAssistant.customization.actionAndTarget = { [unowned self] choice in
				switch choice {
				case .addToCollection:
					return (action: #selector(GLACollectedFolderContentsViewController.addSelectedFileToCollection(_:)), target: self)
				case .removeFromCollection:
					return (action: #selector(GLACollectedFolderContentsViewController.removeSelectedFileFromCollection(_:)), target: self)
				case .showInFinder:
					return (action: #selector(GLACollectedFolderContentsViewController.showSelectedFileInFinder(_:)), target: self)
				}
			}
		}
		
		var showAdd = true
		
		if let assistant = assistant, let fileURLsForContextualMenu = fileURLsForContextualMenu {
			if assistant.fileURLsAreAllCollected(fileURLsForContextualMenu) {
				showAdd = false
			}
		}
		
		contextualMenuAssistant.menuItemRepresentatives = [
			showAdd ? .addToCollection : .removeFromCollection,
			nil,
			.showInFinder
		]
		contextualMenuAssistant.update()
	}
	
	@IBAction func addSelectedFileToCollection(_ sender: AnyObject?) {
		if let fileURLsForContextualMenu = fileURLsForContextualMenu {
			assistant?.addFileURLs(toCollection: fileURLsForContextualMenu)
		}
	}
	
	@IBAction func removeSelectedFileFromCollection(_ sender: AnyObject?) {
		if let fileURLsForContextualMenu = fileURLsForContextualMenu {
			assistant?.removeFileURLs(fromCollection: fileURLsForContextualMenu)
		}
	}
	
	@IBAction func showSelectedFileInFinder(_ sender: AnyObject?) {
		if let fileURLsForContextualMenu = fileURLsForContextualMenu {
			NSWorkspace.shared().activateFileViewerSelecting(fileURLsForContextualMenu)
		}
	}
}

extension GLACollectedFolderContentsViewController: GLAArrangedDirectoryChildrenDelegate {
	public func arrangedDirectoryChildrenDidUpdate(_ arrangedDirectoryChildren: GLAArrangedDirectoryChildren) {
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
	public func fileInfoRetriever(_ fileInfoRetriever: GLAFileInfoRetriever, didRetrieveAvailableTagNamesInsideDirectoryURL directoryURL: URL) {
		updateBrowseChoiceUI()
	}
	
	@nonobjc public func fileInfoRetriever(_ fileInfoRetriever: GLAFileInfoRetriever, didFailWithError error: NSError, retrievingContentsOfDirectoryURL directoryURL: URL) {
		if directoryURL == sourceDirectoryURL {
			folderContentOutlineView.reloadData()
		}
		else {
			folderContentOutlineView.reloadItem(directoryURL, reloadChildren: true)
		}
	}
}

extension GLACollectedFolderContentsViewController: GLADirectoryWatcherDelegate {
	public func directoryWatcher(_ directoryWatcher: GLADirectoryWatcher!, directoriesURLsDidChange directoryURLs: [Any]!) {
		reloadContentsOfFolder()
	}
}

extension GLACollectedFolderContentsViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
	public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		let directoryURL: URL
		if item == nil {
			if let sourceDirectoryURL = sourceDirectoryURL {
				directoryURL = sourceDirectoryURL
			}
			else {
				return 0
			}
		}
		else {
			directoryURL = item as! URL
		}
		
		if let childURLs = arrangedChildrenForDirectoryURL(directoryURL) {
			return childURLs.count
		}
		else {
			if let errorLoadingChildURLs = fileInfoRetriever.errorRetrievingChildURLsOfDirectory(with: directoryURL) {
				// TODO: present error some way.
			}
			
			return 0
		}
	}
	
	public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		let fileInfoRetriever = self.fileInfoRetriever
		
		let fileURL = item as! URL
		
		if let
			isRegularFileValue = fileInfoRetriever?.resourceValue(forKey: URLResourceKey.isRegularFileKey.rawValue, for:fileURL) as? NSNumber,
			let isPackageValue = fileInfoRetriever?.resourceValue(forKey: URLResourceKey.isPackageKey.rawValue, for:fileURL) as? NSNumber
		{
			let isRegularFile = isRegularFileValue.boolValue
			let isPackage = isPackageValue.boolValue
			let treatAsFile = (isRegularFile || isPackage)
			return !treatAsFile
		}
		
		return false
	}
	
	public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		let directoryURL: URL
		if item == nil {
			directoryURL = sourceDirectoryURL
		}
		else {
			directoryURL = item as! URL
		}
		
		let childURLs = arrangedChildrenForDirectoryURL(directoryURL)
		return childURLs![index]
	}
	
	public func outlineView(_ outlineView: NSOutlineView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
		updateSortingFromOutlineView()
	}
	
	public func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
		return item as? URL as NSPasteboardWriting?
	}
	
	// MARK: Delegate
	
	public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		if let identifier = tableColumn?.identifier {
			let cellView = outlineView.make(withIdentifier: identifier, owner: nil) as! NSTableCellView
			
			let fileURL = item as! URL
			let fileInfoRetriever = self.fileInfoRetriever
			
			var text: String?
			var image: NSImage?
			let hasImageView = (cellView.imageView != nil)
			
			switch identifier {
			case "displayNameAndIcon":
				text = fileInfoRetriever?.resourceValue(forKey: URLResourceKey.localizedNameKey.rawValue, for: fileURL) as? String
				if hasImageView {
					image = fileInfoRetriever?.resourceValue(forKey: URLResourceKey.effectiveIconKey.rawValue, for: fileURL) as? NSImage
				}
			case "dateModified":
				if let dateModified = fileInfoRetriever?.resourceValue(forKey: URLResourceKey.contentModificationDateKey.rawValue, for: fileURL) as? Date {
					text = dateFormatter.string(from: dateModified)
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
	
	public func outlineViewSelectionDidChange(_ notification: Notification) {
		assistant?.folderContentsSelectionDidChange()
		
		quickLookPreviewHelper.updatePreviewAnimating(true)
	}
}

extension GLACollectedFolderContentsViewController: GLAQuickLookPreviewHelperDelegate {
	public func selectedURLs(for helper: GLAQuickLookPreviewHelper) -> [Any] {
		return selectedURLs as [AnyObject]
	}
	
	public func quickLookPreviewHelper(_ helper: GLAQuickLookPreviewHelper, tableRowForSelectedURL fileURL: URL) -> Int {
		return folderContentOutlineView.row(forItem: fileURL)
	}
	
	override open func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
		return true
	}
	
	override open func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
		quickLookPreviewHelper.beginPreviewPanelControl(panel)
	}
	
	override open func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
		quickLookPreviewHelper.endPreviewPanelControl(panel)
	}
	
	override open func quickLookPreviewItems(_ sender: Any?) {
		quickLookPreviewHelper.quickLookPreviewItems(sender)
	}
}

extension GLACollectedFolderContentsViewController: NSMenuDelegate {
	public func menuNeedsUpdate(_ menu: NSMenu) {
		updateContextualMenu()
	}
}
