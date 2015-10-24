//
//  NotificationObserver.swift
//  BurntFoundation
//
//  Created by Patrick Smith on 11/05/2015.
//  Copyright (c) 2015 Patrick Smith. All rights reserved.
//

import Foundation


public protocol NotificationObserverType {
	typealias NotificationIdentifier
	typealias Notification
	
	mutating func observe(notificationIdentifier: NotificationIdentifier, block: (Notification) -> ())
	mutating func observeAll(block: (NotificationIdentifier, Notification) -> ())
	mutating func stopObserving(notificationIdentifier: NotificationIdentifier)
	mutating func stopObservingAll()
	mutating func stopObserving()
}


public class NotificationObserver<I: RawRepresentable where I.RawValue == String, I: Hashable>: NotificationObserverType {
	public typealias NotificationIdentifier = I
	public typealias Notification = NSNotification!
	
	public let object: AnyObject
	public let notificationCenter: NSNotificationCenter
	public let operationQueue: NSOperationQueue
	
	private var observers = [NotificationIdentifier: AnyObject]()
	private var allObserver: AnyObject?
	
	public init(object: AnyObject, notificationCenter: NSNotificationCenter, queue: NSOperationQueue = NSOperationQueue.mainQueue()) {
		self.object = object
		self.notificationCenter = notificationCenter
		self.operationQueue = queue
	}
	
	public convenience init(object: AnyObject) {
		self.init(object: object, notificationCenter: NSNotificationCenter.defaultCenter())
	}
	
	public func observe(notificationIdentifier: NotificationIdentifier, block: (Notification) -> ()) {
		assert(observers[notificationIdentifier] == nil, "Existing observer for \(notificationIdentifier) must be removed first")
		
		observers[notificationIdentifier] = notificationCenter.addObserverForName(notificationIdentifier.rawValue, object: object, queue: operationQueue, usingBlock: block)
	}
	
	public func observeAll(block: (NotificationIdentifier, Notification) -> ()) {
		assert(allObserver == nil, "Existing observer for all must be removed first")
		
		allObserver = notificationCenter.addObserverForName(nil, object: object, queue: operationQueue) { notification in
			guard let notificationIdentifier = NotificationIdentifier(rawValue: notification.name) else { return }
			
			block(notificationIdentifier, notification)
		}
	}
	
	public func stopObserving(notificationIdentifier: NotificationIdentifier) {
		guard let observer = observers[notificationIdentifier] else { return }
		
		notificationCenter.removeObserver(observer)
		observers[notificationIdentifier] = nil
	}
	
	public func stopObservingAll() {
		guard let observer = allObserver else { return }
		
		notificationCenter.removeObserver(observer)
		allObserver = nil
	}
	
	public func stopObserving() {
		for (_, observer) in observers {
			notificationCenter.removeObserver(observer)
		}
		observers.removeAll()
		
		stopObservingAll()
	}
	
	 deinit {
		stopObserving()
	}
}


public extension NSNotificationCenter {
	public func postNotification
		<NotificationIdentifier: RawRepresentable where NotificationIdentifier.RawValue == String>
		(notificationIdentifier: NotificationIdentifier, object: AnyObject, userInfo: [String:AnyObject]? = nil)
	{
		postNotificationName(notificationIdentifier.rawValue, object: object, userInfo: userInfo)
	}
}



public class AnyNotificationObserver: NotificationObserverType {
	public typealias NotificationIdentifier = String
	public typealias Notification = NSNotification!
	
	public let object: AnyObject
	public let notificationCenter: NSNotificationCenter
	public let operationQueue: NSOperationQueue
	
	private let underlyingObserver: NotificationObserver<AnyStringNotificationIdentifier>
	
	public init(object: AnyObject, notificationCenter: NSNotificationCenter, queue: NSOperationQueue = NSOperationQueue.mainQueue()) {
		self.object = object
		self.notificationCenter = notificationCenter
		self.operationQueue = queue
		self.underlyingObserver = NotificationObserver(object: object, notificationCenter: notificationCenter, queue: queue)
	}
	
	public convenience init(object: AnyObject) {
		self.init(object: object, notificationCenter: NSNotificationCenter.defaultCenter())
	}
	
	public func observe(notificationIdentifier: NotificationIdentifier, block: (NSNotification!) -> Void) {
		underlyingObserver.observe(AnyStringNotificationIdentifier(string: notificationIdentifier), block: block)
	}
	
	public func observeAll(block: (NotificationIdentifier, Notification) -> ()) {
		underlyingObserver.observeAll { notificationIdentifier, notification in
			block(notificationIdentifier.rawValue, notification)
		}
	}
	
	public func stopObserving(notificationIdentifier: NotificationIdentifier) {
		underlyingObserver.stopObserving(AnyStringNotificationIdentifier(string: notificationIdentifier))
	}
	
	public func stopObservingAll() {
		underlyingObserver.stopObservingAll()
	}
	
	public func stopObserving() {
		underlyingObserver.stopObserving()
	}
}


private struct AnyStringNotificationIdentifier: RawRepresentable, Hashable {
	typealias RawValue = String
	var rawValue: RawValue
	
	init(string: String) {
		self.rawValue = string
	}
	
	init?(rawValue: RawValue) {
		self.init(string: rawValue)
	}
	
	var hashValue: Int { return rawValue.hashValue }
}

private func == (lhs: AnyStringNotificationIdentifier, rhs: AnyStringNotificationIdentifier) -> Bool {
	return lhs.rawValue == rhs.rawValue
}
