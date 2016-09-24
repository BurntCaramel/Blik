//
//  BurntFoundationTests.swift
//  BurntFoundationTests
//
//  Created by Patrick Smith on 16/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import XCTest
import BurntFoundation


class UserDefaultsTests: XCTestCase {
	enum ExampleIntChoice: Int, UserDefaultsChoiceRepresentable {
		case one = 1
		case two = 2
		case three = 3
		
		static var identifier: String = "exampleInt"
		static var defaultValue = ExampleIntChoice.one
	}
	
	enum ExampleStringChoice: String, UserDefaultsChoiceRepresentable {
		case Apple = "apple"
		case Banana = "banana"
		case Carrot = "carrot"
		
		static var identifier: String = "exampleString"
		static var defaultValue = ExampleStringChoice.Apple
	}
	
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testIntChoice() {
		let ud = UserDefaults()
		
		ud.set(3, forKey: ExampleIntChoice.identifier)
		XCTAssertEqual(ud.choice(ExampleIntChoice.self), ExampleIntChoice.three, "Set integer, get choice")
		
		ud.setChoice(ExampleIntChoice.two)
		XCTAssertEqual(ud.integer(forKey: ExampleIntChoice.identifier), 2, "Set choice, get integer")
    }
	
	func testStringChoice() {
		let ud = UserDefaults()
		
		ud.set("banana", forKey: ExampleStringChoice.identifier)
		XCTAssertEqual(ud.choice(ExampleStringChoice.self), ExampleStringChoice.Banana, "Set string, get choice")
		
		ud.setChoice(ExampleStringChoice.Carrot)
		XCTAssertEqual(ud.string(forKey: ExampleStringChoice.identifier)!, "carrot", "Set choice, get string")
	}
	
}
