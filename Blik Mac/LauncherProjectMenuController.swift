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
	case Highlight(HighlightItemSource, HighlightItemDetails)
	case Collection(GLACollection)
	case WorkOnNow
}

extension Item: UIChoiceRepresentative {
	typealias UniqueIdentifier = String
	var uniqueIdentifier: UniqueIdentifier {
		switch self {
		case let .Highlight(sourceItem, _):
			return "highlight.\(sourceItem.UUID)"
		case let .Collection(collection):
			return "collection.\(collection.UUID)"
		case .WorkOnNow:
			return "workOnNow"
		}
	}
	
	var title: String {
		switch self {
		case let .Highlight(_, details):
			return details.displayName ?? NSLocalizedString("Loading…", comment: "Title for loading highlight")
		case let .Collection(collection):
			return collection.name
		case .WorkOnNow:
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
		case let .Highlight(itemSource, _):
			switch itemSource {
			case .GroupedCollectionHeading, .MasterFoldersHeading:
				let style = GLAUIStyle.activeStyle()
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
		case let .Highlight(_, details):
			return details.displayName != nil
		default:
			return true
		}
	}
	
	var icon: NSImage? {
		switch self {
		case let .Highlight(_, details):
			return details.icon.map { image in
				image.size = NSSize(width: 16, height: 16)
				return image
			}
		default:
			return nil
		}
	}
}

public class LauncherProjectMenuController: NSObject {
	public let project: GLAProject
	private let projectManager: GLAProjectManager
	private let navigator: GLAMainSectionNavigator
	private let highlightsAssistant: ProjectHighlightsAssistant
	private let menuAssistant: MenuAssistant<Item>
	
	public init(menu: NSMenu, project: GLAProject, projectManager: GLAProjectManager, navigator: GLAMainSectionNavigator) {
		self.project = project
		self.projectManager = projectManager
		self.navigator = navigator
		
		highlightsAssistant = ProjectHighlightsAssistant(project: project, projectManager: projectManager, wantsIcons: true)
		
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
			case .Highlight:
				action = "openHighlight:"
			case .Collection:
				action = "openCollection:"
			case .WorkOnNow:
				action = "workOnNow:"
			}
			
			return (action, self)
		}
		
		menuAssistant.customization.additionalSetUp = { item, menuItem in
			if let attributes = item.attributes {
				menuItem.attributedTitle = NSAttributedString(string: item.title.uppercaseString, attributes: attributes)
			}
		}
	}
	
	public var menu: NSMenu {
		return menuAssistant.menu
	}
	
	private var items: [Item?] {
		var items = zip(highlightsAssistant, highlightsAssistant.details).map { (sourceItem, details) -> Item? in
			return Item.Highlight(sourceItem, details)
		}
		
		items.append(nil)
		items.append(Item.WorkOnNow)
		
		return items
	}

	private func reloadMenu() {
		menuAssistant.menuItemRepresentatives = items
		menuAssistant.update()
	}
	
	public func update() {
		reloadMenu()
	}
}

extension LauncherProjectMenuController {
	private func activateApplication() {
		NSApp.activateIgnoringOtherApps(true)
	}
	
	@IBAction func openHighlight(menuItem: NSMenuItem) {
		guard let
			item = menuAssistant.itemRepresentativeForMenuItem(menuItem),
			case let .Highlight(highlightSource, _) = item
			else { return }
		
		switch highlightSource {
		case let .Item(highlightedCollectedFile as GLAHighlightedCollectedFile, _):
			projectManager.openHighlightedCollectedFile(highlightedCollectedFile, behaviour: OpeningBehaviour(modifierFlags: NSEvent.modifierFlags()))
		case let .GroupedCollectionHeading(collection):
			navigator.goToCollection(collection)
			
			activateApplication()
		case let .MasterFolder(collectedFolder):
			projectManager.openCollectedFile(collectedFolder, behaviour: OpeningBehaviour(modifierFlags: NSEvent.modifierFlags()))
		default:
			NSBeep()
		}
	}
	
	@IBAction func openCollection(menuItem: NSMenuItem) {
		guard let
			item = menuAssistant.itemRepresentativeForMenuItem(menuItem),
			case let .Collection(collection) = item
			else { return }
	
		navigator.goToCollection(collection)
	
		activateApplication()
	}
	
	@IBAction func workOnNow(menuItem: NSMenuItem) {
		projectManager.changeNowProject(project)
	}
}
