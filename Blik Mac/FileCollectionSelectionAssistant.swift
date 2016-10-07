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
	public let filesListCollectionUUID: UUID
	public let projectUUID: UUID
	public let projectManager: GLAProjectManager
	
	public let openerApplicationCombiner = GLAFileOpenerApplicationFinder()
	
	var projectObserver: AnyNotificationObserver
	
	public init(source: FileCollectionSelectionSourcing, filesListCollectionUUID: UUID, projectUUID: UUID, projectManager: GLAProjectManager) {
		self.source = source
		self.filesListCollectionUUID = filesListCollectionUUID
		self.projectUUID = projectUUID
		self.projectManager = projectManager
		
		projectObserver = AnyNotificationObserver(object: projectManager.notificationObject(forProjectUUID: projectUUID) as AnyObject)
		
		super.init()
		
		observeProject()
	}
	
	fileprivate func observeProject() {
		projectObserver.observe(NSNotification.Name.GLAProjectHighlightsDidChange.rawValue) { [weak self] notification in
			self?.update()
		}
	}
	
	enum Notification: String {
		case DidUpdate = "FileCollectionSelectionAssistantDidUpdateNotification"
	}
	
	internal func notify(_ notificationIdentifier: Notification) {
		NotificationCenter.default.postNotification(notificationIdentifier, object: self, userInfo: nil)
	}
	
	public func update() {
		openerApplicationCombiner.fileURLs = Set(source.selectedFileURLs)
		
		notify(.DidUpdate)
	}
	
	// MARK:
	
	public var isReadyToHighlight: Bool {
		if let project = projectManager.project(with: projectUUID) {
			projectManager.loadHighlights(forProjectIfNeeded: project)
			
			return projectManager.hasLoadedHighlights(for: project)
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
		if selectedFileURLs.count > 0 {
			let fileURLsNotYetCollected = projectManager.filterFileURLs(selectedFileURLs, notInFilesListCollectionWith: filesListCollectionUUID)
			return fileURLsNotYetCollected.count == 0
		}
		
		return false
	}
	
	public func addSelectedFilesToCollection() {
		let fileURLs = source.selectedFileURLs
		let collectedFiles = GLACollectedFile.collectedFiles(withFileURLs: fileURLs)
		
		if let filesListCollection = projectManager.collection(with: filesListCollectionUUID, inProjectWith: projectUUID) {
			projectManager.editFilesList(of: filesListCollection, insertingCollectedFiles:collectedFiles, atOptionalIndex:UInt(NSNotFound))
		}
	}
	
	public func removeSelectedFilesFromCollection() {
		let fileURLs = source.selectedFileURLs
		
		if let filesListCollection = projectManager.collection(with: filesListCollectionUUID, inProjectWith: projectUUID) {
			projectManager.editFilesList(of: filesListCollection) { filesListEditor in
				let indexes = filesListEditor.indexesOfChildrenWhoseResult(fromVisitor: { child in
					let collectedFile = child as! GLACollectedFile
					return collectedFile.accessFile()?.filePathURL
					}, hasValueContainedIn: Set(fileURLs))
				filesListEditor.removeChildren(at: indexes)
			}
		}
	}
}
