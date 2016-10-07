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
		
		let pm = GLAProjectManager.shared()
		masterFoldersUser = pm.usePrimaryFolders(forProjectUUID: filteredFolderCollection.projectUUID)
		masterFoldersUser.changeCompletionBlock = copyMasterFolders
		
		let _ = masterFoldersUser.inspectLoadingIfNeeded().map(copyMasterFolders)
		
		updateFields()
		
		resultsTableView.dataSource = self
		resultsTableView.delegate = self
	}
	
	func copyMasterFolders(_ inspector: GLAArrayInspecting) {
		let masterFolders = (inspector.copyChildren() as! [GLACollectedFile])
		masterFolderAccessors = masterFolders.flatMap { $0.accessFile() }
		
		fetchResults()
	}
	
	func updateFields() {
    fieldsProducer.update(stackView: fieldsStackView, forFields: fieldsState.fields, gapSpacing: fieldGroupSpacing, gravity: .top)
	}
	
	func fetchResults() {
		guard let masterFolderAccessors = masterFolderAccessors else { return }
		
		let folderURLs = masterFolderAccessors.map { $0.filePathURL! }
		
		let request = fieldsState.toRequest(sourceFolderURLs: folderURLs)
		
		let fetcher = FileFilterFetcher(request: request, wantsItems: true, sortedBy: fieldsState.sortedBy, wantsUpdates: true) {
			[weak self] (result, updateKind) in
			if case let .items(items) = result {
				GCDService.mainQueue.async {
					self?.updateItems(items)
				}
			}
		}
		
		self.fetcher?.stopSearch()
		
		fetcher.startSearch()
		self.fetcher = fetcher
	}
	
	func updateItems(_ items: [FileFilterFetcher.Item]) {
		self.items = items
		
		resultsTableView.reloadData()
	}
}

extension FileFilterViewController : NSTableViewDataSource, NSTableViewDelegate {
	func numberOfRows(in tableView: NSTableView) -> Int {
		return items?.count ?? 0
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let item = items![row]
		
		let cellView = tableView.make(withIdentifier: "file", owner: nil) as! FileFilterResultCellView
		//cellView.textField?.stringValue = item.displayName ?? ""
		cellView.pathControl.url = item.fileURL as URL?
		
		return cellView
	}
}


class FileFilterResultCellView : NSTableCellView {
	@IBOutlet var pathControl: NSPathControl!
}
