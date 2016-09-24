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
	
	typealias UniqueIdentifier = UUID
	var uniqueIdentifier: UniqueIdentifier {
		return project.uuid
	}
}


class TopProjectsAssistant: NSObject {
	fileprivate let navigator: GLAMainSectionNavigator
	
	fileprivate let allProjectsUser: GLALoadableArrayUsing
	
	fileprivate let menuItemsAssistant: PlaceholderMenuItemAssistant<TopProject>
	
	init(placeholderMenuItem: NSMenuItem, projectManager: GLAProjectManager, navigator: GLAMainSectionNavigator) {
		self.navigator = navigator
		
		allProjectsUser = projectManager.useAllProjects()
		
		menuItemsAssistant = PlaceholderMenuItemAssistant<TopProject>(placeholderMenuItem: placeholderMenuItem)
		
		super.init()
		
		menuItemsAssistant.customization.actionAndTarget = { [weak self] _ in
			return (action: #selector(TopProjectsAssistant.goToProject(_:)), target: self)
		}
		
		menuItemsAssistant.customization.additionalSetUp = { topProject, menuItem in
			menuItem.keyEquivalent = String(topProject.index + 1)
			menuItem.keyEquivalentModifierMask = [.command, .option]
		}
		
		allProjectsUser.changeCompletionBlock = { [weak self] _ in
			self?.reloadUI()
		}
		
		reloadUI()
	}
	
	fileprivate var items: [TopProject?] {
		let allProjects = (allProjectsUser.copyChildrenLoadingIfNeeded() as! [GLAProject]?) ?? []
		let topProjects = allProjects.prefix(6)
		
		let projectItems: [TopProject?] = topProjects.enumerated().map { (index, project) in
			TopProject(project: project, index: index)
		}
		
		return projectItems
	}
	
	fileprivate func reloadUI() {
		menuItemsAssistant.menuItemRepresentatives = self.items
		menuItemsAssistant.update()
		menuItemsAssistant.placeholderMenuItem.menu?.update()
	}
	
	@IBAction func goToProject(_ menuItem: NSMenuItem) {
    if let item = menuItemsAssistant.itemRepresentative(for: menuItem) {
      navigator.go(to: item.project)
		}
	}
}

