//
//  FileBookmarkingStage.swift
//  Grain
//
//  Created by Patrick Smith on 24/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import XCTest
@testable import Grain


private let defaultResourceKeys = Array<String>()

private func createBookmarkDataForFileURL(fileURL: NSURL) throws -> NSData {
	if fileURL.startAccessingSecurityScopedResource() {
		defer {
			fileURL.stopAccessingSecurityScopedResource()
		}
	}
	
	return try fileURL.bookmarkDataWithOptions(.WithSecurityScope, includingResourceValuesForKeys: defaultResourceKeys, relativeToURL:nil)
}


enum FileBookmarkingStage: StageProtocol {
	typealias Completion = (fileURL: NSURL, bookmarkData: NSData, wasStale: Bool)
	
	/// Initial stages
	case fileURL(fileURL: NSURL)
	case bookmark(bookmarkData: NSData)
	/// Completed stages
	case resolved(Completion)
}

extension FileBookmarkingStage {
	/// The task for each stage
	var nextTask: Task<FileBookmarkingStage>? {
		switch self {
		case let .fileURL(fileURL):
			return Task{
				.resolved((
					fileURL: fileURL,
					bookmarkData: try createBookmarkDataForFileURL(fileURL),
					wasStale: false
				))
			}
		case let .bookmark(bookmarkData):
			return Task{
				var stale: ObjCBool = false
				// Resolve the bookmark data.
				let fileURL = try NSURL(byResolvingBookmarkData: bookmarkData, options: .WithSecurityScope, relativeToURL: nil, bookmarkDataIsStale: &stale)
				
				var bookmarkData = bookmarkData
				if stale {
					bookmarkData = try createBookmarkDataForFileURL(fileURL)
				}

				return .resolved((
					fileURL: fileURL,
					bookmarkData: bookmarkData,
					wasStale: Bool(stale)
				))
			}
		case .resolved: return nil
		}
	}
	
	var completion: Completion? {
		guard case let .resolved(completion) = self else { return nil }
		return completion
	}
}


class FileBookmarkingTests: XCTestCase {
	var bundle: NSBundle { return NSBundle(forClass: self.dynamicType) }
	
	func testFileAccess() {
		guard let fileURL = bundle.URLForResource("example", withExtension: "json") else {
			return
		}
		
		let bookmarkingCustomizer = GCDExecutionCustomizer<FileBookmarkingStage>()
		let expectation = expectationWithDescription("File accessed")
		
		let accessTask = FileStartAccessingStage.start(fileURL: fileURL).taskExecuting(customizer: GCDExecutionCustomizer())
		
		let bookmarkTask = accessTask.flatMap{ useResult -> Task<FileBookmarkingStage.Completion> in
			let (fileURL, _) = try useResult()
			return FileBookmarkingStage.fileURL(fileURL: fileURL).taskExecuting(customizer: bookmarkingCustomizer)
		}
		
		bookmarkTask.perform { useResult in
			do {
				let result = try useResult()
				XCTAssertEqual(result.fileURL, fileURL)
				XCTAssert(result.bookmarkData.length > 0)
				XCTAssertEqual(result.wasStale, false)
			}
			catch {
				XCTFail("Error \(error)")
			}
			
			expectation.fulfill()
		}
		
		waitForExpectationsWithTimeout(3, handler: nil)
	}
}

