//
//  ProjectHighlightsAssistant.swift
//  Blik
//
//  Created by Patrick Smith on 31/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntFoundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



public enum HighlightItemSource {
	case item(item: GLAHighlightedItem, isGrouped: Bool)
	case groupedCollectionHeading(GLACollection)
	case masterFoldersHeading
	case masterFolder(GLACollectedFile)
}

private let masterFoldersHeadingUUID = UUID()

extension HighlightItemSource {
	var UUID: Foundation.UUID {
		switch self {
		case let .item(item, _):
			return item.uuid
		case let .groupedCollectionHeading(collection):
			return collection.uuid
		case .masterFoldersHeading:
			return masterFoldersHeadingUUID
		case let .masterFolder(folder):
			return folder.uuid
		}
	}
}

public enum HighlightItemDetails {
	case item(isGrouped: Bool, displayName: String?, isFolder: Bool?, icon: NSImage?, collection: GLACollection?)
	case groupedCollectionHeading(GLACollection)
	case masterFoldersHeading
	case masterFolder(displayName: String?, icon: NSImage?)
}

extension HighlightItemDetails {
	var displayName: String? {
		switch self {
		case let .item(_, displayName, _, _, _):
			return displayName
		case let .groupedCollectionHeading(collection):
			return collection.name
		case .masterFoldersHeading:
			return NSLocalizedString("Master Folders", comment: "Display name for Master Folders heading")
		case let .masterFolder(displayName, _):
			return displayName
		}
	}
	
	var icon: NSImage? {
		switch self {
		case let .item(_, _, _, icon, _):
			return icon
		case let .masterFolder(_, icon):
			return icon
		default:
			return nil
		}
	}
}

@objc open class ProjectHighlightsAssistant: NSObject {
	fileprivate var project: GLAProject
	fileprivate let projectManager: GLAProjectManager
	fileprivate let navigator: GLAMainSectionNavigator
	fileprivate let wantsIcons: Bool
	
	open var changesNotifier: (() -> ())?
	
	fileprivate let collectedFilesSetting: GLACollectedFilesSetting
	fileprivate let collectedFilesSettingObserver: AnyNotificationObserver
	
	fileprivate let highlightedItemsUser: GLALoadableArrayUsing!
	fileprivate var ungroupedHighlightedItems: [GLAHighlightedItem]!
	fileprivate var allHighlightedItems: [GLAHighlightedItem]!
	
	fileprivate let collectionsUser: GLALoadableArrayUsing!
	fileprivate var collections: [GLACollection]!
	fileprivate var groupedCollectionUUIDs: Set<UUID>!
	fileprivate var groupedCollectionUUIDsToItems: [UUID: [GLAHighlightedItem]]!
	
	fileprivate let primaryFoldersUser: GLALoadableArrayUsing!
	fileprivate var primaryFolders: [GLACollectedFile]?
	
	fileprivate var collectionObservers: [AnyObject]?
	
	init(project: GLAProject, projectManager: GLAProjectManager, navigator: GLAMainSectionNavigator, wantsIcons: Bool = false) {
		self.project = project
		self.projectManager = projectManager
		self.navigator = navigator
		self.wantsIcons = wantsIcons
		
		highlightedItemsUser = projectManager.useHighlights(for: project)
		collectionsUser = projectManager.useCollections(for: project)
		primaryFoldersUser = projectManager.usePrimaryFolders(forProjectUUID: project.uuid)
		
		collectedFilesSetting = GLACollectedFilesSetting()
		var keysToRequest = [URLResourceKey.localizedNameKey, URLResourceKey.isDirectoryKey, URLResourceKey.isPackageKey]
		if wantsIcons {
			keysToRequest.append(URLResourceKey.effectiveIconKey)
		}
		collectedFilesSetting.defaultURLResourceKeysToRequest = keysToRequest
		collectedFilesSettingObserver = AnyNotificationObserver(object: collectedFilesSetting)
		
		super.init()
		
		let changeCompletionBlock: (GLAArrayInspecting) -> () = { [weak self] _ in
			self?.reloadItems()
		}
		
		highlightedItemsUser.changeCompletionBlock = changeCompletionBlock
		collectionsUser.changeCompletionBlock = changeCompletionBlock
		primaryFoldersUser.changeCompletionBlock = changeCompletionBlock
		
		collectedFilesSettingObserver.observe(NSNotification.Name.GLACollectedFilesSettingLoadedFileInfoDidChange.rawValue) { [weak self] _ in
			self?.reloadItems()
		}
	}
	
	func collectedFileForHighlightedItem(_ highlightedItem: GLAHighlightedItem) -> GLACollectedFile? {
		guard let highlightedCollectedFile = highlightedItem as? GLAHighlightedCollectedFile else { return nil }
		
		return projectManager.collectedFile(for: highlightedCollectedFile, loadIfNeeded: true)
	}
	
	func highlightedItemIsGrouped(_ highlightedItem: GLAHighlightedItem) -> Bool {
		guard let highlightedCollectedFile = highlightedItem as? GLAHighlightedCollectedFile else { return false }
		
		let collectionUUID = highlightedCollectedFile.holdingCollectionUUID
		return groupedCollectionUUIDs.contains(collectionUUID)
	}
	
	func reloadItems() {
		guard let project = projectManager.project(with: project.uuid) else { return }
		self.project = project
		
		let allHighlightedItems = highlightedItemsUser.copyChildrenLoadingIfNeeded() as? [GLAHighlightedItem] ?? []
		let collections = collectionsUser.copyChildrenLoadingIfNeeded() as? [GLACollection] ?? []
		let primaryFolders = primaryFoldersUser.copyChildrenLoadingIfNeeded() as? [GLACollectedFile] ?? []
		
		self.collections = collections
		
		//let groupedCollectionUUIDs = Set<NSUUID>(collections.lazy.filter({ $0.highlighted }).map({ $0.UUID }))
		var groupedCollectionUUIDs = Set<UUID>()
		if project.groupHighlights {
			groupedCollectionUUIDs.formUnion(collections.lazy.map({ $0.uuid }))
		}
		self.groupedCollectionUUIDs = groupedCollectionUUIDs
		
		var groupedHighlightedItems = [GLAHighlightedItem]()
		var ungroupedHighlightedItems = [GLAHighlightedItem]()
		var groupedCollectionUUIDsToItems = [UUID: [GLAHighlightedItem]]()
		
		for highlightedItem in allHighlightedItems {
			let collectionUUID = highlightedItem.holdingCollectionUUID
			if groupedCollectionUUIDs.contains(collectionUUID) {
				var groupItems = groupedCollectionUUIDsToItems[collectionUUID] ?? [GLAHighlightedItem]()
				groupedCollectionUUIDsToItems[collectionUUID] = nil
				groupItems.append(highlightedItem)
				groupedCollectionUUIDsToItems[collectionUUID] = groupItems
				
				groupedHighlightedItems.append(highlightedItem)
			}
			else {
				ungroupedHighlightedItems.append(highlightedItem)
			}
		}
		self.ungroupedHighlightedItems = ungroupedHighlightedItems
		self.allHighlightedItems = allHighlightedItems
		
		/*let orderedGroupedItems = groupedCollectionUUIDsToItems.keys.map { collectionUUID in
			var items = groupedCollectionUUIDsToItems[collectionUUID]!
			
			guard let collection = projectManager.collectionWithUUID(collectionUUID, inProjectWithUUID: project.UUID) where collection.type == GLACollectionTypeFilesList else { return items }
			
			let orderedCollectedFiles = projectManager.copyFilesListForCollection(collection) as! [GLACollection]?
			
			items.sort { (highlightedItem1, highlightedItem2) -> Bool in
				
			}
		}*/
		self.groupedCollectionUUIDsToItems = groupedCollectionUUIDsToItems
		
		
		self.primaryFolders = primaryFolders
		
		
		var allCollectedFiles = [GLACollectedFile]()
		allCollectedFiles += allHighlightedItems.lazy.map(collectedFileForHighlightedItem).filter({ $0 != nil }).map({ $0! })
		allCollectedFiles += primaryFolders
		
		collectedFilesSetting.startAccessingCollectedFilesStoppingRemainders(allCollectedFiles)
		
		stopObserving()
		startObserving()
		//enabled = true
		
		changesNotifier?()
	}
	
	func startObserving() {
		let pm = projectManager
		let nc = NotificationCenter.default
		var collectionObservers = [AnyObject]()
		
		let collectionUUIDs = Set<UUID>(allHighlightedItems.lazy.map({ $0.holdingCollectionUUID }))
		
		let notificationBlock: (Notification) -> () = { [weak self] notification in
			self?.reloadItems()
		}
		func addObserverForName(_ name: String, object: AnyObject) {
			collectionObservers.append(
				nc.addObserver(forName: NSNotification.Name(rawValue: name), object: object, queue: nil, using: notificationBlock)
			)
		}
		
		for collectionUUID in collectionUUIDs {
			let collectionNotifier = pm.notificationObject(forCollectionUUID: collectionUUID)
			
			addObserverForName(NSNotification.Name.GLACollectionDidChange.rawValue, object: collectionNotifier as AnyObject)
			addObserverForName(NSNotification.Name.GLACollectionFilesListDidChange.rawValue, object: collectionNotifier as AnyObject)
			addObserverForName(NSNotification.Name.GLAProjectManagerAllProjectsDidChange.rawValue, object: pm)
		}
		
		addObserverForName(NSNotification.Name.GLAProjectCollectionsDidChange.rawValue, object: pm.notificationObject(forProjectUUID: project.uuid) as AnyObject)
		
		self.collectionObservers = collectionObservers
	}
	
	func stopObserving() {
		guard let collectionObservers = self.collectionObservers else { return }
		
		let nc = NotificationCenter.default
		
		for observer in collectionObservers {
			nc.removeObserver(observer)
		}
		
		self.collectionObservers = nil
	}
	
	//var enabled
	
	open var itemCount: Int {
		var count: Int = 0
		
		count += allHighlightedItems.count
		
		if project.groupHighlights {
			// For collection group headings
			count += groupedCollectionUUIDsToItems.count
		}
		
		if let masterFolderCount = primaryFolders?.count , masterFolderCount > 0 {
			count += masterFolderCount
			// Add master folders with heading
			if project.groupHighlights {
				count += 1
			}
		}
		
		return count
	}
	
	var hasUngroupedItems: Bool {
		return ungroupedHighlightedItems.count > 0
	}
	
	fileprivate func detailsForHighlightedItem(_ highlightedItem: GLAHighlightedItem, isGrouped: Bool) -> HighlightItemDetails {
		var displayName: String?
		var isFolder: Bool?
		var icon: NSImage?
		var collection: GLACollection?
		
		if let highlightedCollectedFile = highlightedItem as? GLAHighlightedCollectedFile {
			if let collectedFile = projectManager.collectedFile(for: highlightedCollectedFile, loadIfNeeded: true) {
				collection = projectManager.collection(for: highlightedCollectedFile, loadIfNeeded: true)
				
				if collectedFile.empty {
					displayName = NSLocalizedString("(Gone)", comment: "Display name for empty collected file");
				}
				else {
					displayName = highlightedItem.customName ??
						collectedFilesSetting.copyValue(forURLResourceKey: URLResourceKey.localizedNameKey.rawValue, for: collectedFile) as? String
					
					if let
						isDirectoryValue = collectedFilesSetting.copyValue(forURLResourceKey: URLResourceKey.isDirectoryKey.rawValue, for: collectedFile) as? NSNumber,
						let isPackageValue = collectedFilesSetting.copyValue(forURLResourceKey: URLResourceKey.isPackageKey.rawValue, for: collectedFile) as? NSNumber {
							isFolder = (isDirectoryValue.boolValue && !isPackageValue.boolValue)
					}
					
					icon = wantsIcons ? collectedFilesSetting.copyValue(forURLResourceKey: URLResourceKey.effectiveIconKey.rawValue, for: collectedFile) as? NSImage : nil
				}
			}
		}
		else {
			fatalError("Unknown GLAHighlightedItem type \(highlightedItem)")
		}
		
		return .item(isGrouped: isGrouped, displayName: displayName, isFolder: isFolder, icon: icon, collection: collection)
	}
	
	open subscript(index: Int) -> HighlightItemSource {
		let ungroupedItemCount = ungroupedHighlightedItems.count
		
		// Ungrouped first
		if index < ungroupedItemCount {
			let highlightedItem = ungroupedHighlightedItems[index]
			return .item(item: highlightedItem, isGrouped: false)
		}
		
		// Grouped into collections
		var groupedItemIndex = ungroupedItemCount;
		for collection in collections {
			/*if !collection.highlighted {
				continue;
			}*/
			if !project.groupHighlights {
				continue;
			}
			
			if let groupItems = groupedCollectionUUIDsToItems[collection.uuid] {
				if index == groupedItemIndex {
					return .groupedCollectionHeading(collection)
				}
				
				groupedItemIndex += 1
				
				if index < (groupedItemIndex + groupItems.count) {
					let highlightedItem = groupItems[index - groupedItemIndex]
					return .item(item: highlightedItem, isGrouped: true)
				}
				
				groupedItemIndex += groupItems.count
			}
		}
		
		if project.groupHighlights {
			if index == groupedItemIndex && primaryFolders?.count > 0 {
				return .masterFoldersHeading
			}
			
			groupedItemIndex += 1
		}
		
		// Master folders
		let masterFolderIndex = index - groupedItemIndex
		let collectedFolder = primaryFolders![masterFolderIndex]
		return .masterFolder(collectedFolder)
	}
	
	open func detailsAtIndex(_ index: Int) -> HighlightItemDetails {
		switch self[index] {
		case let .item(highlightedItem, isGrouped):
			return self.detailsForHighlightedItem(highlightedItem, isGrouped: isGrouped)
		case let .groupedCollectionHeading(collection):
			return .groupedCollectionHeading(collection)
		case .masterFoldersHeading:
			return .masterFoldersHeading
		case let .masterFolder(collectedFolder):
			let displayName = self.collectedFilesSetting.copyValue(forURLResourceKey: URLResourceKey.localizedNameKey.rawValue, for: collectedFolder) as? String
			let icon = wantsIcons ? collectedFilesSetting.copyValue(forURLResourceKey: URLResourceKey.effectiveIconKey.rawValue, for: collectedFolder) as? NSImage : nil
			
			return .masterFolder(displayName: displayName, icon: icon)
		}
	}
	
	func fileURLAtIndex(_ index: Int) -> URL? {
		var collectedFile: GLACollectedFile?
		
		switch self[index] {
		case let .item(highlightedItem, _):
			if let highlightedCollectedFile = highlightedItem as? GLAHighlightedCollectedFile {
				collectedFile = projectManager.collectedFile(for: highlightedCollectedFile, loadIfNeeded: true)
			}
		case let .masterFolder(collectedFolder):
			collectedFile = collectedFolder
		default:
			return nil
		}
		
		return collectedFile?.accessFile()?.filePathURL
	}
	
	var details: AnyRandomAccessCollection<HighlightItemDetails> {
		return AnyRandomAccessCollection(lazy.map {
			switch $0 {
			case let .item(highlightedItem, isGrouped):
				return self.detailsForHighlightedItem(highlightedItem, isGrouped: isGrouped)
			case let .groupedCollectionHeading(collection):
				return .groupedCollectionHeading(collection)
			case .masterFoldersHeading:
				return .masterFoldersHeading
			case let .masterFolder(collectedFolder):
				let displayName = self.collectedFilesSetting.copyValue(forURLResourceKey: URLResourceKey.localizedNameKey.rawValue, for: collectedFolder) as? String
				let icon = self.wantsIcons ? self.collectedFilesSetting.copyValue(forURLResourceKey: URLResourceKey.effectiveIconKey.rawValue, for: collectedFolder) as? NSImage : nil
				
				return .masterFolder(displayName: displayName, icon: icon)
			}
		})
	}
	
	open func outputIndexesForTableRows(_ rowIndexes: IndexSet) -> IndexSet {
		let mutableIndexes = (rowIndexes as NSIndexSet).mutableCopy() as! NSMutableIndexSet
		var itemIndex = 0;
		for highlightedItem in allHighlightedItems {
			// Advance over grouped items
			if highlightedItemIsGrouped(highlightedItem) {
				mutableIndexes.shiftIndexesStarting(at: itemIndex, by: 1)
			}
			
			itemIndex += 1
		}
		
		return mutableIndexes as IndexSet
	}
}

extension ProjectHighlightsAssistant: Collection {
	public typealias Index = Int
	
	public var startIndex: Index {
		return 0
	}
	
	public var endIndex: Index {
		return itemCount
	}
  
  public func index(after i: Int) -> Int {
    return i + 1
  }
}

extension ProjectHighlightsAssistant: GLAArrayTableDraggingHelperDelegate {
	public func arrayEditorTableDraggingHelper(_ tableDraggingHelper: GLAArrayTableDraggingHelper, canUseDragging draggingPasteboard: NSPasteboard) -> Bool {
		return GLAHighlightedCollectedFile.canCopyObjects(from: draggingPasteboard)
	}
	
	public func arrayEditorTableDraggingHelper(_ tableDraggingHelper: GLAArrayTableDraggingHelper, outputIndexesForTableRows rowIndexes: IndexSet) -> IndexSet {
		return outputIndexesForTableRows(rowIndexes)
	}
	
	public func arrayEditorTableDraggingHelper(_ tableDraggingHelper: GLAArrayTableDraggingHelper, makeChangesUsingEditing editBlock: @escaping GLAArrayEditingBlock) {
		highlightedItemsUser.editChildren(editBlock)
	}
}

extension ProjectHighlightsAssistant {
	func openItem(_ item: HighlightItemSource, withBehaviour behaviour: OpeningBehaviour, activateIfNeeded: Bool = false) {
		var needsActivation = false
		
		switch item {
		case let .item(highlightedCollectedFile as GLAHighlightedCollectedFile, _):
			projectManager.openHighlightedCollectedFile(highlightedCollectedFile, behaviour: behaviour)
		case let .groupedCollectionHeading(collection):
			navigator.go(to: collection)
			
			needsActivation = activateIfNeeded
		case .masterFoldersHeading:
			navigator.editPrimaryFolders(of: project)
			
			needsActivation = activateIfNeeded
		case let .masterFolder(collectedFolder):
			projectManager.openCollectedFile(collectedFolder, behaviour: behaviour)
		default:
			break
		}
		
		if needsActivation {
			NSApp.activate(ignoringOtherApps: true)
		}
	}
	
	func openItem(atIndex index: Index, withBehaviour behaviour: OpeningBehaviour, activateIfNeeded: Bool = false) {
		openItem(self[index], withBehaviour: behaviour, activateIfNeeded: activateIfNeeded)
	}
	
	public var canOpenAllHighlights: Bool {
		return allHighlightedItems.count > 0
	}
	
	public func openAllHighlights(_ behaviour: OpeningBehaviour = .default) {
		for highlightedItem in allHighlightedItems {
			if let highlightedCollectedFile = highlightedItem as? GLAHighlightedCollectedFile {
				projectManager.openHighlightedCollectedFile(highlightedCollectedFile, behaviour: behaviour)
			}
		}
	}
}
