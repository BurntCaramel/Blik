//
//  HighlightCustomNameViewController.swift
//  Blik
//
//  Created by Patrick Smith on 24/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntFoundation


class HighlightCustomNameViewController: GLAViewController {
	@IBOutlet var customNameLabel: NSTextField!
	@IBOutlet var customNameField: GLATextField!
	
	enum Notification: String {
		case CustomNameDidChange = "HighlightCustomNameViewController.CustomNameDidChange"
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
	}
	
	override func prepareView() {
		let style = GLAUIStyle.active();
		
		style.prepareTextLabel(customNameLabel)
		style.prepareOutlinedTextField(customNameField)
	}
	
	var chosenCustomName: String {
		return customNameField.stringValue
	}
	
	@IBAction fileprivate func customNameChanged(_ sender: AnyObject) {
		let nc = NotificationCenter.default
		nc.postNotification(Notification.CustomNameDidChange, object: self)
	}
}


class HighlightCustomNamePopover: NSPopover {
	static var sharedPopover: HighlightCustomNamePopover {
		let popover = HighlightCustomNamePopover()
		let viewController = HighlightCustomNameViewController()
		
		popover.highlightCustomNameViewController = viewController
		popover.appearance = NSAppearance(named:NSAppearanceNameVibrantDark)
		popover.behavior = .semitransient
		
		return popover
	}
	
	typealias Notification = HighlightCustomNameViewController.Notification
	
	@IBOutlet var highlightCustomNameViewController: HighlightCustomNameViewController? {
		get {
			return contentViewController as! HighlightCustomNameViewController?
		}
		set(newValue) {
			contentViewController = newValue
			
			setUpViewControllerNotificationObserver()
		}
	}
	
	fileprivate var viewControllerNotificationObserver: NotificationObserver<Notification>!
	fileprivate func setUpViewControllerNotificationObserver() {
		let no = NotificationObserver<Notification>(object: highlightCustomNameViewController!)
		let nc = NotificationCenter.default
		// Forward notifications from view controller
		no.observeAll { notificationIdentifier, _ in
			nc.postNotification(notificationIdentifier, object: self)
		}
		
		viewControllerNotificationObserver = no
	}
	
	func setUpWithHighlightedItem(_ item: GLAHighlightedItem) {
		let viewController = highlightCustomNameViewController!
		_ = viewController.view // Yippee!
		
		viewController.customNameField.stringValue = item.customName ?? ""
	}
	
	var chosenCustomName: String {
		return highlightCustomNameViewController!.chosenCustomName
	}
}

extension HighlightCustomNamePopover {
	static func CustomNameDidChangeNotification() -> String {
		return Notification.CustomNameDidChange.rawValue
	}
}
