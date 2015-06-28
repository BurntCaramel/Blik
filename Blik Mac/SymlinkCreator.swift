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
	private let fileManager: NSFileManager
	var modelUsers = [GLALoadableArrayUsing]()
	
	init(holdingDirectoryURL: NSURL, projectManager: GLAProjectManager = GLAProjectManager.sharedProjectManager()) {
		self.holdingDirectoryURL = holdingDirectoryURL
		self.projectManager = projectManager
		self.fileManager = NSFileManager()
	}
	
	public func createLinks() {
		self.createLinksForAllProjectsInDirectoryURL(self.holdingDirectoryURL)
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
		var error: NSError?
		let existingURLs = fileManager.contentsOfDirectoryAtURL(holdingDirectoryURL, includingPropertiesForKeys: nil, options: .SkipsSubdirectoryDescendants, error: &error) as! [NSURL]
		for existingURL in existingURLs {
			fileManager.removeItemAtURL(existingURL, error: &error)
		}
	}
	
	private func projectsDidChange() {
		removeContentsOfDirectoryWithURL(holdingDirectoryURL)
		createLinksForAllProjectsInDirectoryURL(holdingDirectoryURL)
	}
	
	private func createDirectoryAtURL(directoryURL: NSURL) {
		var error: NSError?
		fileManager.createDirectoryAtURL(directoryURL, withIntermediateDirectories: true, attributes: nil, error: &error)
	}
	
	private func createLinksForAllProjectsInDirectoryURL(holdingDirectoryURL: NSURL) {
		let projectsUser = useAllProjects()
		
		projectsUser.ensureLoaded { projectsInspector in
			let projects = projectsInspector.copyChildren() as! [GLAProject]
			for project in projects {
				let projectDirectoryURL = holdingDirectoryURL.URLByAppendingPathComponent(project.name)
				println("PROJECT \(projectDirectoryURL)")
				self.createDirectoryAtURL(projectDirectoryURL)
				
				self.createLinksForProjectWithUUID(project.UUID, inDirectoryURL: projectDirectoryURL)
			}
		}
	}
	
	private func createLinksForProjectWithUUID(projectUUID: NSUUID, inDirectoryURL holdingDirectoryURL: NSURL) {
		var error: NSError?
		
		let pm = projectManager
		let project = pm.projectWithUUID(projectUUID)!
		
		let collectionsUser = pm.useCollectionsForProject(project)
		modelUsers.append(collectionsUser)
		
		collectionsUser.ensureLoaded { collectionsInspector in
			let collections = collectionsInspector.copyChildren() as! [GLACollection]
			
			for collection in collections {
				let collectionDirectoryURL = holdingDirectoryURL.URLByAppendingPathComponent(collection.name)
				self.createDirectoryAtURL(collectionDirectoryURL)
				
				self.createLinksForFilesListCollection(collection, inDirectoryURL: collectionDirectoryURL)
			}
		}
	}
	
	private func createLinksForFilesListCollection(collection: GLACollection, inDirectoryURL holdingDirectoryURL: NSURL) {
		var error: NSError?
		
		let pm = projectManager
		
		let filesListUser = pm.useFilesListForCollection(collection)
		modelUsers.append(filesListUser)
		
		println("ENSURE LOADED")
		filesListUser.ensureLoaded { filesListInspector in
			let filesList = filesListInspector.copyChildren() as! [GLACollectedFile]
			println("DID LOAD")
			
			for collectedFile in filesList {
				let accessedFile = collectedFile.accessFile()
				println("HOLDING \(holdingDirectoryURL) \n ACCESSED FILE \(accessedFile.filePathURL)")
				if let
					filePathURL = accessedFile.filePathURL,
					fileName = filePathURL.lastPathComponent
				{
					let linkURL = holdingDirectoryURL.URLByAppendingPathComponent(fileName)
					println("Creating symbolic link \(filePathURL) -> \(linkURL)")
					let success = self.fileManager.createSymbolicLinkAtURL(linkURL, withDestinationURL: filePathURL, error: &error)
					if !success {
						
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
		
		openPanel.beginWithCompletionHandler { result in
			if result == NSFileHandlingPanelOKButton {
				if let fileURL = openPanel.URLs[0] as? NSURL {
					let symlinkCreator = SymlinkCreator(holdingDirectoryURL: fileURL)
					completion(symlinkCreator)
				}
			}
		}
	}
}
