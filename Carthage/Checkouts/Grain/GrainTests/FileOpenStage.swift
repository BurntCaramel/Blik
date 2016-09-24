//
//	GrainTests.swift
//	GrainTests
//
//	Created by Patrick Smith on 17/03/2016.
//	Copyright © 2016 Burnt Caramel. All rights reserved.
//

import XCTest
@testable import Grain


enum FileUnserializeStage : StageProtocol {
	typealias Result = (text: String, number: Double, arrayOfText: [String])
	
	/// Initial stages
	case open(fileURL: URL)
	/// Intermediate stages
	case read(access: FileAccessStage)
	case unserializeJSON(data: Data)
	case parseJSON(object: AnyObject)
	/// Completed stages
	case success(Result)
	
	// Any errors thrown by the stages
	enum Error : Error {
		case cannotAccess
		case invalidJSON
		case missingInformation
	}
}

extension FileUnserializeStage {
	/// The task for each stage
	func next() -> Deferred<FileUnserializeStage> {
		switch self {
		case let .open(fileURL):
			return Deferred{ .read(
				access: .start(fileURL: fileURL, forgiving: false)
			) }
				/*return .unserializeJSON(
					data: try NSData(contentsOfURL: fileURL, options: .DataReadingMappedIfSafe)
				)*/
		case let .read(access):
			return access.compose(
				transformNext: FileUnserializeStage.read,
				transformResult: { (result) -> Deferred<FileUnserializeStage> in
					let next = Deferred<FileUnserializeStage>{
						if result.hasAccess {
							return .unserializeJSON(
								data: try NSData(contentsOfURL: result.fileURL, options: .DataReadingMappedIfSafe)
							)
						}
						else {
							throw Error.cannotAccess
						}
					}
					
					return result.stopper.map{ next.withCleanUp($0.taskExecuting()) } ?? next
				}
			)
		case let .unserializeJSON(data):
			return Deferred{ .parseJSON(
				object: try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
				) }
		case let .parseJSON(object):
			return Deferred{
				guard let dictionary = object as? [String: AnyObject] else {
					throw Error.invalidJSON
				}
				
				guard let
					text = dictionary["text"] as? String,
					let number = dictionary["number"] as? Double,
					let arrayOfText = dictionary["arrayOfText"] as? [String]
					else { throw Error.missingInformation }
				
				return .success(
					text: text,
					number: number,
					arrayOfText: arrayOfText
				)
			}
		case .success:
			completedStage(self)
		}
	}
	
	// The associated value if this is a completion case
	var result: Result? {
		guard case let .success(result) = self else { return nil }
		return result
	}
}


class GrainTests : XCTestCase {
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	var bundle: Bundle { return Bundle(for: type(of: self)) }
	
	func testFileOpen() {
		print("BUNDLE \(bundle.bundleURL)")
		
		guard let fileURL = bundle.url(forResource: "example", withExtension: "json") else {
			XCTFail("Could not find file `example.json`")
			return
		}
		
		let expectation = self.expectation(description: "FileUnserializeStage executed")
		
		FileUnserializeStage.open(fileURL: fileURL).execute { useResult in
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
		
		waitForExpectations(timeout: 3, handler: nil)
	}
}
