//
//	HTTPRequestStage.swift
//	Grain
//
//	Created by Patrick Smith on 17/03/2016.
//	Copyright © 2016 Burnt Caramel. All rights reserved.
//

import XCTest
@testable import Grain


enum HTTPRequestStage : StageProtocol {
	typealias Result = (response: HTTPURLResponse, body: Data?)
	
	case get(url: URL)
	case post(url: URL, body: Data)
	
	case success(Result)
	
	func next() -> Deferred<HTTPRequestStage> {
		return Deferred.future{ resolve in
			switch self {
			case let .get(url):
				let session = URLSession.shared
				let task = session.dataTask(with: url, completionHandler: { data, response, error in
					if let error = error {
						resolve{ throw error }
					}
					else {
						resolve{ .success((response: response as! HTTPURLResponse, body: data)) }
					}
				}) 
				task.resume()
			case let .post(url, body):
				let session = URLSession.shared
				let request = NSMutableURLRequest(url: url)
				request.httpBody = body
				let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
					if let error = error {
						resolve { throw error }
					}
					else {
						resolve { .success((response: response as! HTTPURLResponse, body: data)) }
					}
				}) 
				task.resume()
			case .success:
				completedStage(self)
			}
		}
	}
	
	var result: Result? {
		guard case let .success(result) = self else { return nil }
		return result
	}
}

enum FileUploadStage : StageProtocol {
	typealias Result = AnyObject?
	
	case openFile(fileStage: FileUnserializeStage, destinationURL: URL)
	case uploadRequest(request: HTTPRequestStage)
	case parseUploadResponse(data: Data?)
	case success(Result)
	
	enum Error : Error {
		case uploadFailed(statusCode: Int, body: Data?)
		case uploadResponseParsing(body: Data?)
	}
	
	func next() -> Deferred<FileUploadStage> {
		switch self {
		case let .openFile(stage, destinationURL):
			return stage.compose(
				next: {
					.openFile(fileStage: $0, destinationURL: destinationURL)
				},
				result: { result in
					Deferred{ .uploadRequest(
						request: .post(
							url: destinationURL,
							body: try JSONSerialization.data(withJSONObject: [ "number": result.number ], options: [])
						)
					) }
				}
			)
		case let .uploadRequest(stage):
			return stage.compose(
				transformNext: {
					.uploadRequest(request: $0)
				},
				transformResult: { result in
					let (response, body) = result
					switch response.statusCode {
					case 200:
						return .parseUploadResponse(data: body)
					default:
						throw Error.uploadFailed(statusCode: response.statusCode, body: body)
					}
				}
			)
		case let .parseUploadResponse(data):
			return Deferred{
				.success(
					try data.map{ try JSONSerialization.jsonObject(with: $0, options: []) }
				)
			}
		case .success:
			completedStage(self)
		}
	}
	
	var result: Result? {
		guard case let .success(result) = self else { return nil }
		return result
	}
}
