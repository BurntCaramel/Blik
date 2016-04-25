//
//  FileAccessingStage.swift
//  Grain
//
//  Created by Patrick Smith on 24/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import XCTest
@testable import Grain


enum FileStartAccessingStage: StageProtocol {
	typealias Completion = (fileURL: NSURL, accessSucceeded: Bool)
	
	/// Initial stages
	case start(fileURL: NSURL)
	
	case started(Completion)
}

enum FileStopAccessingStage: StageProtocol {
	typealias Completion = NSURL
	
	/// Initial stages
	case stop(fileURL: NSURL, accessSucceeded: Bool)
	
	case stopped(fileURL: NSURL)
}

extension FileStartAccessingStage {
	/// The task for each stage
	var nextTask: Task<FileStartAccessingStage>? {
		switch self {
		case let .start(fileURL):
			return Task{
				let accessSucceeded = fileURL.startAccessingSecurityScopedResource()
				
				return .started(
					fileURL: fileURL,
					accessSucceeded: accessSucceeded
				)
			}
		case .started: return nil
		}
	}
	
	var completion: Completion? {
		guard case let .started(completion) = self else { return nil }
		return completion
	}
}

extension FileStopAccessingStage {
	/// The task for each stage
	var nextTask: Task<FileStopAccessingStage>? {
		switch self {
		case let .stop(fileURL, accessSucceeded):
			return Task{
				if accessSucceeded {
					fileURL.stopAccessingSecurityScopedResource()
				}
				
				return .stopped(
					fileURL: fileURL
				)
			}
		case .stopped: return nil
		}
	}
	
	var completion: NSURL? {
		guard case let .stopped(fileURL) = self else { return nil }
		return fileURL
	}
}


class FileAccessingTests: XCTestCase {
	var bundle: NSBundle { return NSBundle(forClass: self.dynamicType) }
	
	func testFileAccess() {
		guard let fileURL = bundle.URLForResource("example", withExtension: "json") else {
			return
		}
		
		let expectation = expectationWithDescription("File accessed")
		
		FileStartAccessingStage.start(fileURL: fileURL).execute { useResult in
			do {
				let result = try useResult()
				XCTAssertEqual(result.fileURL, fileURL)
				XCTAssertEqual(result.accessSucceeded, true)
			}
			catch {
				XCTFail("Error \(error)")
			}
			
			expectation.fulfill()
		}
		
		waitForExpectationsWithTimeout(3, handler: nil)
	}
}


