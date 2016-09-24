//
//  NotificationObserver.swift
//  BurntFoundation
//
//  Created by Patrick Smith on 11/05/2015.
//  Copyright (c) 2015 Patrick Smith. All rights reserved.
//

import Foundation


public protocol NotificationObserverType {
	associatedtype NotificationIdentifier
	associatedtype Notification
	
	mutating func observe(_ notificationIdentifier: NotificationIdentifier, block: @escaping (Notification) -> ())
	mutating func observeAll(_ block: @escaping (NotificationIdentifier, Notification) -> ())
	mutating func stopObserving(_ notificationIdentifier: NotificationIdentifier)
	mutating func stopObservingAll()
	mutating func stopObserving()
}


public class NotificationObserver
<I: RawRepresentable> : NotificationObserverType where I.RawValue == String, I: Hashable
{
	public typealias NotificationIdentifier = I
	public typealias Notification = Foundation.Notification!
	
	public let object: AnyObject
	public let notificationCenter: NotificationCenter
	public let operationQueue: OperationQueue
	
	fileprivate var observers = [NotificationIdentifier: AnyObject]()
	fileprivate var allObserver: AnyObject?
	
	public init(object: AnyObject, notificationCenter: NotificationCenter, queue: OperationQueue = OperationQueue.main) {
		self.object = object
		self.notificationCenter = notificationCenter
		self.operationQueue = queue
	}
	
	public convenience init(object: AnyObject) {
		self.init(object: object, notificationCenter: NotificationCenter.default)
	}
	
	public func observe(_ notificationIdentifier: NotificationIdentifier, block: @escaping (Notification) -> ()) {
		assert(observers[notificationIdentifier] == nil, "Existing observer for \(notificationIdentifier) must be removed first")
		
		observers[notificationIdentifier] = notificationCenter.addObserver(forName: NSNotification.Name(rawValue: notificationIdentifier.rawValue), object: object, queue: operationQueue, using: block)
	}
	
	public func observeAll(_ block: @escaping (NotificationIdentifier, Notification) -> ()) {
		assert(allObserver == nil, "Existing observer for all must be removed first")
		
		allObserver = notificationCenter.addObserver(forName: nil, object: object, queue: operationQueue) { notification in
			guard let notificationIdentifier = NotificationIdentifier(rawValue: notification.name.rawValue)
        else { return }
			
			block(notificationIdentifier, notification)
		}
	}
	
	public func stopObserving(_ notificationIdentifier: NotificationIdentifier) {
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


public extension NotificationCenter {
	public func postNotification
		<NotificationIdentifier : RawRepresentable>
		(_ notificationIdentifier: NotificationIdentifier, object: AnyObject, userInfo: [String:AnyObject]? = nil) where NotificationIdentifier.RawValue == String
	{
		post(name: Notification.Name(rawValue: notificationIdentifier.rawValue), object: object, userInfo: userInfo)
	}
}



public class AnyNotificationObserver : NotificationObserverType {
	public typealias NotificationIdentifier = String
	public typealias Notification = Foundation.Notification!
	
	public let object: AnyObject
	public let notificationCenter: NotificationCenter
	public let operationQueue: OperationQueue
	
	fileprivate let underlyingObserver: NotificationObserver<AnyStringNotificationIdentifier>
	
	public init(object: AnyObject, notificationCenter: NotificationCenter, queue: OperationQueue = OperationQueue.main) {
		self.object = object
		self.notificationCenter = notificationCenter
		self.operationQueue = queue
		self.underlyingObserver = NotificationObserver(object: object, notificationCenter: notificationCenter, queue: queue)
	}
	
	public convenience init(object: AnyObject) {
		self.init(object: object, notificationCenter: NotificationCenter.default)
	}
	
	public func observe(_ notificationIdentifier: NotificationIdentifier, block: @escaping (Foundation.Notification!) -> ()) {
		underlyingObserver.observe(AnyStringNotificationIdentifier(string: notificationIdentifier), block: block)
	}
	
	public func observeAll(_ block: @escaping (NotificationIdentifier, Notification) -> ()) {
		underlyingObserver.observeAll { notificationIdentifier, notification in
			block(notificationIdentifier.rawValue, notification)
		}
	}
	
	public func stopObserving(_ notificationIdentifier: NotificationIdentifier) {
		underlyingObserver.stopObserving(AnyStringNotificationIdentifier(string: notificationIdentifier))
	}
	
	public func stopObservingAll() {
		underlyingObserver.stopObservingAll()
	}
	
	public func stopObserving() {
		underlyingObserver.stopObserving()
	}
}


private struct AnyStringNotificationIdentifier : RawRepresentable, Hashable {
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
