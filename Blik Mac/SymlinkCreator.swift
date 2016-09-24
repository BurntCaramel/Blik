//
//  SymlinkCreator.swift
//  Blik
//
//  Created by Patrick Smith on 11/06/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


open class SymlinkCreator {
	let holdingDirectoryURL: URL
	let projectManager: GLAProjectManager
	fileprivate var modelUsers = [GLALoadableArrayUsing]()
	
	fileprivate let fileManager: FileManager
	fileprivate let fileOperationQueue: DispatchQueue
	
	init(holdingDirectoryURL: URL, projectManager: GLAProjectManager = GLAProjectManager.shared()) {
		self.holdingDirectoryURL = holdingDirectoryURL
		self.projectManager = projectManager
		self.fileManager = FileManager()
		self.fileOperationQueue = DispatchQueue(label: "SymlinkCreator.fileOperationQueue", attributes: [])
	}
	
	open func createLinks() {
		self.createLinksForAllProjectsInDirectoryURL(self.holdingDirectoryURL)
	}
	
	fileprivate func useFileManagerInBackground(_ closure: @escaping (_ fileManager: FileManager) -> Void) {
		let fileManager = self.fileManager
		fileOperationQueue.async {
			closure(fileManager)
		}
	}
	
	fileprivate var allProjectsUser: GLALoadableArrayUsing?
	fileprivate func useAllProjects() -> GLALoadableArrayUsing {
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
	
	fileprivate func removeContentsOfDirectoryWithURL(_ directoryURL: URL) {
		let holdingDirectoryURL = self.holdingDirectoryURL
		useFileManagerInBackground { fileManager in
			do {
				let existingURLs = try fileManager.contentsOfDirectory(at: holdingDirectoryURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
				for existingURL in existingURLs {
					do {
						try fileManager.removeItem(at: existingURL)
					}
				}
			}
			catch {
				NSLog("%@", error as NSError)
			}
		}
	}
	
	fileprivate func projectsDidChange() {
		removeContentsOfDirectoryWithURL(holdingDirectoryURL)
		createLinksForAllProjectsInDirectoryURL(holdingDirectoryURL)
	}
	
	fileprivate func createDirectoryAtURL(_ directoryURL: URL) {
		useFileManagerInBackground { fileManager in
			do {
				try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
			}
			catch {
				NSLog("%@", error as NSError)
			}
		}
	}
	
	fileprivate func createLinksForAllProjectsInDirectoryURL(_ holdingDirectoryURL: URL) {
		let projectsUser = useAllProjects()
		
		projectsUser.whenLoaded { projectsInspector in
			let projects = projectsInspector.copyChildren() as! [GLAProject]
			for project in projects {
				let projectDirectoryURL = holdingDirectoryURL.appendingPathComponent(project.name)
				self.createDirectoryAtURL(projectDirectoryURL)
				
				self.createLinksForProjectWithUUID(project.uuid, inDirectoryURL: projectDirectoryURL)
			}
			
			#if DEBUG
				self.useFileManagerInBackground { (fileManager) in
					print("Created symlinks for all projects")
				}
			#endif
		}
	}
	
	fileprivate func createLinksForProjectWithUUID(_ projectUUID: UUID, inDirectoryURL holdingDirectoryURL: URL) {
		let pm = projectManager
		let project = pm.project(with: projectUUID)!
		
		let collectionsUser = pm.useCollections(for: project)
		modelUsers.append(collectionsUser)
		
		collectionsUser.whenLoaded { collectionsInspector in
			let collections = collectionsInspector.copyChildren() as! [GLACollection]
			
			for collection in collections {
				let collectionDirectoryURL = holdingDirectoryURL.appendingPathComponent(collection.name)
				self.createDirectoryAtURL(collectionDirectoryURL)
				
				self.createLinksForFilesListCollection(collection, inDirectoryURL: collectionDirectoryURL)
			}
		}
	}
	
	fileprivate func createLinksForFilesListCollection(_ collection: GLACollection, inDirectoryURL holdingDirectoryURL: URL) {
		
		let pm = projectManager
		
		let filesListUser = pm.useFilesList(for: collection)
		modelUsers.append(filesListUser)
		
		filesListUser.whenLoaded { filesListInspector in
			let filesList = filesListInspector.copyChildren() as! [GLACollectedFile]
			
			self.useFileManagerInBackground { fileManager in
				for collectedFile in filesList {
					let accessedFile = collectedFile.accessFile()
					if let filePathURL = accessedFile?.filePathURL {
            let fileName = filePathURL.lastPathComponent
						let linkURL = holdingDirectoryURL.appendingPathComponent(fileName)
						do {
              try fileManager.createSymbolicLink(at: linkURL, withDestinationURL: filePathURL)
						}
						catch {
							OperationQueue.main.addOperation {
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
	public class func chooseFolderAndCreateSymlinks(_ completion: @escaping (SymlinkCreator) -> Void) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseDirectories = true
		openPanel.canChooseFiles = false
		openPanel.canCreateDirectories = true
		openPanel.allowsMultipleSelection = false
		openPanel.level = Int(CGWindowLevelForKey(CGWindowLevelKey.floatingWindow))
		
		openPanel.begin { result in
			if result == NSFileHandlingPanelOKButton {
				let fileURL = openPanel.urls[0]
				let symlinkCreator = SymlinkCreator(holdingDirectoryURL: fileURL)
				completion(symlinkCreator)
			}
		}
	}
}
