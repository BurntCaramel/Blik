//
//  SymlinkCreator.swift
//  Blik
//
//  Created by Patrick Smith on 11/06/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


let workDispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)


public class SymlinkCreator {
	let holdingDirectoryURL: NSURL
	let projectManager: GLAProjectManager
	private var modelUsers = [GLALoadableArrayUsing]()
	
	private let fileManager: NSFileManager
	private let fileOperationQueue: dispatch_queue_t
	
	init(holdingDirectoryURL: NSURL, projectManager: GLAProjectManager = GLAProjectManager.sharedProjectManager()) {
		self.holdingDirectoryURL = holdingDirectoryURL
		self.projectManager = projectManager
		self.fileManager = NSFileManager()
		self.fileOperationQueue = dispatch_queue_create("SymlinkCreator.fileOperationQueue", DISPATCH_QUEUE_SERIAL)
	}
	
	public func createLinks() {
		self.createLinksForAllProjectsInDirectoryURL(self.holdingDirectoryURL)
	}
	
	private func useFileManagerInBackground(closure: (fileManager: NSFileManager) -> Void) {
		let fileManager = self.fileManager
		dispatch_async(fileOperationQueue) {
			closure(fileManager: fileManager)
		}
	}
	
	private var allProjectsUser: GLALoadableArrayUsing?
	private func useAllProjects() -> GLALoadableArrayUsing {
		if let allProjectsUser = (self.allProjectsUser) {
			return allProjectsUser
		}
		else {
			let pm = projectManager
			let allProjectsUser = pm.useAllProjects()
			
			allProjectsUser.changeCompletionBlock = { [weak self] inspectableArray in
				self?.projectsDidChange()
			}
			
			self.allProjectsUser = allProjectsUser
			
			return allProjectsUser
		}
	}
	
	private func removeContentsOfDirectoryWithURL(directoryURL: NSURL) {
		let holdingDirectoryURL = self.holdingDirectoryURL
		useFileManagerInBackground { fileManager in
			do {
				let existingURLs = try fileManager.contentsOfDirectoryAtURL(holdingDirectoryURL, includingPropertiesForKeys: nil, options: .SkipsSubdirectoryDescendants)
				for existingURL in existingURLs {
					do {
						try fileManager.removeItemAtURL(existingURL)
					}
				}
			}
			catch {
				NSLog("%@", error as NSError)
			}
		}
	}
	
	private func projectsDidChange() {
		removeContentsOfDirectoryWithURL(holdingDirectoryURL)
		createLinksForAllProjectsInDirectoryURL(holdingDirectoryURL)
	}
	
	private func createDirectoryAtURL(directoryURL: NSURL) {
		useFileManagerInBackground { fileManager in
			do {
				try fileManager.createDirectoryAtURL(directoryURL, withIntermediateDirectories: true, attributes: nil)
			}
			catch {
				NSLog("%@", error as NSError)
			}
		}
	}
	
	private func createLinksForAllProjectsInDirectoryURL(holdingDirectoryURL: NSURL) {
		let projectsUser = useAllProjects()
		
		projectsUser.whenLoaded { projectsInspector in
			let projects = projectsInspector.copyChildren() as! [GLAProject]
			for project in projects {
				let projectDirectoryURL = holdingDirectoryURL.URLByAppendingPathComponent(project.name)
				self.createDirectoryAtURL(projectDirectoryURL)
				
				self.createLinksForProjectWithUUID(project.UUID, inDirectoryURL: projectDirectoryURL)
			}
			
			#if DEBUG
				self.useFileManagerInBackground { (fileManager) in
					print("Created symlinks for all projects")
				}
			#endif
		}
	}
	
	private func createLinksForProjectWithUUID(projectUUID: NSUUID, inDirectoryURL holdingDirectoryURL: NSURL) {
		let pm = projectManager
		let project = pm.projectWithUUID(projectUUID)!
		
		let collectionsUser = pm.useCollectionsForProject(project)
		modelUsers.append(collectionsUser)
		
		collectionsUser.whenLoaded { collectionsInspector in
			let collections = collectionsInspector.copyChildren() as! [GLACollection]
			
			for collection in collections {
				let collectionDirectoryURL = holdingDirectoryURL.URLByAppendingPathComponent(collection.name)
				self.createDirectoryAtURL(collectionDirectoryURL)
				
				self.createLinksForFilesListCollection(collection, inDirectoryURL: collectionDirectoryURL)
			}
		}
	}
	
	private func createLinksForFilesListCollection(collection: GLACollection, inDirectoryURL holdingDirectoryURL: NSURL) {
		
		let pm = projectManager
		
		let filesListUser = pm.useFilesListForCollection(collection)
		modelUsers.append(filesListUser)
		
		filesListUser.whenLoaded { filesListInspector in
			let filesList = filesListInspector.copyChildren() as! [GLACollectedFile]
			
			self.useFileManagerInBackground { fileManager in
				for collectedFile in filesList {
					let accessedFile = collectedFile.accessFile()
					if let
						filePathURL = accessedFile.filePathURL,
						fileName = filePathURL.lastPathComponent
					{
						let linkURL = holdingDirectoryURL.URLByAppendingPathComponent(fileName)
						do {
							try fileManager.createSymbolicLinkAtURL(linkURL, withDestinationURL: filePathURL)
						}
						catch {
							NSOperationQueue.mainQueue().addOperationWithBlock {
								NSApp.presentError(error as NSError)
							}
						}
					}
				}
			}
		}
	}
}

extension SymlinkCreator {
	public class func chooseFolderAndCreateSymlinks(completion: (SymlinkCreator) -> Void) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseDirectories = true
		openPanel.canChooseFiles = false
		openPanel.canCreateDirectories = true
		openPanel.allowsMultipleSelection = false
		openPanel.level = Int(CGWindowLevelForKey(CGWindowLevelKey.FloatingWindowLevelKey))
		
		openPanel.beginWithCompletionHandler { result in
			if result == NSFileHandlingPanelOKButton {
				let fileURL = openPanel.URLs[0]
				let symlinkCreator = SymlinkCreator(holdingDirectoryURL: fileURL)
				completion(symlinkCreator)
			}
		}
	}
}
