//
//  SystemDirectory.swift
//  BurntFoundation
//
//  Created by Patrick Smith on 26/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation



public class SystemDirectory {
	public typealias ErrorReceiver = (NSError) -> ()
	
	public let pathComponents: [String]
	public let directoryBase: NSSearchPathDirectory
	public let errorReceiver: ErrorReceiver
	private let group: dispatch_group_t
	private var createdDirectoryURL: NSURL?
	
	public init(var pathComponents: [String], inUserDirectory directoryBase: NSSearchPathDirectory, errorReceiver: ErrorReceiver, useBundleIdentifier: Bool = true) {
		if useBundleIdentifier {
			if let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier {
				pathComponents.insert(bundleIdentifier, atIndex: 0)
			}
		}
		
		self.pathComponents = pathComponents
		self.directoryBase = directoryBase
		self.errorReceiver = errorReceiver
		
		group = dispatch_group_create()
		
		createDirectory()
	}
	
	private func directoryURLResolver(fm fm: NSFileManager) throws -> NSURL? {
		return try fm.URLForDirectory(directoryBase, inDomain:.UserDomainMask, appropriateForURL:nil, create:true)
	}
	
	private func createDirectory() {
		let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
		dispatch_group_async(group, queue) {
			let fm = NSFileManager.defaultManager()
			
			do {
				guard let baseDirectoryURL = try self.directoryURLResolver(fm: fm) else { return }
				
				// Convert path to its components, so we can add more components
				// and convert back into a URL.
				var pathComponents = (baseDirectoryURL.pathComponents)!
				pathComponents.appendContentsOf(self.pathComponents)
				
				// Convert components back into a URL.
				guard let directoryURL = NSURL.fileURLWithPathComponents(pathComponents) else { return }
				
				try fm.createDirectoryAtURL(directoryURL, withIntermediateDirectories:true, attributes:nil)
				
				self.createdDirectoryURL = directoryURL
			}
			catch let error as NSError {
				self.errorReceiver(error)
			}
		}
	}
	
	public func useOnQueue(queue: dispatch_queue_t, closure: (directoryURL: NSURL) -> Void) {
		dispatch_group_notify(group, queue) {
			if let createdDirectoryURL = self.createdDirectoryURL {
				closure(directoryURL: createdDirectoryURL)
			}
		}
	}
}
