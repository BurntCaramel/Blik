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
	
	mutating func addObserver(notificationIdentifier: NotificationIdentifier, block: (Notification) -> Void)
	mutating func removeObserver(notificationIdentifier: NotificationIdentifier)
	mutating func removeAllObservers()
}


public class NotificationObserver<I: RawRepresentable where I.RawValue == String, I: Hashable>: NotificationObserverType {
	public typealias NotificationIdentifier = I
	public typealias Notification = NSNotification!
	
	public let object: AnyObject
	public let notificationCenter: NSNotificationCenter
	public let operationQueue: NSOperationQueue
	
	private var observers = [NotificationIdentifier: AnyObject]()
	
	public init(object: AnyObject, notificationCenter: NSNotificationCenter, queue: NSOperationQueue = NSOperationQueue.mainQueue()) {
		self.object = object
		self.notificationCenter = notificationCenter
		self.operationQueue = queue
	}
	
	public convenience init(object: AnyObject) {
		self.init(object: object, notificationCenter: NSNotificationCenter.defaultCenter())
	}
	
	public func addObserver(notificationIdentifier: NotificationIdentifier, block: (Notification) -> Void) {
		let observer = notificationCenter.addObserverForName(notificationIdentifier.rawValue, object: object, queue: operationQueue, usingBlock: block)
		observers[notificationIdentifier] = observer
	}
	
	public func removeObserver(notificationIdentifier: NotificationIdentifier) {
		if let observer: AnyObject = observers[notificationIdentifier] {
			notificationCenter.removeObserver(observer)
			observers.removeValueForKey(notificationIdentifier)
		}
	}
	
	public func removeAllObservers() {
		for (_, observer) in observers {
			notificationCenter.removeObserver(observer)
		}
		observers.removeAll()
	}
	
	 deinit {
		removeAllObservers()
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
	
	public func addObserver(notificationIdentifier: NotificationIdentifier, block: (NSNotification!) -> Void) {
		underlyingObserver.addObserver(AnyStringNotificationIdentifier(string: notificationIdentifier), block: block)
	}
	
	public func removeObserver(notificationIdentifier: NotificationIdentifier) {
		underlyingObserver.removeObserver(AnyStringNotificationIdentifier(string: notificationIdentifier))
	}
	
	public func removeAllObservers() {
		underlyingObserver.removeAllObservers()
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
