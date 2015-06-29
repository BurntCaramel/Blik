//
//  FileInfoDisplaying.swift
//  Blik
//
//  Created by Patrick Smith on 29/06/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


internal enum FileInfoIdentifier: String {
	case DisplayNameAndIcon = "displayNameAndIcon"
	case DateModified = "dateModified"
	
	var sortDescriptor: NSSortDescriptor {
		switch self {
		case .DisplayNameAndIcon:
			return NSSortDescriptor(key:NSURLLocalizedNameKey, ascending:true)
		case .DateModified:
			return NSSortDescriptor(key:NSURLContentModificationDateKey, ascending:false)
		}
	}
	
	func updateTableColumnInTableView(tableView: NSTableView) {
		if let tableColumn = tableView.tableColumnWithIdentifier(rawValue) {
			tableColumn.sortDescriptorPrototype = sortDescriptor
		}
	}
}

internal struct FileInfoDisplayingAssistant {
	let fileInfoRetriever: GLAFileInfoRetriever
	
	let dateFormatter: NSDateFormatter = {
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateStyle = .MediumStyle
		dateFormatter.timeStyle = .ShortStyle
		dateFormatter.doesRelativeDateFormatting = true
		return dateFormatter
		}()
	
	func textForInfoIdentifier(identifier: FileInfoIdentifier, fileURL: NSURL) -> String? {
		switch identifier {
		case .DisplayNameAndIcon:
			return fileInfoRetriever.resourceValueForKey(NSURLLocalizedNameKey, forURL: fileURL) as? String
		case .DateModified:
			if let dateModified = fileInfoRetriever.resourceValueForKey(NSURLContentModificationDateKey, forURL: fileURL) as? NSDate {
				return dateFormatter.stringFromDate(dateModified)
			}
		}
		
		return nil
	}
	
	func imageForInfoIdentifier(identifier: FileInfoIdentifier, fileURL: NSURL) -> NSImage? {
		switch identifier {
		case .DisplayNameAndIcon:
			return fileInfoRetriever.resourceValueForKey(NSURLEffectiveIconKey, forURL: fileURL) as? NSImage
		default:
			return nil
		}
	}
	
	func tableCellViewForTableView(tableView: NSTableView, tableColumn: NSTableColumn?, fileURL: NSURL) -> NSTableCellView? {
		if let identifier = tableColumn?.identifier {
			let cellView = tableView.makeViewWithIdentifier(identifier, owner: nil) as! NSTableCellView
			
			let fileInfoRetriever = self.fileInfoRetriever
			
			var text: String?
			var image: NSImage?
			let hasImageView = (cellView.imageView != nil)
			
			if let infoIdentifier = FileInfoIdentifier(rawValue: identifier) {
				text = textForInfoIdentifier(infoIdentifier, fileURL: fileURL)
				image = imageForInfoIdentifier(infoIdentifier, fileURL: fileURL)
			}
			
			cellView.textField?.stringValue = text ?? "Loading…"
			cellView.imageView?.image = image
			
			return cellView
		}
		
		return nil
	}
}
