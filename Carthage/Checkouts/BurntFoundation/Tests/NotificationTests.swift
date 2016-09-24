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
		let nc = NotificationCenter()
		let object = Example()
		
		let expectation = self.expectation(description: "Observed .DidUpdate notification")
		
		let notificationObserver = NotificationObserver<Example.Notification>(object: object, notificationCenter: nc, queue: OperationQueue.main)
		notificationObserver.observe(.DidUpdate) { notification in
			expectation.fulfill()
		}
		
		OperationQueue.main.addOperation {
			withExtendedLifetime(notificationObserver) {
				nc.post(name: Notification.Name(rawValue: Example.Notification.DidUpdate.rawValue), object: object)
			}
		}
		
		waitForExpectations(timeout: 2) { error in
		}
	}
	
	func testObservingAll() {
		let nc = NotificationCenter()
		let object = Example()
		
		let expectations: [Example.Notification: XCTestExpectation] = [
			.DidUpdate: expectation(description: "Observed .DidUpdate notification"),
			.DidDoSomethingElse: expectation(description: "Observed .DidDoSomethingElse notification")
		]
		
		let notificationObserver = NotificationObserver<Example.Notification>(object: object, notificationCenter: nc, queue: OperationQueue.main)
		notificationObserver.observeAll { identifier, notification in
			XCTAssertNotNil(expectations[identifier])
			
			expectations[identifier]!.fulfill()
		}
		
		OperationQueue.main.addOperation {
			withExtendedLifetime(notificationObserver) {
				nc.post(name: Notification.Name(rawValue: Example.Notification.DidUpdate.rawValue), object: object)
				nc.post(name: Notification.Name(rawValue: Example.Notification.DidDoSomethingElse.rawValue), object: object)
			}
		}
		
		waitForExpectations(timeout: 2) { error in
		}
	}
	
	func testPosting() {
		let nc = NotificationCenter.default
		let object = Example()
		
		let expectation = self.expectation(forNotification: Example.Notification.DidUpdate.rawValue, object: object, handler: nil)
		
		OperationQueue.main.addOperation {
			withExtendedLifetime(expectation) {
				nc.postNotification(Example.Notification.DidUpdate, object: object, userInfo: nil)
			}
		}
		
		waitForExpectations(timeout: 2) { error in
		}
	}
	
}
