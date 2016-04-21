//
//  FileFilter.swift
//  Blik
//
//  Created by Patrick Smith on 26/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


enum FileSort {
	case name
	case dateModified
	case dateOpened
	
	var primarySpotlightAttribute: String {
		switch self {
		case .name: return kMDItemDisplayName as String
		case .dateModified: return kMDItemFSContentChangeDate as String
		case .dateOpened: return kMDItemLastUsedDate as String
		}
	}
	
	func updateSpotlightQuery(spotlightQuery: MDQuery, sortingAttributes: [String]) {
		var sortingAttributes = sortingAttributes
		let primaryAttribute = self.primarySpotlightAttribute
		
		if let index = sortingAttributes.indexOf(primaryAttribute) {
			sortingAttributes.removeAtIndex(index)
		}
		
		sortingAttributes.insert(primaryAttribute, atIndex: 0)
		
		MDQueryDisableUpdates(spotlightQuery)
		MDQuerySetSortOrder(spotlightQuery, sortingAttributes)
		MDQueryEnableUpdates(spotlightQuery)
	}
}


extension String {
	func escapeAsMetadataQuery() -> String {
		return self
			.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
			.stringByReplacingOccurrencesOfString("'", withString: "\'")
	}
}


struct FileFilterQuery {
	enum Kind {
		case any
		case folders(
			containingFileNamed: String?,
			pathNotContaining: String?
		)
		case images()
	}

	var kind: Kind
	var tagNames: [String]
	
	var fileMetadataQueryRepresentation: String {
		var parts = [String]()
		
		switch kind {
		case .any:
			break
		case .folders(_, _):
			parts.append("kMDItemContentType = \"\(kUTTypeFolder)\"")
		case .images:
			parts.append("kMDItemContentType = \"\(kUTTypeImage)\"")
		}
		
		if tagNames.count > 0 {
			parts.append(
				tagNames.map{ tagName in
					"kMDItemUserTags = \"\(tagName.escapeAsMetadataQuery())*\"cdwt"
				}.joinWithSeparator(" || ")
			)
		}
		
		return parts.joinWithSeparator(" && ")
	}
}


struct FileFilterRequest {
	var sourceFolderURLs: [NSURL]
	var query: FileFilterQuery
	var maxCount: Int = 10
	var attributes: [String]
	var sortingAttributes: [String]
	
	static var defaultAttributes: [String] = [kMDItemPath as String, kMDItemDisplayName as String, "kMDItemUserTags"]
	static var defaultSortingAttributes: [String] = [kMDItemLastUsedDate as String, kMDItemContentCreationDate as String, kMDItemFSContentChangeDate as String, kMDItemFSCreationDate as String]
	
	func createSpotlightQuery(sortedBy sortedBy: FileSort) -> MDQuery {
		let metadataQueryString = query.fileMetadataQueryRepresentation
		let spotlightQuery = MDQueryCreate(kCFAllocatorDefault, metadataQueryString, attributes, sortingAttributes)
		
		assert(spotlightQuery != nil, "Spotlight query must exist")
		
		// Folders
		let folderPaths = sourceFolderURLs.flatMap{ $0.path.map{ $0 as NSString } } as NSArray
		MDQuerySetSearchScope(spotlightQuery, folderPaths, 0)
		// Count
		MDQuerySetMaxCount(spotlightQuery, maxCount)
		// Sorting
		changeSpotlightQuery(spotlightQuery, sortedBy: sortedBy)
		
		return spotlightQuery
	}
	
	func changeSpotlightQuery(spotlightQuery: MDQuery, sortedBy: FileSort) {
		sortedBy.updateSpotlightQuery(spotlightQuery, sortingAttributes: sortingAttributes)
	}
}

class FileFilterFetcher {
	let request: FileFilterRequest
	let wantsItems: Bool
	var sortedBy: FileSort {
		didSet {
			guard let spotlightQuery = spotlightQuery else { return }
			request.changeSpotlightQuery(spotlightQuery, sortedBy: sortedBy)
		}
	}
	
	struct Item {
		var fileURL: NSURL?
		var displayName: String?
		var dateModified: NSDate?
		
		static private let attributeNames = [
			kMDItemPath,
			kMDItemDisplayName,
			kMDItemFSContentChangeDate
		]
		
		init(spotlightItem: MDItem) {
			let attributes = MDItemCopyAttributes(spotlightItem, Item.attributeNames) as NSDictionary
			func getAttribute<T>(key: CFString) -> T? {
				return attributes[key as String] as? T
			}
			
			fileURL = getAttribute(kMDItemPath).map{ NSURL(fileURLWithPath: $0) }
			displayName = getAttribute(kMDItemDisplayName)
			dateModified = getAttribute(kMDItemFSContentChangeDate)
		}
		
		static func copyItemsFromSpotlightQuery(spotlightQuery: MDQuery) -> [Item] {
			MDQueryDisableUpdates(spotlightQuery)
			
			let indexes = 0 ..< MDQueryGetResultCount(spotlightQuery)
			let items = indexes.map{ index -> Item in
				let spotlightItem = MDQueryGetResultAtIndex(spotlightQuery, index) as! MDItemRef
				
				return Item(spotlightItem: spotlightItem)
			}
			
			MDQueryEnableUpdates(spotlightQuery)
			
			return items
		}
	}
	
	enum Result {
		case count(Int)
		case items([Item])
	}
	
	struct Callbacks {
		var onProgress: (Result -> ())?
		var onUpdate: (Result -> ())?
	}
	let callbacks: Callbacks
	
	private var spotlightQuery: MDQuery?
	private var resultsQueue = GCDService.utility.queue
	private var progressObserver: PGWSCFNotificationObserver?
	private var updateObserver: PGWSCFNotificationObserver?
	
	init(request: FileFilterRequest, wantsItems: Bool, sortedBy: FileSort, callbacks: Callbacks) {
		self.request = request
		self.wantsItems = wantsItems
		self.sortedBy = sortedBy
		self.callbacks = callbacks
	}
	
	deinit {
		stopSearch()
	}
	
	func startSearch() {
		stopSearch()
		
		var spotlightQuery = request.createSpotlightQuery(sortedBy: sortedBy)
		let wantsItems = self.wantsItems
		
		let localNC = CFNotificationCenterGetLocalCenter()
		
		func resultsFromSpotlightQuery(spotlightQuery: MDQuery) -> Result {
			if wantsItems {
				return .items(Item.copyItemsFromSpotlightQuery(spotlightQuery))
			}
			else {
				return .count(MDQueryGetResultCount(spotlightQuery))
			}
		}
		
		if let onProgress = callbacks.onProgress {
			progressObserver = withUnsafePointer(&spotlightQuery) { pointer in
				PGWSCFNotificationObserver(
					center: localNC,
					block: { (_, _, _, userInfo) in
						print("SPOTLIGHT!")
						onProgress(resultsFromSpotlightQuery(spotlightQuery))
					},
					name: kMDQueryProgressNotification,
					object: pointer,
					suspensionBehavior: .Coalesce
				)
			}
		}
		
		if let onUpdate = callbacks.onUpdate {
			updateObserver = withUnsafePointer(&spotlightQuery) { pointer in
				PGWSCFNotificationObserver(
					center: localNC,
					block: { (_, _, _, userInfo) in
						onUpdate(resultsFromSpotlightQuery(spotlightQuery))
					},
					name: kMDQueryDidUpdateNotification,
					object: pointer,
					suspensionBehavior: .Coalesce
				)
			}
		}
		
		MDQuerySetDispatchQueue(spotlightQuery, resultsQueue)
		
		MDQueryExecute(spotlightQuery, CFOptionFlags(kMDQueryWantsUpdates.rawValue))
		
		self.spotlightQuery = spotlightQuery
	}
	
	func stopSearch() {
		guard let spotlightQuery = spotlightQuery else { return }
		
		progressObserver = nil
		updateObserver = nil
		
		MDQueryStop(spotlightQuery)
		self.spotlightQuery = nil
	}
}
