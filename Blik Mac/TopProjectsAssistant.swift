//
//  TopProjectsMenu.swift
//  Blik
//
//  Created by Patrick Smith on 16/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntCocoaUI


private struct TopProject {
	var project: GLAProject
	var index: Int
}

extension TopProject: UIChoiceRepresentative {
	var title: String {
		return project.name
	}
	
	typealias UniqueIdentifier = NSUUID
	var uniqueIdentifier: UniqueIdentifier {
		return project.UUID
	}
}


class TopProjectsAssistant: NSObject {
	private let navigator: GLAMainSectionNavigator
	
	private let allProjectsUser: GLALoadableArrayUsing
	
	private let menuItemsAssistant: PlaceholderMenuItemAssistant<TopProject>
	
	init(placeholderMenuItem: NSMenuItem, projectManager: GLAProjectManager, navigator: GLAMainSectionNavigator) {
		self.navigator = navigator
		
		allProjectsUser = projectManager.useAllProjects()
		
		menuItemsAssistant = PlaceholderMenuItemAssistant<TopProject>(placeholderMenuItem: placeholderMenuItem)
		
		super.init()
		
		menuItemsAssistant.customization.actionAndTarget = { [weak self] _ in
			return (action: "goToProject:", target: self)
		}
		
		menuItemsAssistant.customization.additionalSetUp = { topProject, menuItem in
			menuItem.keyEquivalent = String(topProject.index + 1)
			
			let keyEquivalentModifierMask = NSEventModifierFlags.CommandKeyMask.union(.AlternateKeyMask)
			menuItem.keyEquivalentModifierMask = Int(keyEquivalentModifierMask.rawValue)
		}
		
		allProjectsUser.changeCompletionBlock = { [weak self] _ in
			self?.reloadUI()
		}
		
		reloadUI()
	}
	
	private var items: [TopProject?] {
		let allProjects = (allProjectsUser.copyChildrenLoadingIfNeeded() as! [GLAProject]?) ?? []
		let topProjects = allProjects.prefix(6)
		
		let projectItems: [TopProject?] = topProjects.enumerate().map { (index, project) in
			TopProject(project: project, index: index)
		}
		
		return projectItems
	}
	
	private func reloadUI() {
		menuItemsAssistant.menuItemRepresentatives = self.items
		menuItemsAssistant.update()
		menuItemsAssistant.placeholderMenuItem.menu?.update()
	}
	
	@IBAction func goToProject(menuItem: NSMenuItem) {
		if let item = menuItemsAssistant.itemRepresentativeForMenuItem(menuItem) {
			navigator.goToProject(item.project)
		}
	}
}

