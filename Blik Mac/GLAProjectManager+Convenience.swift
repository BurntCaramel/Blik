//
//  GLAProjectManager+Convenience.swift
//  Blik
//
//  Created by Patrick Smith on 21/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


func collectedFileUUIDForHighlightedItem(highlightedItem: AnyObject!) -> AnyObject! {
	if let highlightedCollectedFile = highlightedItem as? GLAHighlightedCollectedFile {
		return highlightedCollectedFile.collectedFileUUID
	}
	else {
		return nil
	}
}


public extension GLAProjectManager {
	public func filesAreAllCollected(fileURLs: [NSURL], inFilesListCollectionWithUUID filesListCollectionUUID: NSUUID) -> Bool {
		if fileURLs.count > 0 {
			let fileURLsNotYetCollected = filterFileURLs(fileURLs, notInFilesListCollectionWithUUID: filesListCollectionUUID)
			return fileURLsNotYetCollected.count == 0
		}
		
		return false
	}
	
	public func addFiles(fileURLs: [NSURL], toFilesListCollectionWithUUID filesListCollectionUUID: NSUUID, projectUUID: NSUUID) {
		let collectedFiles = GLACollectedFile.collectedFilesWithFileURLs(fileURLs)
		
		if let filesListCollection = collectionWithUUID(filesListCollectionUUID, inProjectWithUUID: projectUUID) {
			editFilesListOfCollection(filesListCollection, insertingCollectedFiles:collectedFiles, atOptionalIndex:UInt(NSNotFound))
		}
	}
	
	public func removeFiles(fileURLs: [NSURL], fromFilesListCollectionWithUUID filesListCollectionUUID: NSUUID, projectUUID: NSUUID) {
		if let filesListCollection = collectionWithUUID(filesListCollectionUUID, inProjectWithUUID: projectUUID) {
			editFilesListOfCollection(filesListCollection) { filesListEditor in
				let indexes = filesListEditor.indexesOfChildrenWhoseResultFromVisitor({ child in
					let collectedFile = child as! GLACollectedFile
					return collectedFile.accessFile().filePathURL
					}, hasValueContainedInSet: Set(fileURLs))
				filesListEditor.removeChildrenAtIndexes(indexes)
			}
		}
	}
	
	// MARK:
	
	public func collectedFilesAreAllHighlighted(collectedFiles: [GLACollectedFile], fromCollectionWithUUID collectionUUID: NSUUID, projectUUID: NSUUID) -> Bool {
		if collectedFiles.count > 0 {
			let project = projectWithUUID(projectUUID)!
			var collectedFilesNotHighlighted = filterCollectedFiles(collectedFiles, notInHighlightsOfProject:project);
			return (collectedFilesNotHighlighted.count == 0)
		}
		
		return false
	}
	
	public func highlightCollectedFiles(collectedFiles: [GLACollectedFile], fromCollectionWithUUID collectionUUID: NSUUID, projectUUID: NSUUID) {
		var highlightedItems = [GLAHighlightedCollectedFile]()
		for collectedFile in collectedFiles {
			let highlightedCollectedFile = GLAHighlightedCollectedFile(byEditing: { editor in
				editor.holdingCollectionUUID = collectionUUID
				editor.projectUUID = projectUUID
				editor.collectedFileUUID = collectedFile.UUID
			})
			highlightedItems.append(highlightedCollectedFile)
		}
		
		editHighlightsOfProjectWithUUID(projectUUID) { highlightsEditor in
			let filteredItems = highlightsEditor.filterArray(highlightedItems, whoseResultFromVisitorIsNotAlreadyPresent: collectedFileUUIDForHighlightedItem)
			highlightsEditor.addChildren(filteredItems)
		}
	}
	
	public func unhighlightCollectedFiles(collectedFiles: [GLACollectedFile], projectUUID: NSUUID) {
		let collectedFileUUIDs = Set(collectedFiles.map { $0.UUID })
		
		editHighlightsOfProjectWithUUID(projectUUID) { highlightsEditor in
			let highlightedItemsIndexes = highlightsEditor.indexesOfChildrenWhoseResultFromVisitor(collectedFileUUIDForHighlightedItem, hasValueContainedInSet: collectedFileUUIDs)
			
			highlightsEditor.removeChildrenAtIndexes(highlightedItemsIndexes)
		}
	}
}
