//
//  FileCollectionExpandedViewController.swift
//  Blik
//
//  Created by Patrick Smith on 24/06/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa

private struct CollectedFileInfo {
	let URL: NSURL
	let isDirectory: Bool
}


@objc public class FileCollectionExpandedTableViewController: GLAViewController {
	@IBOutlet var outlineView: NSOutlineView!
	
	var filesListCollection: GLACollection? {
		didSet {
			reload()
		}
	}
	
	private var collectedFiles = [GLACollectedFile]()
	
	private var orderedChildCounts = [Int]()
	private var collectedFileUUIDToInfo = [NSUUID: CollectedFileInfo]()
	private var directoryURLToArrangedChildren = [NSURL: GLAArrangedDirectoryChildren]()
	
	private var fileInfoRetriever: GLAFileInfoRetriever!
	
	private var fileInfoDisplayingAssistant: FileInfoDisplayingAssistant!
	
	var projectManager: GLAProjectManager {
		return GLAProjectManager.sharedProjectManager()
	}
	
	func reloadSourceFiles() {
		let pm = projectManager
		
		let project = pm.projectWithUUID(filesListCollection.projectUUID)
		
		[pm loadFilesListForCollectionIfNeeded:filesListCollection];
		
		BOOL hasLoadedPrimaryFolders = [pm hasLoadedPrimaryFoldersForProject:project];
		
		if (hasLoadedPrimaryFolders) {
			collectedFiles = [pm copyFilesListForCollection:filesListCollection];
		}
		else {
			[pm loadPrimaryFoldersForProjectIfNeeded:project];
		}
	}
	
	func reload() {
		outlineView.reloadData()
		
		for collectedFile in collectedFiles {
			outlineView.expandItem(collectedFile)
		}
	}
	
	func arrangedChildrenForDirectoryURL(directoryURL: NSURL) -> GLAArrangedDirectoryChildren? {
		if let directoryChildren = directoryURLToArrangedChildren[directoryURL] {
			return directoryChildren
		}
		else {
			let directoryChildren = GLAArrangedDirectoryChildren(directoryURL: directoryURL, delegate: self, fileInfoRetriever: fileInfoRetriever)
			directoryURLToArrangedChildren[directoryURL] = directoryChildren
			return directoryChildren
		}
	}
}

private var numberOfItemsLeading = 1
private var numberOfItemsTrailing = 0
private var numberOfItemsForFiles = 1

extension FileCollectionExpandedTableViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
	public func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
		if item == nil {
			return collectedFiles.count
			
		}
		else if let collectedFile = item as? GLACollectedFile {
			if let info = collectedFileUUIDToInfo[collectedFile.UUID] {
				if info.isDirectory {
					if let arrangedChildren = arrangedChildrenForDirectoryURL(info.URL) {
						return arrangedChildren.arrangedChildren.count
					}
				}
			}
			
			return numberOfItemsForFiles
		}
		else if let fileURL = item as? NSURL {
			if let arrangedChildren = arrangedChildrenForDirectoryURL(fileURL) {
				return arrangedChildren.arrangedChildren.count
			}
		}
		
		return 0
	}
	
	
	public func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
		if item == nil {
			return collectedFiles[index]
		}
		else if let collectedFile = item as? GLACollectedFile {
			if let info = collectedFileUUIDToInfo[collectedFile.UUID] {
				if info.isDirectory {
					if let arrangedChildren = arrangedChildrenForDirectoryURL(info.URL) {
						return arrangedChildren.arrangedChildren[index]
					}
				}
			}
		}
		else if let fileURL = item as? NSURL {
			if let arrangedChildren = arrangedChildrenForDirectoryURL(fileURL) {
				return arrangedChildren.arrangedChildren[index]
			}
		}
		
		return 0
	}
	
	// MARK: Delegpublic ate
	
	public func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
		
		let fileURL = item as! NSURL
		
		if let cellView = fileInfoDisplayingAssistant.tableCellViewForTableView(outlineView, tableColumn: tableColumn, fileURL: fileURL) {
			//cellView.menu = contextualMenuAssistant.menu
			
			return cellView
		}
		
		return nil
	}
}

extension FileCollectionExpandedTableViewController: GLAArrangedDirectoryChildrenDelegate {
	public func arrangedDirectoryChildrenDidUpdateChildren(arrangedDirectoryChildren: GLAArrangedDirectoryChildren!) {
		outlineView.reloadItem(arrangedDirectoryChildren.directoryURL, reloadChildren: true)
	}
}
