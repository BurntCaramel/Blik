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
	case renameOrRecolor
	case delete
	
	var title: String {
		switch self {
		case .renameOrRecolor:
			return "Rename or Recolor Collection…"
		case .delete:
			return "Delete Collection…"
		}
	}
	
	var action: Selector {
		switch self {
		case .renameOrRecolor:
			return #selector(CollectionItemAssistant.renameOrRecolorCollection(_:))
		case .delete:
			return #selector(CollectionItemAssistant.deleteCollection(_:))
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
	func editDetailsOfCollection(_ collection: GLACollection, atRow collectionRow: Int)
	
	func deleteCollection(_ collection: GLACollection, atRow collectionRow: Int)
	
	func renameClickedCollection(_ sender: AnyObject?)
}


open class CollectionItemAssistant: NSObject {
	open weak var delegate: CollectionItemAssistantDelegate?
	open let menu = NSMenu()
	fileprivate let menuAssistant: MenuAssistant<Item>
	
	override init() {
		menuAssistant = MenuAssistant<Item>(menu: menu)
		
		super.init()
		
		menuAssistant.customization.actionAndTarget = { [weak self] item in
			return (action: item.action, target: self)
		}
	}
	
	open var collectionAndRow: (collection: GLACollection, row: Int)? {
		didSet {
			if collectionAndRow != nil {
				menuAssistant.menuItemRepresentatives = [
					.renameOrRecolor,
					nil,
					.delete
				]
			}
			else {
				menuAssistant.menuItemRepresentatives = []
			}
			
			menuAssistant.update()
		}
	}
	
	@IBAction open func renameOrRecolorCollection(_ menuItem: NSMenuItem) {
		if let (collection, row) = collectionAndRow {
			delegate?.editDetailsOfCollection(collection, atRow: row)
		}
	}
	
	@IBAction open func deleteCollection(_ menuItem: NSMenuItem) {
		if let (collection, row) = collectionAndRow {
			delegate?.deleteCollection(collection, atRow: row)
		}
	}
}


open class CollectionItemTableCellView: NSTableCellView {
	fileprivate let assistant = CollectionItemAssistant()
	
	open var delegate: CollectionItemAssistantDelegate? {
		get {
			return assistant.delegate
		}
		set {
			assistant.delegate = newValue
		}
	}
	
	open var contextualMenu: NSMenu {
		return assistant.menu
	}
	
	open func setCollection(_ collection: GLACollection, row: Int) {
		assistant.collectionAndRow = (collection, row)
	}

	open func clearCollection() {
		assistant.collectionAndRow = nil
	}
}
