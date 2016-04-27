//
//  ProjectHighlightsAssistant.swift
//  Blik
//
//  Created by Patrick Smith on 31/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntFoundation


public enum HighlightItemSource {
	case Item(item: GLAHighlightedItem, isGrouped: Bool)
	case GroupedCollectionHeading(GLACollection)
	case MasterFoldersHeading
	case MasterFolder(GLACollectedFile)
}

private let masterFoldersHeadingUUID = NSUUID()

extension HighlightItemSource {
	var UUID: NSUUID {
		switch self {
		case let .Item(item, _):
			return item.UUID
		case let .GroupedCollectionHeading(collection):
			return collection.UUID
		case .MasterFoldersHeading:
			return masterFoldersHeadingUUID
		case let .MasterFolder(folder):
			return folder.UUID
		}
	}
}

public enum HighlightItemDetails {
	case Item(isGrouped: Bool, displayName: String?, isFolder: Bool?, icon: NSImage?, collection: GLACollection?)
	case GroupedCollectionHeading(GLACollection)
	case MasterFoldersHeading
	case MasterFolder(displayName: String?, icon: NSImage?)
}

extension HighlightItemDetails {
	var displayName: String? {
		switch self {
		case let .Item(_, displayName, _, _, _):
			return displayName
		case let .GroupedCollectionHeading(collection):
			return collection.name
		case .MasterFoldersHeading:
			return NSLocalizedString("Master Folders", comment: "Display name for Master Folders heading")
		case let .MasterFolder(displayName, _):
			return displayName
		}
	}
	
	var icon: NSImage? {
		switch self {
		case let .Item(_, _, _, icon, _):
			return icon
		case let .MasterFolder(_, icon):
			return icon
		default:
			return nil
		}
	}
}

@objc public class ProjectHighlightsAssistant: NSObject {
	private var project: GLAProject
	private let projectManager: GLAProjectManager
	private let navigator: GLAMainSectionNavigator
	private let wantsIcons: Bool
	
	public var changesNotifier: (() -> ())?
	
	private let collectedFilesSetting: GLACollectedFilesSetting
	private let collectedFilesSettingObserver: AnyNotificationObserver
	
	private let highlightedItemsUser: GLALoadableArrayUsing!
	private var ungroupedHighlightedItems: [GLAHighlightedItem]!
	private var allHighlightedItems: [GLAHighlightedItem]!
	
	private let collectionsUser: GLALoadableArrayUsing!
	private var collections: [GLACollection]!
	private var groupedCollectionUUIDs: Set<NSUUID>!
	private var groupedCollectionUUIDsToItems: [NSUUID: [GLAHighlightedItem]]!
	
	private let primaryFoldersUser: GLALoadableArrayUsing!
	private var primaryFolders: [GLACollectedFile]?
	
	private var collectionObservers: [AnyObject]?
	
	init(project: GLAProject, projectManager: GLAProjectManager, navigator: GLAMainSectionNavigator, wantsIcons: Bool = false) {
		self.project = project
		self.projectManager = projectManager
		self.navigator = navigator
		self.wantsIcons = wantsIcons
		
		highlightedItemsUser = projectManager.useHighlightsForProject(project)
		collectionsUser = projectManager.useCollectionsForProject(project)
		primaryFoldersUser = projectManager.usePrimaryFoldersForProjectUUID(project.UUID)
		
		collectedFilesSetting = GLACollectedFilesSetting()
		var keysToRequest = [NSURLLocalizedNameKey, NSURLIsDirectoryKey, NSURLIsPackageKey]
		if wantsIcons {
			keysToRequest.append(NSURLEffectiveIconKey)
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
		
		collectedFilesSettingObserver.observe(GLACollectedFilesSettingLoadedFileInfoDidChangeNotification) { [weak self] _ in
			self?.reloadItems()
		}
	}
	
	func collectedFileForHighlightedItem(highlightedItem: GLAHighlightedItem) -> GLACollectedFile? {
		guard let highlightedCollectedFile = highlightedItem as? GLAHighlightedCollectedFile else { return nil }
		
		return projectManager.collectedFileForHighlightedCollectedFile(highlightedCollectedFile, loadIfNeeded: true)
	}
	
	func highlightedItemIsGrouped(highlightedItem: GLAHighlightedItem) -> Bool {
		guard let highlightedCollectedFile = highlightedItem as? GLAHighlightedCollectedFile else { return false }
		
		let collectionUUID = highlightedCollectedFile.holdingCollectionUUID
		return groupedCollectionUUIDs.contains(collectionUUID)
	}
	
	func reloadItems() {
		guard let project = projectManager.projectWithUUID(project.UUID) else { return }
		self.project = project
		
		let allHighlightedItems = highlightedItemsUser.copyChildrenLoadingIfNeeded() as? [GLAHighlightedItem] ?? []
		let collections = collectionsUser.copyChildrenLoadingIfNeeded() as? [GLACollection] ?? []
		let primaryFolders = primaryFoldersUser.copyChildrenLoadingIfNeeded() as? [GLACollectedFile] ?? []
		
		self.collections = collections
		
		//let groupedCollectionUUIDs = Set<NSUUID>(collections.lazy.filter({ $0.highlighted }).map({ $0.UUID }))
		var groupedCollectionUUIDs = Set<NSUUID>()
		if project.groupHighlights {
			groupedCollectionUUIDs.unionInPlace(collections.lazy.map({ $0.UUID }))
		}
		self.groupedCollectionUUIDs = groupedCollectionUUIDs
		
		var groupedHighlightedItems = [GLAHighlightedItem]()
		var ungroupedHighlightedItems = [GLAHighlightedItem]()
		var groupedCollectionUUIDsToItems = [NSUUID: [GLAHighlightedItem]]()
		
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
		let nc = NSNotificationCenter.defaultCenter()
		var collectionObservers = [AnyObject]()
		
		let collectionUUIDs = Set<NSUUID>(allHighlightedItems.lazy.map({ $0.holdingCollectionUUID }))
		
		let notificationBlock: (NSNotification) -> () = { [weak self] notification in
			self?.reloadItems()
		}
		func addObserverForName(name: String, object: AnyObject) {
			collectionObservers.append(
				nc.addObserverForName(name, object: object, queue: nil, usingBlock: notificationBlock)
			)
		}
		
		for collectionUUID in collectionUUIDs {
			let collectionNotifier = pm.notificationObjectForCollectionUUID(collectionUUID)
			
			addObserverForName(GLACollectionDidChangeNotification, object: collectionNotifier)
			addObserverForName(GLACollectionFilesListDidChangeNotification, object: collectionNotifier)
			addObserverForName(GLAProjectManagerAllProjectsDidChangeNotification, object: pm)
		}
		
		addObserverForName(GLAProjectCollectionsDidChangeNotification, object: pm.notificationObjectForProjectUUID(project.UUID))
		
		self.collectionObservers = collectionObservers
	}
	
	func stopObserving() {
		guard let collectionObservers = self.collectionObservers else { return }
		
		let nc = NSNotificationCenter.defaultCenter()
		
		for observer in collectionObservers {
			nc.removeObserver(observer)
		}
		
		self.collectionObservers = nil
	}
	
	//var enabled
	
	public var itemCount: Int {
		var count: Int = 0
		
		count += allHighlightedItems.count
		
		if project.groupHighlights {
			// For collection group headings
			count += groupedCollectionUUIDsToItems.count
		}
		
		if let masterFolderCount = primaryFolders?.count where masterFolderCount > 0 {
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
	
	private func detailsForHighlightedItem(highlightedItem: GLAHighlightedItem, isGrouped: Bool) -> HighlightItemDetails {
		var displayName: String?
		var isFolder: Bool?
		var icon: NSImage?
		var collection: GLACollection?
		
		if let highlightedCollectedFile = highlightedItem as? GLAHighlightedCollectedFile {
			if let collectedFile = projectManager.collectedFileForHighlightedCollectedFile(highlightedCollectedFile, loadIfNeeded: true) {
				collection = projectManager.collectionForHighlightedCollectedFile(highlightedCollectedFile, loadIfNeeded: true)
				
				if collectedFile.empty {
					displayName = NSLocalizedString("(Gone)", comment: "Display name for empty collected file");
				}
				else {
					displayName = highlightedItem.customName ??
						collectedFilesSetting.copyValueForURLResourceKey(NSURLLocalizedNameKey, forCollectedFile: collectedFile) as? String
					
					if let
						isDirectoryValue = collectedFilesSetting.copyValueForURLResourceKey(NSURLIsDirectoryKey, forCollectedFile: collectedFile) as? NSNumber,
						isPackageValue = collectedFilesSetting.copyValueForURLResourceKey(NSURLIsPackageKey, forCollectedFile: collectedFile) as? NSNumber {
							isFolder = (isDirectoryValue.boolValue && !isPackageValue.boolValue)
					}
					
					icon = wantsIcons ? collectedFilesSetting.copyValueForURLResourceKey(NSURLEffectiveIconKey, forCollectedFile: collectedFile) as? NSImage : nil
				}
			}
		}
		else {
			fatalError("Unknown GLAHighlightedItem type \(highlightedItem)")
		}
		
		return .Item(isGrouped: isGrouped, displayName: displayName, isFolder: isFolder, icon: icon, collection: collection)
	}
	
	public subscript(index: Int) -> HighlightItemSource {
		let ungroupedItemCount = ungroupedHighlightedItems.count
		
		// Ungrouped first
		if index < ungroupedItemCount {
			let highlightedItem = ungroupedHighlightedItems[index]
			return .Item(item: highlightedItem, isGrouped: false)
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
			
			if let groupItems = groupedCollectionUUIDsToItems[collection.UUID] {
				if index == groupedItemIndex {
					return .GroupedCollectionHeading(collection)
				}
				
				groupedItemIndex += 1
				
				if index < (groupedItemIndex + groupItems.count) {
					let highlightedItem = groupItems[index - groupedItemIndex]
					return .Item(item: highlightedItem, isGrouped: true)
				}
				
				groupedItemIndex += groupItems.count
			}
		}
		
		if project.groupHighlights {
			if index == groupedItemIndex && primaryFolders?.count > 0 {
				return .MasterFoldersHeading
			}
			
			groupedItemIndex += 1
		}
		
		// Master folders
		let masterFolderIndex = index - groupedItemIndex
		let collectedFolder = primaryFolders![masterFolderIndex]
		return .MasterFolder(collectedFolder)
	}
	
	public func detailsAtIndex(index: Int) -> HighlightItemDetails {
		switch self[index] {
		case let .Item(highlightedItem, isGrouped):
			return self.detailsForHighlightedItem(highlightedItem, isGrouped: isGrouped)
		case let .GroupedCollectionHeading(collection):
			return .GroupedCollectionHeading(collection)
		case .MasterFoldersHeading:
			return .MasterFoldersHeading
		case let .MasterFolder(collectedFolder):
			let displayName = self.collectedFilesSetting.copyValueForURLResourceKey(NSURLLocalizedNameKey, forCollectedFile: collectedFolder) as? String
			let icon = wantsIcons ? collectedFilesSetting.copyValueForURLResourceKey(NSURLEffectiveIconKey, forCollectedFile: collectedFolder) as? NSImage : nil
			
			return .MasterFolder(displayName: displayName, icon: icon)
		}
	}
	
	func fileURLAtIndex(index: Int) -> NSURL? {
		var collectedFile: GLACollectedFile?
		
		switch self[index] {
		case let .Item(highlightedItem, _):
			if let highlightedCollectedFile = highlightedItem as? GLAHighlightedCollectedFile {
				collectedFile = projectManager.collectedFileForHighlightedCollectedFile(highlightedCollectedFile, loadIfNeeded: true)
			}
		case let .MasterFolder(collectedFolder):
			collectedFile = collectedFolder
		default:
			return nil
		}
		
		return collectedFile?.accessFile().filePathURL
	}
	
	var details: AnyRandomAccessCollection<HighlightItemDetails> {
		return AnyRandomAccessCollection(lazy.map {
			switch $0 {
			case let .Item(highlightedItem, isGrouped):
				return self.detailsForHighlightedItem(highlightedItem, isGrouped: isGrouped)
			case let .GroupedCollectionHeading(collection):
				return .GroupedCollectionHeading(collection)
			case .MasterFoldersHeading:
				return .MasterFoldersHeading
			case let .MasterFolder(collectedFolder):
				let displayName = self.collectedFilesSetting.copyValueForURLResourceKey(NSURLLocalizedNameKey, forCollectedFile: collectedFolder) as? String
				let icon = self.wantsIcons ? self.collectedFilesSetting.copyValueForURLResourceKey(NSURLEffectiveIconKey, forCollectedFile: collectedFolder) as? NSImage : nil
				
				return .MasterFolder(displayName: displayName, icon: icon)
			}
		})
	}
	
	public func outputIndexesForTableRows(rowIndexes: NSIndexSet) -> NSIndexSet {
		let mutableIndexes = rowIndexes.mutableCopy() as! NSMutableIndexSet
		var itemIndex = 0;
		for highlightedItem in allHighlightedItems {
			// Advance over grouped items
			if highlightedItemIsGrouped(highlightedItem) {
				mutableIndexes.shiftIndexesStartingAtIndex(itemIndex, by: 1)
			}
			
			itemIndex += 1
		}
		
		return mutableIndexes
	}
}

extension ProjectHighlightsAssistant: CollectionType {
	public typealias Index = Int
	
	public var startIndex: Index {
		return 0
	}
	
	public var endIndex: Index {
		return itemCount
	}
	
	public func generate() -> IndexingGenerator<ProjectHighlightsAssistant> {
		return IndexingGenerator(self)
	}
}

extension ProjectHighlightsAssistant: GLAArrayTableDraggingHelperDelegate {
	public func arrayEditorTableDraggingHelper(tableDraggingHelper: GLAArrayTableDraggingHelper, canUseDraggingPasteboard draggingPasteboard: NSPasteboard) -> Bool {
		return GLAHighlightedCollectedFile.canCopyObjectsFromPasteboard(draggingPasteboard)
	}
	
	public func arrayEditorTableDraggingHelper(tableDraggingHelper: GLAArrayTableDraggingHelper, outputIndexesForTableRows rowIndexes: NSIndexSet) -> NSIndexSet {
		return outputIndexesForTableRows(rowIndexes)
	}
	
	public func arrayEditorTableDraggingHelper(tableDraggingHelper: GLAArrayTableDraggingHelper, makeChangesUsingEditingBlock editBlock: GLAArrayEditingBlock) {
		highlightedItemsUser.editChildrenUsingBlock(editBlock)
	}
}

extension ProjectHighlightsAssistant {
	func openItem(item: HighlightItemSource, withBehaviour behaviour: OpeningBehaviour, activateIfNeeded: Bool = false) {
		var needsActivation = false
		
		switch item {
		case let .Item(highlightedCollectedFile as GLAHighlightedCollectedFile, _):
			projectManager.openHighlightedCollectedFile(highlightedCollectedFile, behaviour: behaviour)
		case let .GroupedCollectionHeading(collection):
			navigator.goToCollection(collection)
			
			needsActivation = activateIfNeeded
		case .MasterFoldersHeading:
			navigator.editPrimaryFoldersOfProject(project)
			
			needsActivation = activateIfNeeded
		case let .MasterFolder(collectedFolder):
			projectManager.openCollectedFile(collectedFolder, behaviour: behaviour)
		default:
			break
		}
		
		if needsActivation {
			NSApp.activateIgnoringOtherApps(true)
		}
	}
	
	func openItem(atIndex index: Index, withBehaviour behaviour: OpeningBehaviour, activateIfNeeded: Bool = false) {
		openItem(self[index], withBehaviour: behaviour, activateIfNeeded: activateIfNeeded)
	}
	
	public var canOpenAllHighlights: Bool {
		return allHighlightedItems.count > 0
	}
	
	public func openAllHighlights(behaviour: OpeningBehaviour = .Default) {
		for highlightedItem in allHighlightedItems {
			if let highlightedCollectedFile = highlightedItem as? GLAHighlightedCollectedFile {
				projectManager.openHighlightedCollectedFile(highlightedCollectedFile, behaviour: behaviour)
			}
		}
	}
}
