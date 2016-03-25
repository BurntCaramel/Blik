//
//  HTTPRequestStage.swift
//  Grain
//
//  Created by Patrick Smith on 17/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import XCTest
@testable import Grain


enum HTTPRequestStage: StageProtocol {
	case get(url: NSURL)
	case post(url: NSURL, body: NSData)
	case success(response: NSHTTPURLResponse, body: NSData?)
	
	var nextTask: Task<HTTPRequestStage>? {
		switch self {
		case let .get(url):
			return Task.future{ resolve in
				let session = NSURLSession.sharedSession()
				let task = session.dataTaskWithURL(url) { data, response, error in
					if let error = error {
						resolve{ throw error }
					}
					else {
						resolve{ .success(response: response as! NSHTTPURLResponse, body: data) }
					}
				}
				task.resume()
			}
		case let .post(url, body):
			return Task.future{ resolve in
				let session = NSURLSession.sharedSession()
				let request = NSMutableURLRequest(URL: url)
				request.HTTPBody = body
				let task = session.dataTaskWithRequest(request) { (data, response, error) in
					if let error = error {
						resolve { throw error }
					}
					else {
						resolve { .success(response: response as! NSHTTPURLResponse, body: data) }
					}
				}
				task.resume()
			}
		case .success:
			return nil
		}
	}
}

enum FileUploadStage: StageProtocol {
	case openFile(fileOpenStage: FileOpenStage, destinationURL: NSURL)
	case uploadRequest(HTTPRequestStage)
	case success
	
	enum Error: ErrorType {
		case uploadFailed(statusCode: Int, body: NSData?)
	}
	
	var nextTask: Task<FileUploadStage>? {
		switch self {
		case let .openFile(stage, destinationURL):
			if case let .success(_, number, _) = stage {
				return Task{
					.uploadRequest(.post(
						url: destinationURL,
						body: try NSJSONSerialization.dataWithJSONObject([ "number": number ], options: [])
					))
				}
			}
			else {
				return stage.mapNext{ .openFile(fileOpenStage: $0, destinationURL: destinationURL) }
			}
		case let .uploadRequest(stage):
			if case let .success(response, body) = stage {
				let statusCode = response.statusCode
				if statusCode == 200 {
					return Task{ .success }
				}
				else {
					return Task{ throw Error.uploadFailed(statusCode: statusCode, body: body) }
				}
			}
			else {
				return stage.mapNext{ .uploadRequest($0) }
			}
		case .success:
			return nil
		}
	}
}
