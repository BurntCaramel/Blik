//
//  NotificationObserver.swift
//  BurntFoundation
//
//  Created by Patrick Smith on 11/05/2015.
//  Copyright (c) 2015 Patrick Smith. All rights reserved.
//

import Foundation


public class NotificationObserver<NotificationIdentifier: RawRepresentable where NotificationIdentifier.RawValue == String, NotificationIdentifier: Hashable> {
	public let object: AnyObject
	public let notificationCenter: NSNotificationCenter
	let operationQueue: NSOperationQueue
	
	var observers = [String: AnyObject]()
	
	public init(object: AnyObject, notificationCenter: NSNotificationCenter, queue: NSOperationQueue) {
		self.object = object
		self.notificationCenter = notificationCenter
		self.operationQueue = queue
	}
	
	public convenience init(object: AnyObject) {
		self.init(object: object, notificationCenter: NSNotificationCenter.defaultCenter(), queue: NSOperationQueue.mainQueue())
	}
	
	public func addObserver(notificationIdentifier: String, block: (NSNotification!) -> Void) {
		let observer = notificationCenter.addObserverForName(notificationIdentifier, object: object, queue: operationQueue, usingBlock: block)
		observers[notificationIdentifier] = observer
	}
	
	public func removeObserver(notificationIdentifier: String) {
		if let observer: AnyObject = observers[notificationIdentifier] {
			notificationCenter.removeObserver(observer)
			observers.removeValueForKey(notificationIdentifier)
		}
	}
	
	public func addObserver(notificationIdentifier: NotificationIdentifier, block: (NSNotification!) -> Void) {
		addObserver(notificationIdentifier.rawValue, block: block)
	}
	
	public func removeObserver(notificationIdentifier: NotificationIdentifier) {
		removeObserver(notificationIdentifier.rawValue)
	}
	
	public func removeAllObservers() {
		for (notificationIdentifier, observer) in observers {
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


public struct AnyStringNotificationIdentifier: RawRepresentable, Hashable {
	public typealias RawValue = String
	public var rawValue: RawValue
	
	public init?(rawValue: RawValue) {
		self.rawValue = rawValue
	}
	
	public var hashValue: Int { return rawValue.hashValue }
}

public func == (lhs: AnyStringNotificationIdentifier, rhs: AnyStringNotificationIdentifier) -> Bool {
	return lhs.rawValue == rhs.rawValue
}
