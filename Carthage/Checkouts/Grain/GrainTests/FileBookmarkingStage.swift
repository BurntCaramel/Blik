//
//	FileBookmarkingStage.swift
//	Grain
//
//	Created by Patrick Smith on 24/03/2016.
//	Copyright © 2016 Burnt Caramel. All rights reserved.
//

import XCTest
@testable import Grain


private let defaultResourceKeys = Array<String>()

private func createBookmarkDataForFileURL(_ fileURL: URL) throws -> Data {
	return try (fileURL as NSURL).bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: defaultResourceKeys, relativeTo:nil)
}


enum FileBookmarkingStage: StageProtocol {
	typealias Result = (fileURL: URL, bookmarkData: Data, wasStale: Bool)
	
	/// Initial stages
	case fileURL(fileURL: URL)
	case bookmark(bookmarkData: Data)
	/// Completed stages
	case resolved(Result)
}

extension FileBookmarkingStage {
	/// The task for each stage
	func next() -> Deferred<FileBookmarkingStage> {
		switch self {
		case let .fileURL(fileURL):
			return Deferred{
				.resolved((
					fileURL: fileURL,
					bookmarkData: try createBookmarkDataForFileURL(fileURL),
					wasStale: false
				))
			}
		case let .bookmark(bookmarkData):
			return Deferred{
				var stale: ObjCBool = false
				// Resolve the bookmark data.
				let fileURL = try (NSURL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale) as URL)
				
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
		case .resolved: completedStage(self)
		}
	}
	
	var result: Result? {
		guard case let .resolved(result) = self else { return nil }
		return result
	}
}


class FileBookmarkingTests: XCTestCase {
	var bundle: Bundle { return Bundle(for: type(of: self)) }
	
	func testFileAccess() {
		guard let fileURL = bundle.url(forResource: "example", withExtension: "json") else {
			return
		}
		
		let expectation = self.expectation(description: "File accessed")
		
		let accessDeferred = FileAccessStage.start(fileURL: fileURL, forgiving: false) * GCDService.utility
		
		let bookmarkDeferred = accessDeferred.flatMap{ useResult -> Deferred<FileBookmarkingStage.Result> in
			let (fileURL, _, stopAccessing) = try useResult()
			return (
				FileBookmarkingStage.fileURL(fileURL: fileURL) * GCDService.background
			).withCleanUp(stopAccessing!.taskExecuting())
		}
		
		(bookmarkDeferred + GCDService.mainQueue).perform { useResult in
			do {
				let result = try useResult()
				XCTAssertEqual(result.fileURL, fileURL)
				XCTAssert(result.bookmarkData.count > 0)
				XCTAssertEqual(result.wasStale, false)
				
				expectation.fulfill()
			}
			catch {
				XCTFail("Error \(error)")
			}
		}
		
		waitForExpectations(timeout: 3, handler: nil)
	}
}

