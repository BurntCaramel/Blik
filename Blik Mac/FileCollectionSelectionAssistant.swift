//
//  FileCollectionSelectionAssistant.swift
//  Blik
//
//  Created by Patrick Smith on 21/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntFoundation


@objc public final class FileCollectionSelectionAssistant: NSObject {
	public let source: FileCollectionSelectionSourcing
	public let filesListCollectionUUID: NSUUID
	public let projectUUID: NSUUID
	public let projectManager: GLAProjectManager
	
	public let openerApplicationCombiner = GLAFileOpenerApplicationFinder()
	
	public init(source: FileCollectionSelectionSourcing, filesListCollectionUUID: NSUUID, projectUUID: NSUUID, projectManager: GLAProjectManager) {
		self.source = source
		self.filesListCollectionUUID = filesListCollectionUUID
		self.projectUUID = projectUUID
		self.projectManager = projectManager
	}
	
	public func update() {
		openerApplicationCombiner.fileURLs = Set(source.selectedFileURLs)
	}
	
	public var isReadyToHighlight: Bool {
		if let project = projectManager.projectWithUUID(projectUUID) {
			return projectManager.hasLoadedHighlightsForProject(project)
		}
		
		return false
	}
	
	public var collectedFilesAreAllHighlighted: Bool {
		if let selectedCollectedFiles = source.collectedFileSource?.selectedCollectedFiles {
			return projectManager.collectedFilesAreAllHighlighted(selectedCollectedFiles, fromCollectionWithUUID: filesListCollectionUUID, projectUUID: projectUUID)
		}
		
		return false
	}
	
	public func addSelectedFilesToHighlights() {
		if let collectedFiles = source.collectedFileSource?.selectedCollectedFiles {
			projectManager.highlightCollectedFiles(collectedFiles, fromCollectionWithUUID: filesListCollectionUUID, projectUUID: projectUUID)
		}
	}
	
	public func removeSelectedFilesFromHighlights() {
		if let collectedFiles = source.collectedFileSource?.selectedCollectedFiles {
			projectManager.unhighlightCollectedFiles(collectedFiles, projectUUID: projectUUID)
		}
	}
	
	// MARK:
	
	public var selectedFilesAreAllCollected: Bool {
		let selectedFileURLs = source.selectedFileURLs
		println("selectedFileURLs \(selectedFileURLs)")
		if selectedFileURLs.count > 0 {
			let fileURLsNotYetCollected = projectManager.filterFileURLs(selectedFileURLs, notInFilesListCollectionWithUUID: filesListCollectionUUID)
			println("fileURLsNotYetCollected \(fileURLsNotYetCollected)")
			return fileURLsNotYetCollected.count == 0
		}
		
		return false
	}
	
	public func addSelectedFilesToCollection() {
		let fileURLs = source.selectedFileURLs
		let collectedFiles = GLACollectedFile.collectedFilesWithFileURLs(fileURLs)
		
		if let filesListCollection = projectManager.collectionWithUUID(filesListCollectionUUID, inProjectWithUUID: projectUUID) {
			projectManager.editFilesListOfCollection(filesListCollection, insertingCollectedFiles:collectedFiles, atOptionalIndex:UInt(NSNotFound))
		}
	}
	
	public func removeSelectedFilesFromCollection() {
		let fileURLs = source.selectedFileURLs
		
		if let filesListCollection = projectManager.collectionWithUUID(filesListCollectionUUID, inProjectWithUUID: projectUUID) {
			projectManager.editFilesListOfCollection(filesListCollection) { filesListEditor in
				let indexes = filesListEditor.indexesOfChildrenWhoseResultFromVisitor({ child in
					let collectedFile = child as! GLACollectedFile
					return collectedFile.accessFile().filePathURL
					}, hasValueContainedInSet: Set(fileURLs))
				filesListEditor.removeChildrenAtIndexes(indexes)
			}
		}
	}
}
