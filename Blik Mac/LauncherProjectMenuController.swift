//
//  LauncherProjectMenuController.swift
//  Blik
//
//  Created by Patrick Smith on 12/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntCocoaUI


private enum Item {
	case highlight(HighlightItemSource, HighlightItemDetails)
	case collection(GLACollection)
	case workOnNow
}

extension Item: UIChoiceRepresentative {
	typealias UniqueIdentifier = String
	var uniqueIdentifier: UniqueIdentifier {
		switch self {
		case let .highlight(sourceItem, _):
			return "highlight.\(sourceItem.UUID)"
		case let .collection(collection):
			return "collection.\(collection.uuid)"
		case .workOnNow:
			return "workOnNow"
		}
	}
	
	var title: String {
		switch self {
		case let .highlight(_, details):
			return details.displayName ?? NSLocalizedString("Loading…", comment: "Title for loading highlight")
		case let .collection(collection):
			return collection.name
		case .workOnNow:
			return NSLocalizedString("Work on Now…", comment: "Title for working on project now")
		}
	}
	
	var attributes: [String: AnyObject]? {
		switch self {
		/*case let .Highlight(.GroupedCollectionHeading(collection), _):
			let style = GLAUIStyle.activeStyle()
			return [
				//NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleThick.rawValue,
				//NSUnderlineColorAttributeName: style.colorForCollectionColor(collection.color),
				NSFontAttributeName: style.highlightGroupFont
			]*/
		case let .highlight(itemSource, _):
			switch itemSource {
			case .groupedCollectionHeading, .masterFoldersHeading:
				let style = GLAUIStyle.active()
				return [
					NSFontAttributeName: style.highlightGroupFont
				]
			default:
				return nil
			}
		default:
			return nil
		}
	}
	
	var enabled: Bool {
		switch self {
		case let .highlight(_, details):
			return details.displayName != nil
		default:
			return true
		}
	}
	
	var icon: NSImage? {
		switch self {
		case let .highlight(_, details):
			return details.icon.map { image in
				image.size = NSSize(width: 16, height: 16)
				return image
			}
		default:
			return nil
		}
	}
}

open class LauncherProjectMenuController: NSObject {
	open let project: GLAProject
	fileprivate let projectManager: GLAProjectManager
	fileprivate let navigator: GLAMainSectionNavigator
	fileprivate let highlightsAssistant: ProjectHighlightsAssistant
	fileprivate let menuAssistant: MenuAssistant<Item>
	
	public init(menu: NSMenu, project: GLAProject, projectManager: GLAProjectManager, navigator: GLAMainSectionNavigator) {
		self.project = project
		self.projectManager = projectManager
		self.navigator = navigator
		
		highlightsAssistant = ProjectHighlightsAssistant(project: project, projectManager: projectManager, navigator: navigator, wantsIcons: true)
		
		menuAssistant = MenuAssistant(menu: menu)
		
		super.init()
		
		highlightsAssistant.reloadItems()
		highlightsAssistant.changesNotifier = { [weak self] in
			self?.reloadMenu()
		}
		
		menuAssistant.customization.enabled = { $0.enabled }
		menuAssistant.customization.image = { $0.icon }
		
		menuAssistant.customization.actionAndTarget = { [weak self] (item) in
			let action: Selector
			
			switch item {
			case .highlight:
				action = #selector(LauncherProjectMenuController.openHighlight(_:))
			case .collection:
				action = #selector(LauncherProjectMenuController.openCollection(_:))
			case .workOnNow:
				action = #selector(LauncherProjectMenuController.workOnNow(_:))
			}
			
			return (action, self)
		}
		
		menuAssistant.customization.additionalSetUp = { item, menuItem in
			if let attributes = item.attributes {
				menuItem.attributedTitle = NSAttributedString(string: item.title.uppercased(), attributes: attributes)
			}
		}
	}
	
	open var menu: NSMenu {
		return menuAssistant.menu
	}
	
	fileprivate var items: [Item?] {
		var items = zip(highlightsAssistant, highlightsAssistant.details).map { (sourceItem, details) -> Item? in
			return Item.highlight(sourceItem, details)
		}
		
		items.append(nil)
		items.append(Item.workOnNow)
		
		return items
	}

	fileprivate func reloadMenu() {
		menuAssistant.menuItemRepresentatives = items
		menuAssistant.update()
	}
	
	open func update() {
		reloadMenu()
	}
}

extension LauncherProjectMenuController {
	fileprivate func activateApplication() {
		NSApp.activate(ignoringOtherApps: true)
	}
	
	@IBAction func openHighlight(_ menuItem: NSMenuItem) {
		guard let
      item = menuAssistant.itemRepresentative(for: menuItem),
			case let .highlight(highlightSource, _) = item
			else { return }
		
		highlightsAssistant.openItem(highlightSource, withBehaviour: OpeningBehaviour(modifierFlags: NSEvent.modifierFlags()), activateIfNeeded: true)
	}
	
	@IBAction func openCollection(_ menuItem: NSMenuItem) {
		guard let
      item = menuAssistant.itemRepresentative(for: menuItem),
			case let .collection(collection) = item
			else { return }
	
    navigator.go(to: collection)
	
		activateApplication()
	}
	
	@IBAction func workOnNow(_ menuItem: NSMenuItem) {
		projectManager.changeNowProject(project)
	}
}
