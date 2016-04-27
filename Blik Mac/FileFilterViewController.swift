//
//  FileFilterViewController.swift
//  Blik
//
//  Created by Patrick Smith on 26/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa
import Grain


class FileFilterViewController : GLAViewController {
	@IBOutlet var fieldsStackView: NSStackView!
	@IBOutlet var resultsTableView: NSTableView!
	
	var filteredFolderCollection: GLACollection!
	
	var fieldsState = FileQueryFieldsState()
	var fieldsProducer: FileQueryFieldsProducer!
	let fieldGroupSpacing: CGFloat = 16.0
	
	var masterFoldersUser: GLALoadableArrayUsing!
	//var masterFolders: [GLACollectedFile]?
	var masterFolderAccessors: [GLAFileAccessing]?
	
	var fetcher: FileFilterFetcher?
	var items: [FileFilterFetcher.Item]?
	
	override func prepareView() {
		fieldsProducer = FileQueryFieldsProducer(onFieldChange: { field in
			self.fieldsState.mergeField(field)
			self.updateFields()
			self.fetchResults()
		})
		
		let pm = GLAProjectManager.sharedProjectManager()
		masterFoldersUser = pm.usePrimaryFoldersForProjectUUID(filteredFolderCollection.projectUUID)
		masterFoldersUser.changeCompletionBlock = copyMasterFolders
		
		let _ = masterFoldersUser.inspectLoadingIfNeeded().map(copyMasterFolders)
		
		updateFields()
		
		resultsTableView.setDataSource(self)
		resultsTableView.setDelegate(self)
	}
	
	func copyMasterFolders(inspector: GLAArrayInspecting) {
		let masterFolders = (inspector.copyChildren() as! [GLACollectedFile])
		masterFolderAccessors = masterFolders.map { $0.accessFile() }
		
		fetchResults()
	}
	
	func updateFields() {
		fieldsProducer.updateStackView(fieldsStackView, forFields: fieldsState.fields, gapSpacing: fieldGroupSpacing, gravity: .Top)
	}
	
	func fetchResults() {
		guard let masterFolderAccessors = masterFolderAccessors else { return }
		
		let folderURLs = masterFolderAccessors.map { $0.filePathURL! }
		
		let request = fieldsState.toRequest(sourceFolderURLs: folderURLs)
		
		let fetcher = FileFilterFetcher(request: request, wantsItems: true, sortedBy: fieldsState.sortedBy, callbacks: FileFilterFetcher.Callbacks(
			onProgress: { [weak self] result in
				if case let .items(items) = result {
					GCDService.mainQueue.async {
						self?.updateItems(items)
					}
				}
			},
			onUpdate: { [weak self] result in
				if case let .items(items) = result {
					GCDService.mainQueue.async {
						self?.updateItems(items)
					}
				}
			}
		))
		
		self.fetcher?.stopSearch()
		
		fetcher.startSearch()
		self.fetcher = fetcher
	}
	
	func updateItems(items: [FileFilterFetcher.Item]) {
		self.items = items
		
		resultsTableView.reloadData()
	}
}

extension FileFilterViewController : NSTableViewDataSource, NSTableViewDelegate {
	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		return items?.count ?? 0
	}
	
	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let item = items![row]
		
		let cellView = tableView.makeViewWithIdentifier("file", owner: nil) as! FileFilterResultCellView
		//cellView.textField?.stringValue = item.displayName ?? ""
		cellView.pathControl.URL = item.fileURL
		
		return cellView
	}
}


class FileFilterResultCellView : NSTableCellView {
	@IBOutlet var pathControl: NSPathControl!
}
