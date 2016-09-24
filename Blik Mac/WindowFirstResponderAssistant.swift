//
//  WindowFirstResponderAssistant.swift
//  Blik
//
//  Created by Patrick Smith on 21/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa

private var kvoContext = 0

@objc(GLAWindowFirstResponderAssistant) open class WindowFirstResponderAssistant: NSObject {
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
		window.addObserver(self, forKeyPath: #keyPath(NSWindow.firstResponder), options: .new, context: &kvoContext)
	}
	
	func stopObservingWindow() {
		window.removeObserver(self, forKeyPath: #keyPath(NSWindow.firstResponder))
	}
	
	open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if context == &kvoContext {
      if keyPath == #keyPath(NSWindow.firstResponder) {
				firstResponderDidChange?()
			}
		}
	}
}
