//
//  NowWidgetViewController.swift
//  Blik
//
//  Created by Patrick Smith on 30/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntFoundation
import BurntCocoaUI


struct ProjectChoice : UIChoiceRepresentative {
	var project: GLAProject
	
	var title: String { return project.name }
	
	var uniqueIdentifier: UUID { return project.uuid }
}


class NowWidgetViewController : GLAViewController {
	@IBOutlet var projectPopUpButton: NSPopUpButton?
	@IBOutlet var highlightsViewController: ProjectHighlightsViewController!
	
	fileprivate var projectButtonAssistant: PopUpButtonAssistant<ProjectChoice>?
	
	override func prepareView() {
		super.prepareView()
		
		if let projectPopUpButton = projectPopUpButton {
			projectButtonAssistant = PopUpButtonAssistant(popUpButton: projectPopUpButton)
		}
		
		inspectModel()
		
		preferredContentSize = NSSize(width: 250, height: 140)
		view.frame = NSRect(origin: .zero, size: preferredContentSize)
		
		view.wantsLayer = true
		view.layer!.backgroundColor = GLAUIStyle.active().contentBackgroundColor.cgColor
		
		view.layoutSubtreeIfNeeded()
	}
	
	fileprivate var projectManager: GLAProjectManager { return GLAProjectManager.shared() }
	fileprivate var allProjectsUser: GLALoadableArrayUsing?
	fileprivate var projectManagerObserver: AnyNotificationObserver!
	
	fileprivate func inspectModel() {
		let pm = projectManager
		let projectManagerObserver = AnyNotificationObserver(object: pm)
		
		// All Projects
		
		let allProjectsUser = pm.useAllProjects()
		allProjectsUser.changeCompletionBlock = { projectInspector in
			let projects = projectInspector.copyChildren() as! [GLAProject]
			self.projectButtonAssistant?.menuItemRepresentatives = projects.map { ProjectChoice(project: $0) }
			self.projectButtonAssistant?.update()
		}

		allProjectsUser.inspectLoadingIfNeeded()
		
		// Now Project
		
		projectManagerObserver.observe(NSNotification.Name.GLAProjectManagerNowProjectDidChange.rawValue) { notification in
			guard let nowProject = pm.nowProject else { return }
			
			self.projectButtonAssistant?.selectedUniqueIdentifier = nowProject.uuid
			self.highlightsViewController.project = nowProject
		}
		
		pm.loadNowProjectIfNeeded()
		
		if let nowProject = pm.nowProject {
			projectButtonAssistant?.selectedUniqueIdentifier = nowProject.uuid
			highlightsViewController.project = nowProject
		}
		
		self.allProjectsUser = allProjectsUser
		self.projectManagerObserver = projectManagerObserver
	}
	
	@IBAction func selectProject(_ sender: NSPopUpButton) {
		if let project = projectButtonAssistant?.selectedItemRepresentative?.project {
			projectManager.changeNowProject(project)
		}
	}
}

open class NowWidgetView: NSView {
	#if false
	func ensureWindowIsKey(window: NSWindow?) {
		if let window = window /*where !window.keyWindow*/ {
			window.resignKeyWindow()
			window.becomeKeyWindow()
		}
		
		updateTrackingAreas()
	}
	
	override public func viewWillMoveToSuperview(newSuperview: NSView?) {
		super.viewWillMoveToSuperview(newSuperview)
		
		ensureWindowIsKey(newSuperview?.window)
	}
	
	override public func viewWillMoveToWindow(newWindow: NSWindow?) {
		super.viewWillMoveToWindow(newWindow)
		
		ensureWindowIsKey(newWindow)
	}
	#endif
}
