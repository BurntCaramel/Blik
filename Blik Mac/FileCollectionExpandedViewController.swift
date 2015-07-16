//
//  FileCollectionExpandedViewController.swift
//  Blik
//
//  Created by Patrick Smith on 24/06/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntFoundation


private struct CollectedFileInfo {
	let URL: NSURL
	let isDirectory: Bool
}


@objc public class FileCollectionExpandedTableViewController: GLAViewController {
	@IBOutlet var outlineView: NSOutlineView!
	
	var filesListCollection: GLACollection? {
		didSet {
			reloadSourceFiles()
		}
	}
	
	private var filesListClient: GLALoadableArrayUsing!
	private var collectedFiles = [GLACollectedFile]() {
		didSet {
			collectedFilesDidChange()
		}
	}
	private var collectedFilesSetting: GLACollectedFilesSetting!
	private var collectedFilesSettingNotificationObserver: NotificationObserver<AnyStringNotificationIdentifier>!
	
	private var orderedChildCounts = [Int]()
	private var collectedFileUUIDToInfo = [NSUUID: CollectedFileInfo]()
	private var directoryURLToArrangedChildren = [NSURL: GLAArrangedDirectoryChildren]()
	
	private var fileInfoRetriever: GLAFileInfoRetriever! {
		return collectedFilesSetting.fileInfoRetriever
	}
	
	private var fileInfoDisplayingAssistant: FileInfoDisplayingAssistant!
	
	var projectManager: GLAProjectManager {
		return GLAProjectManager.sharedProjectManager()
	}
	
	public override func prepareView() {
		outlineView.setDataSource(self)
		outlineView.setDelegate(self)
		
		let style = GLAUIStyle.activeStyle()
		//style.prepareContentTableView(outlineView)
		
		collectedFilesSetting = GLACollectedFilesSetting()
		collectedFilesSettingNotificationObserver = NotificationObserver<AnyStringNotificationIdentifier>(object: collectedFilesSetting)
	collectedFilesSettingNotificationObserver.addObserver( GLACollectedFilesSettingLoadedFileInfoDidChangeNotification ) { [unowned self] notification in
			if let collectedFile = notification.userInfo?[GLACollectedFilesSettingLoadedFileInfoDidChangeNotification_CollectedFile] as? GLACollectedFile {
				self.updateInfoForCollectedFile(collectedFile)
				self.reloadViews()
			}
		}
		
		fileInfoDisplayingAssistant = FileInfoDisplayingAssistant(fileInfoRetriever: collectedFilesSetting.fileInfoRetriever)
	}
	
	func collectedFilesDidChange() {
		collectedFilesSetting.startAccessingCollectedFilesStoppingRemainders(collectedFiles)
		
		for collectedFile in collectedFiles {
			updateInfoForCollectedFile(collectedFile)
		}
		
		reloadViews()
	}
	
	func updateInfoForCollectedFile(collectedFile: GLACollectedFile) {
		if let
			fileURL = collectedFilesSetting.filePathURLForCollectedFile(collectedFile),
			isDirectoryValue = collectedFilesSetting.copyValueForURLResourceKey(NSURLIsDirectoryKey, forCollectedFile: collectedFile) as? NSNumber,
			isPackageValue = collectedFilesSetting.copyValueForURLResourceKey(NSURLIsPackageKey, forCollectedFile: collectedFile) as? NSNumber {
				let isDirectory = (isDirectoryValue == true) && (isPackageValue == false)
				collectedFileUUIDToInfo[collectedFile.UUID] = CollectedFileInfo(URL: fileURL, isDirectory: isDirectory)
		}
		else {
			collectedFileUUIDToInfo[collectedFile.UUID] = nil
		}
	}
	
	func reloadSourceFiles() {
		let pm = projectManager
		
		if let filesListCollection = filesListCollection {
			println("useFilesListForCollection \(filesListCollection)")
			filesListClient = pm.useFilesListForCollection(filesListCollection)
			filesListClient.changeCompletionBlock = { [unowned self] (filesListInspector) in
				self.reloadFromFilesListInspector(filesListInspector)
			}
			
			filesListClient.whenLoaded(self.reloadFromFilesListInspector)
		}
		else {
			collectedFiles.removeAll()
			reloadViews()
		}
	}
	
	private func reloadFromFilesListInspector(filesListInspector: GLAArrayInspecting) {
		let newCollectedFiles = filesListInspector.copyChildren() as! [GLACollectedFile]
		self.collectedFiles = newCollectedFiles
		self.reloadViews()
	}
	
	func reloadViews() {
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
					if let fileURLs = arrangedChildrenForDirectoryURL(info.URL)?.fileURLs {
						return fileURLs.count
					}
					else {
						return 0
					}
				}
			}
			
			return numberOfItemsForFiles
		}
		else if let fileURL = item as? NSURL {
			if let fileURLs = arrangedChildrenForDirectoryURL(fileURL)?.fileURLs {
				return fileURLs.count
			}
			else {
				return 0
			}
		}
		
		return 0
	}
	
	public func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
		if let collectedFile = item as? GLACollectedFile {
			if let info = collectedFileUUIDToInfo[collectedFile.UUID] {
				return info.isDirectory
			}
		}
		else if let fileURL = item as? NSURL {
			if let arrangedChildren = arrangedChildrenForDirectoryURL(fileURL) {
				return true
			}
		}
		
		return false
	}
	
	
	public func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
		if item == nil {
			return collectedFiles[index]
		}
		else if let collectedFile = item as? GLACollectedFile {
			if let info = collectedFileUUIDToInfo[collectedFile.UUID] {
				if info.isDirectory {
					if let fileURLs = arrangedChildrenForDirectoryURL(info.URL)?.fileURLs {
						return fileURLs[index]
					}
				}
			}
		}
		else if let fileURL = item as? NSURL {
			if let fileURLs = arrangedChildrenForDirectoryURL(fileURL)?.fileURLs {
				return fileURLs[index]
			}
		}
		
		return 0
	}
	
	// MARK: Delegate
	
	public func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
		var fileURLToDisplay: NSURL?
		
		if let collectedFile = item as? GLACollectedFile {
			fileURLToDisplay = collectedFilesSetting.filePathURLForCollectedFile(collectedFile)
		}
		else if let fileURL = item as? NSURL {
			fileURLToDisplay = fileURL
		}
		
		if let fileURL = fileURLToDisplay {
			if let cellView = fileInfoDisplayingAssistant.tableCellViewForTableView(outlineView, tableColumn: tableColumn, fileURL: fileURL) {
				//cellView.menu = contextualMenuAssistant.menu
				
				return cellView
			}
		}
		
		return nil
	}
}

extension FileCollectionExpandedTableViewController: GLAArrangedDirectoryChildrenDelegate {
	public func arrangedDirectoryChildrenDidUpdateChildren(arrangedDirectoryChildren: GLAArrangedDirectoryChildren) {
		println("arrangedDirectoryChildrenDidUpdateChildren \(arrangedDirectoryChildren.directoryURL)")
		outlineView.reloadItem(arrangedDirectoryChildren.directoryURL, reloadChildren: true)
	}
}
