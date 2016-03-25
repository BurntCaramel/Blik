# Grain

Grain makes data flow easier, using an enum to create discrete stages.
Associated values are used to keep state for each stage.

## Usage

```swift
// Create an enum conforming to `StageProtocol` 
enum FileOpenStage: StageProtocol {
	/// Initial stages
	case read(fileURL: NSURL)
	/// Intermediate stages
	case unserializeJSON(data: NSData)
	case parseJSON(object: AnyObject)
	/// Completed stages
	case success(text: String, number: Double, arrayOfText: [String])

	// Any errors thrown by the stages
	enum Error: ErrorType {
		case invalidJSON
		case missingData
	}
}
```

Each stage creates a task, which resolves to the next stage.
Tasks can be synchronous subroutines (.unit) or asynchronous futures (.future).

```swift
extension FileOpenStage {
	/// The task for each stage
	var nextTask: Task<FileOpenStage>? {
		switch self {
		case let .read(fileURL):
			return .unit({
				.unserializeJSON(
					data: try NSData(contentsOfURL: fileURL, options: .DataReadingMappedIfSafe)
				)
			})
		case let .unserializeJSON(data):
			return .unit({
				.parseJSON(
					object: try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
				)
			})
		case let .parseJSON(object):
			return .unit({
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
			})
		case .success:
			return nil
		}
	}
}
```

To execute, create an initial stage and call `.execute()`, which uses
Grand Central Dispatch to asychronously dispatch each stage, by default
with a **user initiated** QOS.

Your callback is passed `useResult`, which you call to return the result.
Any errors thrown in the stages will bubble up, so use Swift error
handling to catch these here in the one place. 

```swift
FileOpenStage.read(fileURL: fileURL).execute { useResult in
	do {
		let result = try useResult()
		if case let .success(text, number, arrayOfText) = result {
			// Do something with result
		}
		else {
			// Invalid stage to complete at
			fatalError("Invalid success stage \(result)")
		}
	}
	catch {
		// Handle `error` here
	}
	
	expectation.fulfill()
}
```

## Using existing asynchronous libraries

Grain can create tasks for existing asychronous libraries, such as NSURLSession.
Use the `.future` task, and resolve the value, or resolve throwing an error.

```swift
enum HTTPRequestStage: StageProtocol {
	case get(url: NSURL)
	case post(url: NSURL, body: NSData)
	case success(response: NSHTTPURLResponse, body: NSData?)
	
	var nextTask: Task<HTTPRequestStage>? {
		switch self {
		case let .get(url):
			return .future({ resolve in
				let session = NSURLSession.sharedSession()
				let task = session.dataTaskWithURL(url) { (data, response, error) in
					if let error = error {
						resolve { throw error }
					}
					else {
						resolve { .success(response: response as! NSHTTPURLResponse, body: data) }
					}
				}
				task.resume()
			})
		case let .post(url, body):
			return .future({ resolve in
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
			})
		case .success:
			return nil
		}
	}
}
```

## Customizing GCD

```swift
var customizer = GCDExecutionCustomizer<FileOpenStage>()

// Change QOS for particular stages
customizer.serviceForStage = { stage in
	switch stage {
	case .read: return .utility
	default: return .userInitiated
	}
}

// Dispatch on a custom serial queue
let resultQueue = dispatch_queue_create("com.example.results", DISPATCH_QUEUE_SERIAL)
customizer.completionService = .customQueue(resultQueue)

customizer.beforeStage = { print("About to perform stage \($0)") }

// Execute using customizer
FileOpenStage.read(fileURL: fileURL).execute(customizer: customizer) { useResult in
	...
}
```

## Multiple inputs or outputs

Stages can have multiple choices of initial stages or success stages.
Just add multiple cases!

## Motivations

Breaking a data flow into a more declarative form makes it easier to understand.

Each stage is distinct, and can contain code that is sychronous or asychronous.

It allows easier testing, as stages are able to be stored and resumed at will.
Associated values capture the entire state of a stage, making storing easy.
And any stage can be executed, not just initial ones.

Data flows in a flattened heirarchy, with native support for Swift’s
error system.

## Composing stages

`StageProtocol` includes `.map` and `.flatMap` methods, allowing stages to be composed
inside other stages. A series of stages can become a single stage in a different
enum, and so on.

```swift
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
				return .unit({
					.uploadRequest(.post(
						url: destinationURL,
						body: try NSJSONSerialization.dataWithJSONObject([ "number": number ], options: [])
					))
				})
			}
			else {
				return stage.mapNext{ .openFile(fileOpenStage: $0, destinationURL: destinationURL) }
			}
		case let .uploadRequest(stage):
			if case let .success(response, body) = stage {
				if response.statusCode == 200 {
					return .unit({ .success })
				}
				else {
					return .unit({ throw Error.uploadFailed(statusCode: response.statusCode, body: body) })
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
```

(More to come.)
