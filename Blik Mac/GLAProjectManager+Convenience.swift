//
//  GLAProjectManager+Convenience.swift
//  Blik
//
//  Created by Patrick Smith on 21/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


func collectedFileUUIDForHighlightedItem(_ highlightedItem: Any!) -> AnyObject! {
	if let highlightedCollectedFile = highlightedItem as? GLAHighlightedCollectedFile {
		return highlightedCollectedFile.collectedFileUUID as AnyObject!
	}
	else {
		return nil
	}
}


public extension GLAProjectManager {
	public func filesAreAllCollected(_ fileURLs: [URL], inFilesListCollectionWithUUID filesListCollectionUUID: UUID) -> Bool {
		if fileURLs.count > 0 {
			let fileURLsNotYetCollected = filterFileURLs(fileURLs, notInFilesListCollectionWith: filesListCollectionUUID)
			return fileURLsNotYetCollected.count == 0
		}
		
		return false
	}
	
	public func addFiles(_ fileURLs: [URL], toFilesListCollectionWithUUID filesListCollectionUUID: UUID, projectUUID: UUID) {
		let collectedFiles = GLACollectedFile.collectedFiles(withFileURLs: fileURLs)
		
		if let filesListCollection = collection(with: filesListCollectionUUID, inProjectWith: projectUUID) {
			editFilesList(of: filesListCollection, insertingCollectedFiles:collectedFiles!, atOptionalIndex:UInt(NSNotFound))
		}
	}
	
	public func removeFiles(_ fileURLs: [URL], fromFilesListCollectionWithUUID filesListCollectionUUID: UUID, projectUUID: UUID) {
		if let filesListCollection = collection(with: filesListCollectionUUID, inProjectWith: projectUUID) {
			editFilesList(of: filesListCollection) { filesListEditor in
				let indexes = filesListEditor.indexesOfChildrenWhoseResult(fromVisitor: { child in
					let collectedFile = child as! GLACollectedFile
					return collectedFile.accessFile().filePathURL
					}, hasValueContainedIn: Set(fileURLs))
				filesListEditor.removeChildren(at: indexes)
			}
		}
	}
	
	// MARK:
	
	public func collectedFilesAreAllHighlighted(_ collectedFiles: [GLACollectedFile], fromCollectionWithUUID collectionUUID: UUID, projectUUID: UUID) -> Bool {
		if collectedFiles.count > 0 {
			let project = self.project(with: projectUUID)!
			let collectedFilesNotHighlighted = filterCollectedFiles(collectedFiles, notInHighlightsOf:project);
			return (collectedFilesNotHighlighted.count == 0)
		}
		
		return false
	}
	
	public func highlightCollectedFiles(_ collectedFiles: [GLACollectedFile], fromCollectionWithUUID collectionUUID: UUID, projectUUID: UUID) {
		var highlightedItems = [GLAHighlightedCollectedFile]()
		for collectedFile in collectedFiles {
			let highlightedCollectedFile = GLAHighlightedCollectedFile(byEditing: { editor in
				editor.holdingCollectionUUID = collectionUUID
				editor.projectUUID = projectUUID
				editor.collectedFileUUID = collectedFile.uuid
			})
			highlightedItems.append(highlightedCollectedFile)
		}
		
		editHighlightsOfProject(with: projectUUID) { highlightsEditor in
			let filteredItems = highlightsEditor.filterArray(highlightedItems, whoseResultFromVisitorIsNotAlreadyPresent: collectedFileUUIDForHighlightedItem)
			highlightsEditor.addChildren(filteredItems)
		}
	}
	
	public func unhighlightCollectedFiles(_ collectedFiles: [GLACollectedFile], projectUUID: UUID) {
		let collectedFileUUIDs = Set(collectedFiles.map { $0.uuid })
		
		editHighlightsOfProject(with: projectUUID) { highlightsEditor in
			let highlightedItemsIndexes = highlightsEditor.indexesOfChildrenWhoseResult(fromVisitor: collectedFileUUIDForHighlightedItem, hasValueContainedIn: collectedFileUUIDs)
			
			highlightsEditor.removeChildren(at: highlightedItemsIndexes)
		}
	}
}
