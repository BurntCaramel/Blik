//
//  FileAccessingStage.swift
//  Grain
//
//  Created by Patrick Smith on 24/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import XCTest
@testable import Grain


enum FileAccessingStage: StageProtocol {
	/// Initial stages
	case start(fileURL: NSURL)
	case stop(fileURL: NSURL, accessSucceeded: Bool)
	/// Completed stages
	case started(fileURL: NSURL, accessSucceeded: Bool)
	case stopped(fileURL: NSURL)
}

extension FileAccessingStage {
	func asStarted() throws -> (fileURL: NSURL, accessSucceeded: Bool) {
		guard case let .started(fileURL, accessSucceeded) = self else {
			throw StageError.stageInvalid(self)
		}
		
		return (fileURL, accessSucceeded)
	}
}

extension FileAccessingStage {
	/// The task for each stage
	var nextTask: Task<FileAccessingStage>? {
		switch self {
		case let .start(fileURL):
			return Task{
				let accessSucceeded = fileURL.startAccessingSecurityScopedResource()
				
				return .started(
					fileURL: fileURL,
					accessSucceeded: accessSucceeded
				)
			}
		case let .stop(fileURL, accessSucceeded):
			return Task{
				if accessSucceeded {
					fileURL.stopAccessingSecurityScopedResource()
				}
				
				return .stopped(
					fileURL: fileURL
				)
			}
		case .started, .stopped:
			return nil
		}
	}
}


class FileAccessingTests: XCTestCase {
	var bundle: NSBundle { return NSBundle(forClass: self.dynamicType) }
	
	func testFileAccess() {
		guard let fileURL = bundle.URLForResource("example", withExtension: "json") else {
			return
		}
		
		let expectation = expectationWithDescription("File accessed")
		
		FileAccessingStage.start(fileURL: fileURL).execute { useResult in
			do {
				let result = try useResult()
				if case let .started(fileURL2, accessSucceeded) = result {
					XCTAssertEqual(fileURL, fileURL2)
					XCTAssertEqual(accessSucceeded, true)
				}
				else {
					XCTFail("Unexpected result \(result)")
				}
			}
			catch {
				XCTFail("Error \(error)")
			}
			
			expectation.fulfill()
		}
		
		waitForExpectationsWithTimeout(3, handler: nil)
	}
}


