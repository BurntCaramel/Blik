//
//  AppDelegate.swift
//  Blik
//
//  Created by Patrick Smith on 30/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


@objc(GLAAppDelegate) class AppDelegate: NSObject, NSApplicationDelegate {
	var mainWindowController: GLAMainWindowController!
	
	var desktopWidgetWindowController: DesktopWidgetWindowController!
	
	var statusItemController: GLAStatusItemController!
	
	@IBOutlet var mainHelpMenu: NSMenu!
	@IBOutlet var helpGuidesPlaceholderMenuItem: NSMenuItem!
	@IBOutlet var activityStatusMenuItem: NSMenuItem!
	
	@IBOutlet var buyMenuItem: NSMenuItem!
	@IBOutlet var buyMacAppStoreMenuItem: NSMenuItem!
	
	@IBOutlet var creatorThoughtsMenu: NSMenu!
	
	
	var hasPrepared: Bool = false
	
	var creatorThoughtsAssistant: CreatorThoughtsAssistant!
	var helpGuidesAssistant: GuideArticlesAssistant!
}

func isShowingWindowController(windowController: NSWindowController?) -> Bool {
	if let windowController = windowController where windowController.windowLoaded {
		return windowController.window!.visible
	}
	else {
		return false
	}
}

extension AppDelegate {
	func createMainWindowController() {
		if mainWindowController == nil {
			self.mainWindowController = GLAMainWindowController(windowNibName: "GLAMainWindowController")
		}
	}
	
	func showMainWindow() {
		createMainWindowController()
	
		mainWindowController.window!.makeKeyAndOrderFront(self)
	}
	
	func hideMainWindow() {
		mainWindowController.window?.close()
	}
	
	var showingMainWindowController: Bool {
		return isShowingWindowController(mainWindowController)
	}
}

extension AppDelegate {
	func createDesktopWidgetWindowController() {
		if desktopWidgetWindowController == nil {
			self.desktopWidgetWindowController = DesktopWidgetWindowController(windowNibName: "DesktopWidgetWindow")
		}
	}
	
	func showDesktopWidget() {
		createDesktopWidgetWindowController()
		
		desktopWidgetWindowController.window!.makeKeyAndOrderFront(self)
	}
	
	func hideDesktopWidget() {
		desktopWidgetWindowController.window?.close()
	}
	
	var showingDesktopWidget: Bool {
		return isShowingWindowController(desktopWidgetWindowController)
	}
}
