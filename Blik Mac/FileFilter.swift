//
//  FileFilter.swift
//  Blik
//
//  Created by Patrick Smith on 26/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


enum FileSort : String {
	case name = "name"
	case dateModified = "dateModified"
	case dateOpened = "dateOpened"
	
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
			containingFileNamed: String?
		)
		case images()
	}

	var kind: Kind
	var tagNames: [String]
	var pathNotContaining: String?
	
	var fileMetadataQueryRepresentation: String {
		var parts = [String]()
		
		switch kind {
		case .any:
			break
		case .folders(_):
			parts.append("\(kMDItemContentType) == \"\(kUTTypeFolder)\"")
		case .images:
			parts.append("\(kMDItemContentType) == \"\(kUTTypeImage)\"")
		}
		
		if tagNames.count > 0 {
			parts.append(
				tagNames.map{ tagName in
					"kMDItemUserTags == \"\(tagName.escapeAsMetadataQuery())*\"cdwt"
				}.joinWithSeparator(" || ")
			)
		}
		
		if let pathNotContaining = pathNotContaining where pathNotContaining != "" {
			parts.append("\(kMDItemPath) != \"*\(pathNotContaining.escapeAsMetadataQuery())*\"")
		}
		
		return parts.joinWithSeparator(" && ")
	}
}

extension FileFilterQuery {
	func taskForFilteringURLs(urls: [NSURL]) -> Task<[NSURL]> {
		switch kind {
		case let .folders(containingFileNamed):
			return FilesMatchStage.folders(folderURLs: urls, containingFileNamed: containingFileNamed).taskExecuting()!
		default:
			return Task{ urls }
		}
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
		print("metadataQueryString: \(metadataQueryString)")
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
	
	let wantsUpdates: Bool
	
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
				let spotlightItemPointer = MDQueryGetResultAtIndex(spotlightQuery, index)
				let spotlightItem = Unmanaged<MDItem>.fromOpaque(COpaquePointer(spotlightItemPointer)).takeUnretainedValue()
				
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
	
	enum UpdateKind {
		case progress
		case finish
		case update
	}
	
	let receiveResult: (result: Result, updateKind: UpdateKind) -> ()
	
	private var spotlightQuery: MDQuery?
	private var resultsQueue = GCDService.utility.queue
	private var progressObserver: PGWSCFNotificationObserver?
	private var finishObserver: PGWSCFNotificationObserver?
	private var updateObserver: PGWSCFNotificationObserver?
	
	init(request: FileFilterRequest, wantsItems: Bool, sortedBy: FileSort, wantsUpdates: Bool, receiveResult: (result: Result, updateKind: UpdateKind) -> ()) {
		self.request = request
		self.wantsItems = wantsItems
		self.sortedBy = sortedBy
		self.wantsUpdates = wantsUpdates
		self.receiveResult = receiveResult
	}
	
	deinit {
		stopSearch()
	}
	
	func startSearch() {
		stopSearch()
		
		let spotlightQuery = request.createSpotlightQuery(sortedBy: sortedBy)
		
		let localNC = CFNotificationCenterGetLocalCenter()
		let spotlightQueryPointer = UnsafePointer<MDQuery>(Unmanaged.passUnretained(spotlightQuery).toOpaque())
		
		let receiveResult = self.receiveResult
		
		progressObserver = PGWSCFNotificationObserver(
			center: localNC,
			block: { (_, _, _, userInfo) in
				print("SPOTLIGHT!")
				self.processResults(spotlightQuery) { result in
					receiveResult(result: result, updateKind: .progress)
				}
			},
			name: kMDQueryProgressNotification,
			object: spotlightQueryPointer,
			suspensionBehavior: .DeliverImmediately
		)
		
		finishObserver = PGWSCFNotificationObserver(
			center: localNC,
			block: { (_, _, _, userInfo) in
				self.processResults(spotlightQuery) { result in
					receiveResult(result: result, updateKind: .finish)
				}
			},
			name: kMDQueryDidFinishNotification,
			object: spotlightQueryPointer,
			suspensionBehavior: .DeliverImmediately
		)
		
		if wantsUpdates {
			updateObserver = PGWSCFNotificationObserver(
				center: localNC,
				block: { (_, _, _, userInfo) in
					self.processResults(spotlightQuery) { result in
						receiveResult(result: result, updateKind: .update)
					}
				},
				name: kMDQueryDidUpdateNotification,
				object: spotlightQueryPointer,
				suspensionBehavior: .DeliverImmediately
			)
		}
		
		MDQuerySetDispatchQueue(spotlightQuery, resultsQueue)
		
		MDQueryExecute(spotlightQuery, CFOptionFlags(kMDQueryWantsUpdates.rawValue))
		
		self.spotlightQuery = spotlightQuery
	}
	
	func processResults(spotlightQuery: MDQuery, receiver: (Result) -> ()) {
		if wantsItems {
			let items = Item.copyItemsFromSpotlightQuery(spotlightQuery)
			let urls = items.flatMap{ $0.fileURL }
			request.query.taskForFilteringURLs(urls).perform{ useResult in
				do {
					let filteredURLs = Set(try useResult())
					let items = items.filter{
						$0.fileURL.map{ filteredURLs.contains($0) } ?? false
					}
					receiver(.items(items))
				}
				catch {
					receiver(.items([]))
				}
			}
		}
		else {
			receiver(.count(MDQueryGetResultCount(spotlightQuery)))
		}
	}
	
	func stopSearch() {
		guard let spotlightQuery = spotlightQuery else { return }
		
		progressObserver = nil
		updateObserver = nil
		
		MDQueryStop(spotlightQuery)
		self.spotlightQuery = nil
	}
}
