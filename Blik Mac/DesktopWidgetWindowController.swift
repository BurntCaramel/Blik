//
//  DesktopWidgetWindowController.swift
//  Blik
//
//  Created by Patrick Smith on 30/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


@objc(GLADesktopWidgetWindowController) class DesktopWidgetWindowController: NSWindowController {
	@IBOutlet private var mainViewController: DesktopWidgetMainViewController!
	
	override func windowDidLoad() {
		let window = self.window!
		window.movableByWindowBackground = true
		
		window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
		
		window.title = NSLocalizedString("Blik Desktop Widget", comment: "Title for main window as it appears in Mission Control")
		//(window.level) = CGWindowLevelForKey(kCGDesktopIconWindowLevelKey) - 1;
		
		NSApp.addWindowsItem(window, title: NSLocalizedString("Desktop Widget", comment: "Title for desktop widget as it appears in the Windows menu"), filename: false)
		
		setUpContentView()
	}
	
	func setUpContentView() {
		let contentView = mainViewController.view
		contentView.wantsLayer = true
		contentView.layer!.backgroundColor = GLAUIStyle.activeStyle().contentBackgroundColor.CGColor
	}
}
