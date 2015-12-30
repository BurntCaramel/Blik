//
//  DesktopWidgetMainViewController.swift
//  Blik
//
//  Created by Patrick Smith on 30/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntFoundation
import BurntCocoaUI


struct ProjectChoice: UIChoiceRepresentative {
	var project: GLAProject
	
	var title: String { return project.name }
	
	var uniqueIdentifier: NSUUID { return project.UUID }
}


class DesktopWidgetMainViewController: GLAViewController {
	@IBOutlet var projectPopUpButton: NSPopUpButton!
	
	private var projectButtonAssistant: PopUpButtonAssistant<ProjectChoice>!
	//private var highlightsViewController: ProjectHighlightsViewController!
	
	override func prepareView() {
		super.prepareView()
		
		projectButtonAssistant = PopUpButtonAssistant(popUpButton: projectPopUpButton)
		
		inspectModel()
	}
	
	private var projectManager: GLAProjectManager { return GLAProjectManager.sharedProjectManager() }
	private var allProjectsUser: GLALoadableArrayUsing?
	private var projectManagerObserver: AnyNotificationObserver!
	
	private func inspectModel() {
		let pm = projectManager
		let projectManagerObserver = AnyNotificationObserver(object: pm)
		
		// All Projects
		
		let allProjectsUser = pm.useAllProjects()
		allProjectsUser.changeCompletionBlock = { projectInspector in
			let projects = projectInspector.copyChildren() as! [GLAProject]
			print("PROJECTS \(projects)")
			self.projectButtonAssistant.menuItemRepresentatives = projects.map { ProjectChoice(project: $0) }
			self.projectButtonAssistant.update()
		}

		allProjectsUser.inspectLoadingIfNeeded()
		
		// Now Project
		
		projectManagerObserver.observe(GLAProjectManagerNowProjectDidChangeNotification) { notification in
			self.projectButtonAssistant.selectedUniqueIdentifier = pm.nowProject?.UUID
		}
		
		pm.loadNowProjectIfNeeded()
		projectButtonAssistant.selectedUniqueIdentifier = pm.nowProject?.UUID
		
		self.allProjectsUser = allProjectsUser
		self.projectManagerObserver = projectManagerObserver
	}
	
	@IBAction func selectProject(sender: NSPopUpButton) {
		if let project = projectButtonAssistant.selectedItemRepresentative?.project {
			projectManager.changeNowProject(project)
		}
	}
}
