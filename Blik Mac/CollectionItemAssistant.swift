//
//  CollectionItemAssistant.swift
//  Blik
//
//  Created by Patrick Smith on 26/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntCocoaUI


private enum Item: Int {
	case RenameOrRecolor
	case Delete
	
	var title: String {
		switch self {
		case .RenameOrRecolor:
			return "Rename or Recolor Collection…"
		case .Delete:
			return "Delete Collection…"
		}
	}
	
	var action: Selector {
		switch self {
		case .RenameOrRecolor:
			return "renameOrRecolorCollection:"
		case .Delete:
			return "deleteCollection:"
		}
	}
}

extension Item: UIChoiceRepresentative {
	typealias UniqueIdentifier = Item
	var uniqueIdentifier: Item {
		return self
	}
}


@objc public protocol CollectionItemAssistantDelegate: class {
	func editDetailsOfCollection(collection: GLACollection, atRow collectionRow: Int)
	
	func deleteCollection(collection: GLACollection, atRow collectionRow: Int)
	
	func renameClickedCollection(sender: AnyObject?)
}


public class CollectionItemAssistant: NSObject {
	public weak var delegate: CollectionItemAssistantDelegate?
	public let menu = NSMenu()
	private let menuAssistant: MenuAssistant<Item>
	
	override init() {
		menuAssistant = MenuAssistant<Item>(menu: menu)
		
		super.init()
		
		menuAssistant.customization.actionAndTarget = { [weak self] item in
			return (action: item.action, target: self)
		}
	}
	
	public var collectionAndRow: (collection: GLACollection, row: Int)? {
		didSet {
			if collectionAndRow != nil {
				menuAssistant.menuItemRepresentatives = [
					.RenameOrRecolor,
					nil,
					.Delete
				]
			}
			else {
				menuAssistant.menuItemRepresentatives = []
			}
			
			menuAssistant.update()
		}
	}
	
	@IBAction public func renameOrRecolorCollection(menuItem: NSMenuItem) {
		if let (collection, row) = collectionAndRow {
			delegate?.editDetailsOfCollection(collection, atRow: row)
		}
	}
	
	@IBAction public func deleteCollection(menuItem: NSMenuItem) {
		if let (collection, row) = collectionAndRow {
			delegate?.deleteCollection(collection, atRow: row)
		}
	}
}


public class CollectionItemTableCellView: NSTableCellView {
	private let assistant = CollectionItemAssistant()
	
	public var delegate: CollectionItemAssistantDelegate? {
		get {
			return assistant.delegate
		}
		set {
			assistant.delegate = newValue
		}
	}
	
	public var contextualMenu: NSMenu {
		return assistant.menu
	}
	
	public func setCollection(collection: GLACollection, row: Int) {
		assistant.collectionAndRow = (collection, row)
	}

	public func clearCollection() {
		assistant.collectionAndRow = nil
	}
}
