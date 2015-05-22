//
//  WindowFirstResponderAssistant.swift
//  Blik
//
//  Created by Patrick Smith on 21/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


@objc(GLAWindowFirstResponderAssistant) public class WindowFirstResponderAssistant: NSObject {
	let window: NSWindow
	
	var firstResponderDidChange: (() -> Void)?
	
	public init(window: NSWindow) {
		self.window = window
		
		super.init()
		
		startObservingWindow()
	}
	
	deinit {
		stopObservingWindow()
	}
	
	func startObservingWindow() {
		window.addObserver(self, forKeyPath: "firstResponder", options: .New, context: nil)
	}
	
	func stopObservingWindow() {
		window.removeObserver(self, forKeyPath: "firstResponder")
	}
	
	public override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
		if object === window {
			if keyPath == "firstResponder" {
				firstResponderDidChange?()
			}
		}
	}
}
