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
	
	func updateSpotlightQuery(_ spotlightQuery: MDQuery, sortingAttributes: [String]) {
		var sortingAttributes = sortingAttributes
		let primaryAttribute = self.primarySpotlightAttribute
		
		if let index = sortingAttributes.index(of: primaryAttribute) {
			sortingAttributes.remove(at: index)
		}
		
		sortingAttributes.insert(primaryAttribute, at: 0)
		
		MDQueryDisableUpdates(spotlightQuery)
		MDQuerySetSortOrder(spotlightQuery, sortingAttributes as CFArray!)
		MDQueryEnableUpdates(spotlightQuery)
	}
}


extension String {
	func escapeAsMetadataQuery() -> String {
		return self
			.replacingOccurrences(of: "\"", with: "\\\"")
			.replacingOccurrences(of: "'", with: "\'")
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
				}.joined(separator: " || ")
			)
		}
		
		if let pathNotContaining = pathNotContaining , pathNotContaining != "" {
			parts.append("\(kMDItemPath) != \"*\(pathNotContaining.escapeAsMetadataQuery())*\"")
		}
		
		return parts.joined(separator: " && ")
	}
}

extension FileFilterQuery {
	func taskForFilteringURLs(_ urls: [URL]) -> Deferred<[URL]> {
		switch kind {
		case let .folders(containingFileNamed):
      let stage = FilesMatchStage.folders(folderURLs: urls, containingFileNamed: containingFileNamed)
			return stage.taskExecuting(GCDService.utility)
		default:
			return .unit{ urls }
		}
	}
}


struct FileFilterRequest {
	var sourceFolderURLs: [URL]
	var query: FileFilterQuery
	var maxCount: Int = 10
	var attributes: [String]
	var sortingAttributes: [String]
	
	static var defaultAttributes: [String] = [kMDItemPath as String, kMDItemDisplayName as String, "kMDItemUserTags"]
	static var defaultSortingAttributes: [String] = [kMDItemLastUsedDate as String, kMDItemContentCreationDate as String, kMDItemFSContentChangeDate as String, kMDItemFSCreationDate as String]
	
	func createSpotlightQuery(sortedBy: FileSort) -> MDQuery {
		let metadataQueryString = query.fileMetadataQueryRepresentation
		print("metadataQueryString: \(metadataQueryString)")
		let spotlightQuery = MDQueryCreate(kCFAllocatorDefault, metadataQueryString as CFString!, attributes as CFArray!, sortingAttributes as CFArray!)
		
		assert(spotlightQuery != nil, "Spotlight query must exist")
		
		// Folders
		let folderPaths = sourceFolderURLs.flatMap{ $0.path } as NSArray
		MDQuerySetSearchScope(spotlightQuery, folderPaths, 0)
		// Count
		MDQuerySetMaxCount(spotlightQuery, maxCount)
		// Sorting
		changeSpotlightQuery(spotlightQuery!, sortedBy: sortedBy)
		
		return spotlightQuery!
	}
	
	func changeSpotlightQuery(_ spotlightQuery: MDQuery, sortedBy: FileSort) {
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
		var fileURL: URL?
		var displayName: String?
		var dateModified: Date?
		
		static fileprivate let attributeNames = [
			kMDItemPath,
			kMDItemDisplayName,
			kMDItemFSContentChangeDate
		]
		
		init(spotlightItem: MDItem) {
			let attributes = MDItemCopyAttributes(spotlightItem, Item.attributeNames as CFArray!) as NSDictionary
			func getAttribute<T>(_ key: CFString) -> T? {
				return attributes[key as String] as? T
			}
			
			fileURL = getAttribute(kMDItemPath).map{ URL(fileURLWithPath: $0) }
			displayName = getAttribute(kMDItemDisplayName)
			dateModified = getAttribute(kMDItemFSContentChangeDate)
		}
		
		static func copyItemsFromSpotlightQuery(_ spotlightQuery: MDQuery) -> [Item] {
			MDQueryDisableUpdates(spotlightQuery)
			
			let indexes = 0 ..< MDQueryGetResultCount(spotlightQuery)
			let items = indexes.map{ index -> Item in
				let spotlightItemPointer = MDQueryGetResultAtIndex(spotlightQuery, index)!
				let spotlightItem = Unmanaged<MDItem>.fromOpaque(spotlightItemPointer).takeUnretainedValue()
				
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
	
	let receiveResult: (_ result: Result, _ updateKind: UpdateKind) -> ()
	
	fileprivate var spotlightQuery: MDQuery?
	fileprivate var resultsQueue = GCDService.utility.queue
	fileprivate var progressObserver: PGWSCFNotificationObserver?
	fileprivate var finishObserver: PGWSCFNotificationObserver?
	fileprivate var updateObserver: PGWSCFNotificationObserver?
	
	init(request: FileFilterRequest, wantsItems: Bool, sortedBy: FileSort, wantsUpdates: Bool, receiveResult: @escaping (_ result: Result, _ updateKind: UpdateKind) -> ()) {
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
		let spotlightQueryPointer = Unmanaged.passUnretained(spotlightQuery).toOpaque()
		
		let receiveResult = self.receiveResult
		
		progressObserver = PGWSCFNotificationObserver(
			center: localNC,
			block: { (_, _, _, userInfo) in
				print("SPOTLIGHT!")
				self.processResults(spotlightQuery) { result in
					receiveResult(result, .progress)
				}
			},
			name: kMDQueryProgressNotification,
			object: spotlightQueryPointer,
			suspensionBehavior: .deliverImmediately
		)
		
		finishObserver = PGWSCFNotificationObserver(
			center: localNC,
			block: { (_, _, _, userInfo) in
				self.processResults(spotlightQuery) { result in
					receiveResult(result, .finish)
				}
			},
			name: kMDQueryDidFinishNotification,
			object: spotlightQueryPointer,
			suspensionBehavior: .deliverImmediately
		)
		
		if wantsUpdates {
			updateObserver = PGWSCFNotificationObserver(
				center: localNC,
				block: { (_, _, _, userInfo) in
					self.processResults(spotlightQuery) { result in
						receiveResult(result, .update)
					}
				},
				name: kMDQueryDidUpdateNotification,
				object: spotlightQueryPointer,
				suspensionBehavior: .deliverImmediately
			)
		}
		
		MDQuerySetDispatchQueue(spotlightQuery, resultsQueue)
		
		MDQueryExecute(spotlightQuery, CFOptionFlags(kMDQueryWantsUpdates.rawValue))
		
		self.spotlightQuery = spotlightQuery
	}
	
	func processResults(_ spotlightQuery: MDQuery, receiver: @escaping (Result) -> ()) {
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
