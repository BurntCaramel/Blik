//
//  NotificationTests.swift
//  BurntFoundationTests
//
//  Created by Patrick Smith on 16/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import XCTest
import BurntFoundation


private class Example {
	enum Notification: String {
		case DidUpdate = "NotificationTestsDidUpdateNotification"
		case DidDoSomethingElse = "NotificationTestsDidDoSomethingElseNotification"
	}
}


class NotificationTests: XCTestCase {
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testObserving() {
		let nc = NSNotificationCenter()
		let object = Example()
		
		let expectation = expectationWithDescription("Observed .DidUpdate notification")
		
		let notificationObserver = NotificationObserver<Example.Notification>(object: object, notificationCenter: nc, queue: NSOperationQueue.mainQueue())
		notificationObserver.observe(.DidUpdate) { notification in
			expectation.fulfill()
		}
		
		NSOperationQueue.mainQueue().addOperationWithBlock {
			withExtendedLifetime(notificationObserver) {
				nc.postNotificationName(Example.Notification.DidUpdate.rawValue, object: object)
			}
		}
		
		waitForExpectationsWithTimeout(2) { error in
		}
	}
	
	func testObservingAll() {
		let nc = NSNotificationCenter()
		let object = Example()
		
		let expectations: [Example.Notification: XCTestExpectation] = [
			.DidUpdate: expectationWithDescription("Observed .DidUpdate notification"),
			.DidDoSomethingElse: expectationWithDescription("Observed .DidDoSomethingElse notification")
		]
		
		let notificationObserver = NotificationObserver<Example.Notification>(object: object, notificationCenter: nc, queue: NSOperationQueue.mainQueue())
		notificationObserver.observeAll { identifier, notification in
			XCTAssertNotNil(expectations[identifier])
			
			expectations[identifier]!.fulfill()
		}
		
		NSOperationQueue.mainQueue().addOperationWithBlock {
			withExtendedLifetime(notificationObserver) {
				nc.postNotificationName(Example.Notification.DidUpdate.rawValue, object: object)
				nc.postNotificationName(Example.Notification.DidDoSomethingElse.rawValue, object: object)
			}
		}
		
		waitForExpectationsWithTimeout(2) { error in
		}
	}
	
	func testPosting() {
		let nc = NSNotificationCenter.defaultCenter()
		let object = Example()
		
		let expectation = expectationForNotification(Example.Notification.DidUpdate.rawValue, object: object, handler: nil)
		
		NSOperationQueue.mainQueue().addOperationWithBlock {
			withExtendedLifetime(expectation) {
				nc.postNotification(Example.Notification.DidUpdate, object: object, userInfo: nil)
			}
		}
		
		waitForExpectationsWithTimeout(2) { error in
		}
	}
	
}
