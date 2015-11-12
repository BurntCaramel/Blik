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
	
	var enabled: Bool {
		switch self {
		case let .Highlight(_, details):
			return details.displayName != nil
		default:
			return true
		}
	}
}

public class LauncherProjectMenuController {
	public let project: GLAProject
	private let highlightsAssistant: ProjectHighlightsAssistant
	private let menuAssistant: MenuAssistant<Item>
	
	public init(menu: NSMenu, project: GLAProject, projectManager: GLAProjectManager) {
		self.project = project
		
		highlightsAssistant = ProjectHighlightsAssistant(project: project, projectManager: projectManager)
		
		menuAssistant = MenuAssistant(menu: menu)
		
		highlightsAssistant.reloadItems()
		highlightsAssistant.changesNotifier = { [weak self] in
			self?.reloadMenu()
		}
		
		menuAssistant.customization.enabled = { $0.enabled }
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
