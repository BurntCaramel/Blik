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
	case MasterFolder(GLACollectedFile)
}

public enum HighlightItemDetails {
	case Item(isGrouped: Bool, displayName: String?, isFolder: Bool?, collection: GLACollection?)
	case GroupedCollectionHeading(GLACollection)
	case MasterFolder(displayName: String?)
}

@objc public class ProjectHighlightsAssistant: NSObject {
	let project: GLAProject
	let projectManager: GLAProjectManager
	
	private let collectedFilesSetting: GLACollectedFilesSetting
	private let collectedFilesSettingObserver: AnyNotificationObserver
	
	let highlightedItemsUser: GLALoadableArrayUsing!
	var ungroupedHighlightedItems: [GLAHighlightedItem]!
	var allHighlightedItems: [GLAHighlightedItem]!
	
	let collectionsUser: GLALoadableArrayUsing!
	var collections: [GLACollection]!
	var groupedCollectionUUIDs: Set<NSUUID>!
	var groupedCollectionUUIDsToItems: [NSUUID: [GLAHighlightedItem]]!
	
	let primaryFoldersUser: GLALoadableArrayUsing!
	var primaryFolders: [GLACollectedFile]?
	
	private var collectionObservers: [AnyObject]?
	
	public var changesNotifier: (() -> ())?
	
	init(project: GLAProject, projectManager: GLAProjectManager) {
		self.project = project
		self.projectManager = projectManager
		highlightedItemsUser = projectManager.useHighlightsForProject(project)
		collectionsUser = projectManager.useCollectionsForProject(project)
		primaryFoldersUser = projectManager.usePrimaryFoldersForProject(project)
		
		collectedFilesSetting = GLACollectedFilesSetting()
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
		let allHighlightedItems = highlightedItemsUser.copyChildrenLoadingIfNeeded() as? [GLAHighlightedItem] ?? []
		let collections = collectionsUser.copyChildrenLoadingIfNeeded() as? [GLACollection] ?? []
		let primaryFolders = primaryFoldersUser.copyChildrenLoadingIfNeeded() as? [GLACollectedFile] ?? []
		
		self.collections = collections
		
		let groupedCollectionUUIDs = Set<NSUUID>(collections.lazy.filter({ $0.highlighted }).map({ $0.UUID }))
		self.groupedCollectionUUIDs = groupedCollectionUUIDs
		
		var groupedHighlightedItems = [GLAHighlightedItem]()
		var ungroupedHighlightedItems = [GLAHighlightedItem]()
		for highlightedItem in allHighlightedItems {
			if highlightedItemIsGrouped(highlightedItem) {
				groupedHighlightedItems.append(highlightedItem)
			}
			else {
				ungroupedHighlightedItems.append(highlightedItem)
			}
		}
		self.ungroupedHighlightedItems = ungroupedHighlightedItems
		self.allHighlightedItems = allHighlightedItems
		
		var groupedCollectionUUIDsToItems = [NSUUID: [GLAHighlightedItem]]()
		for highlightedItem in allHighlightedItems {
			let collectionUUID = highlightedItem.holdingCollectionUUID
			if groupedCollectionUUIDs.contains(collectionUUID) {
				var groupItems = groupedCollectionUUIDsToItems[collectionUUID] ?? [GLAHighlightedItem]()
				groupedCollectionUUIDsToItems[collectionUUID] = nil
				groupItems.append(highlightedItem)
				groupedCollectionUUIDsToItems[collectionUUID] = groupItems
			}
		}
		self.groupedCollectionUUIDsToItems = groupedCollectionUUIDsToItems
		
		
		self.primaryFolders = primaryFolders
		
		
		var allCollectedFiles = [GLACollectedFile]()
		allCollectedFiles.appendContentsOf(
			allHighlightedItems.lazy.map({ self.collectedFileForHighlightedItem($0) }).filter({ $0 != nil }).map({ $0! })
		)
		allCollectedFiles.appendContentsOf(primaryFolders)
		
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
		
		let collectionUUIDs = Set<NSUUID>(ungroupedHighlightedItems.lazy.map({ $0.holdingCollectionUUID }))
		
		let notificationBlock: (NSNotification) -> () = { [weak self] _ in
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
		}
		
		//addObserverForName(GLAProjectCollectionsDidChangeNotification, object: pm.notificationObjectForProjectUUID(project.UUID))
		
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
		count += primaryFolders?.count ?? 0
		
		// For collection group headers
		count += groupedCollectionUUIDsToItems.count
		
		return count
	}
	
	var hasUngroupedItems: Bool {
		return ungroupedHighlightedItems.count > 0
	}
	
	private func detailsForHighlightedItem(highlightedItem: GLAHighlightedItem, isGrouped: Bool) -> HighlightItemDetails {
		var displayName: String?
		var isFolder: Bool?
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
							isFolder = (true == isDirectoryValue && false == isPackageValue)
					}
				}
			}
		}
		else {
			fatalError("Unknown GLAHighlightedItem type \(highlightedItem)")
		}
		
		return .Item(isGrouped: isGrouped, displayName: displayName, isFolder: isFolder, collection: collection)
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
			if !collection.highlighted {
				continue;
			}
			
			if let groupItems = groupedCollectionUUIDsToItems[collection.UUID] {
				if index == groupedItemIndex {
					return .GroupedCollectionHeading(collection)
				}
				
				groupedItemIndex++
				
				if index < (groupedItemIndex + groupItems.count) {
					let highlightedItem = groupItems[index - groupedItemIndex]
					return .Item(item: highlightedItem, isGrouped: true)
				}
				
				groupedItemIndex += groupItems.count
			}
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
		case let .MasterFolder(collectedFolder):
			let displayName = self.collectedFilesSetting.copyValueForURLResourceKey(NSURLLocalizedNameKey, forCollectedFile: collectedFolder) as? String
			
			return .MasterFolder(displayName: displayName)
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
		return AnyRandomAccessCollection(self.lazy.map {
			switch $0 {
			case let .Item(highlightedItem, isGrouped):
				return self.detailsForHighlightedItem(highlightedItem, isGrouped: isGrouped)
			case let .GroupedCollectionHeading(collection):
				return .GroupedCollectionHeading(collection)
			case let .MasterFolder(collectedFolder):
				let displayName = self.collectedFilesSetting.copyValueForURLResourceKey(NSURLLocalizedNameKey, forCollectedFile: collectedFolder) as? String
				
				return .MasterFolder(displayName: displayName)
			}
		})
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
	
	public func arrayEditorTableDraggingHelper(tableDraggingHelper: GLAArrayTableDraggingHelper, makeChangesUsingEditingBlock editBlock: GLAArrayEditingBlock) {
		highlightedItemsUser.editChildrenUsingBlock(editBlock)
	}
	
	public func arrayEditorTableDraggingHelper(tableDraggingHelper: GLAArrayTableDraggingHelper, outputIndexesForTableRows rowIndexes: NSIndexSet) -> NSIndexSet {
		let mutableIndexes = rowIndexes.mutableCopy() as! NSMutableIndexSet
		var itemIndex = 0;
		for highlightedItem in allHighlightedItems {
			if highlightedItemIsGrouped(highlightedItem) {
				mutableIndexes.shiftIndexesStartingAtIndex(itemIndex, by: 1)
			}
			
			itemIndex++
		}
		
		return mutableIndexes
	}
}
