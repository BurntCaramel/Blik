//
//  LauncherMenuController.swift
//  Blik
//
//  Created by Patrick Smith on 12/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntFoundation
import BurntCocoaUI


private enum Item {
	case NowProject
	case Project(GLAProject)
	case AllProjects
	case NewProject
}

extension Item: UIChoiceRepresentative {
	typealias UniqueIdentifier = String
	var uniqueIdentifier: UniqueIdentifier {
		switch self {
		case .NowProject:
			return "now"
		case let .Project(project):
			return "project.\(project.UUID)"
		case .AllProjects:
			return "allProjects"
		case .NewProject:
			return "newProject"
		}
	}
	
	var title: String {
		switch self {
		case .NowProject:
			return "Now"
		case let .Project(project):
			return project.name
		case .AllProjects:
			return NSLocalizedString("All Projects…", comment: "Title for opening All Projects")
		case .NewProject:
			return NSLocalizedString("New Project…", comment: "Title for creating a new project")
		}
	}
}

public class LauncherMenuController: NSObject {
	private let projectManager: GLAProjectManager
	private let navigator: GLAMainSectionNavigator
	private let allProjectsUser: GLALoadableArrayUsing
	private let menuAssistant: MenuAssistant<Item>
	private let projectMenuControllerCache = NSCache()
	private let projectManagerObserver: AnyNotificationObserver
	private let nowWidgetViewController: NowWidgetViewController
	
	public init(menu: NSMenu, projectManager: GLAProjectManager, navigator: GLAMainSectionNavigator) {
		self.projectManager = projectManager
		self.navigator = navigator
		
		allProjectsUser = projectManager.useAllProjects()
		projectManagerObserver = AnyNotificationObserver(object: projectManager)
		
		menuAssistant = MenuAssistant(menu: menu)
		
		nowWidgetViewController = NowWidgetViewController()
		
		super.init()
		
		menu.delegate = self
		
		menuAssistant.customization.actionAndTarget = { [weak self] (item) in
			let action: Selector
			
			switch item {
			case .NowProject:
				action = nil
			case .Project:
				action = "openProject:"
			case .AllProjects:
				action = "goToAllProjects:"
			case .NewProject:
				action = "createNewProject:"
			}
			
			return (action, self)
		}
		
		menuAssistant.customization.state = { (item) in
			switch item {
			case let .Project(project):
				if project.UUID == projectManager.nowProject?.UUID {
					return NSOnState
				}
			default: break
			}
			
			return NSOffState
		}
		
		menuAssistant.customization.additionalSetUp = { item, menuItem in
			switch item {
			case .NowProject:
				menuItem.view = self.nowWidgetViewController.view
			case .Project:
				if menuItem.submenu == nil {
					menuItem.submenu = NSMenu()
				}
			default:
				break
			}
		}
		
		allProjectsUser.changeCompletionBlock = { [weak self] _ in
			self?.reloadMenu()
		}
		
		projectManagerObserver.observe(GLAProjectManagerNowProjectDidChangeNotification) { [weak self] _ in
			self?.reloadMenu()
		}
		
		reloadMenu()
	}
	
	public var menu: NSMenu {
		return menuAssistant.menu
	}
	
	private var items: [Item?] {
		var items = [Item?]()
		
		items.append(Item.NowProject)
		items.append(nil)
		
		let projects = (allProjectsUser.copyChildrenLoadingIfNeeded() as! [GLAProject]?) ?? []
		let projectItems: [Item?] = projects.filter({ !$0.hideFromLauncherMenu }).map(Item.Project)
		items += projectItems
		
		items.append(nil)
		items.append(Item.AllProjects)
		items.append(Item.NewProject)
		
		return items
	}
	
	private func reloadMenu() {
		projectManager.loadNowProjectIfNeeded()
		
		menuAssistant.menuItemRepresentatives = self.items
		menuAssistant.update()
	}
}

extension LauncherMenuController {
	private func activateApplication() {
		NSApp.activateIgnoringOtherApps(true)
	}
	
	@IBAction func openProject(menuItem: NSMenuItem) {
		guard let
			item = menuAssistant.itemRepresentativeForMenuItem(menuItem),
			case let .Project(project) = item
			else { return }
		
		navigator.goToProject(project)
	
		activateApplication()
	}
	
	@IBAction func createNewProject(menuItem: NSMenuItem) {
		navigator.addNewProject()
	
		activateApplication()
	}
	
	@IBAction func goToAllProjects(menuItem: NSMenuItem) {
		navigator.goToAllProjects()
	
		activateApplication()
	}
}

extension LauncherMenuController: NSMenuDelegate {
	public func menu(menu: NSMenu, willHighlightItem menuItem: NSMenuItem?) {
		guard let menuItem = menuItem else { return }
		
		guard let item = menuAssistant.itemRepresentativeForMenuItem(menuItem) else { return }
		
		if case let .Project(project) = item {
			let submenu = menuItem.submenu ?? {
				let submenu = NSMenu()
				menuItem.submenu = submenu
				return submenu
			}()
			
			let menuController = projectMenuControllerCache.objectForKey(project.UUID) as! LauncherProjectMenuController? ?? {
				let menuController = LauncherProjectMenuController(menu: submenu, project: project, projectManager: projectManager, navigator: navigator)
				projectMenuControllerCache.setObject(menuController, forKey: project.UUID)
				return menuController
			}()
			
			menuController.update()
		}
	}
}
