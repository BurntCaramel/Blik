//
//  GrainTests.swift
//  GrainTests
//
//  Created by Patrick Smith on 17/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import XCTest
@testable import Grain


enum FileOpenStage: StageProtocol {
	typealias Completion = (text: String, number: Double, arrayOfText: [String])
	
	/// Initial stages
	case read(fileURL: NSURL)
	/// Intermediate stages
	case unserializeJSON(data: NSData)
	case parseJSON(object: AnyObject)
	/// Completed stages
	case success(Completion)
	
	// Any errors thrown by the stages
	enum Error: ErrorType {
		case invalidJSON
		case missingData
	}
}

extension FileOpenStage {
	/// The task for each stage
	var nextTask: Task<FileOpenStage>? {
		switch self {
		case let .read(fileURL):
			return Task{
				.unserializeJSON(
					data: try NSData(contentsOfURL: fileURL, options: .DataReadingMappedIfSafe)
				)
			}
		case let .unserializeJSON(data):
			return Task{
				.parseJSON(
					object: try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
				)
			}
		case let .parseJSON(object):
			return Task{
				guard let dictionary = object as? [String: AnyObject] else {
					throw Error.invalidJSON
				}
				
				guard let
					text = dictionary["text"] as? String,
					number = dictionary["number"] as? Double,
					arrayOfText = dictionary["arrayOfText"] as? [String]
					else { throw Error.missingData }
				
				
				return .success(
					text: text,
					number: number,
					arrayOfText: arrayOfText
				)
			}
		case .success:
			return nil
		}
	}
	
	// The associated value if this is a completion case
	var completion: Completion? {
		guard case let .success(completion) = self else { return nil }
		return completion
	}
}


class GrainTests: XCTestCase {
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	var bundle: NSBundle { return NSBundle(forClass: self.dynamicType) }
	
	func testFileOpen() {
		print("BUNDLE \(bundle.bundleURL)")
		
		guard let fileURL = bundle.URLForResource("example", withExtension: "json") else {
			XCTFail("Could not find file `example.json`")
			return
		}
		
		let expectation = expectationWithDescription("FileOpenStage executed")
		
		FileOpenStage.read(fileURL: fileURL).execute { useResult in
			do {
				let (text, number, arrayOfText) = try useResult()
				XCTAssertEqual(text, "abc")
				XCTAssertEqual(number, 5)
				XCTAssertEqual(arrayOfText.count, 2)
				XCTAssertEqual(arrayOfText[1], "ghi")
			}
			catch {
				XCTFail("Error \(error)")
			}
			
			expectation.fulfill()
		}
		
		waitForExpectationsWithTimeout(3, handler: nil)
	}
}
