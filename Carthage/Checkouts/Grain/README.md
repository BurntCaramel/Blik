# Grain

Grain makes data flow easier, using an enum to create discrete stages.
Associated values are used to keep state for each stage.

## Usage

```swift
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
```

Each stage creates a task, which resolves to the next stage.
Tasks can be synchronous subroutines (`Task()`) or asynchronous futures (`Task.future()`).

Grain by default runs tasks on a background queue, even synchronous ones.

```swift
extension FileOpenStage {
	/// The task for each stage
	var nextTask: Task<FileOpenStage>? {
		switch self {
		// Currently at the .read stage:
		case let .read(fileURL):
			// A synchronous task to run the passed closure.
			// The task returns the next stage: .read -> .unserializeJSON
			return Task{
				return .unserializeJSON(
					data: try NSData(contentsOfURL: fileURL, options: .DataReadingMappedIfSafe)
				)
			}
		// Currently at the .unserializeJSON stage
		case let .unserializeJSON(data):
			return Task{
				return .parseJSON(
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
			// Completed: no next task
			return nil
		}
	}
	
	// Returns a value if this stage is completed 
	var completion: Completion? {
		guard case let .success(completion) = self else { return nil }
		return completion
	}
}
```

To execute, create an initial stage and call `.execute()`, which uses
Grand Central Dispatch to asychronously dispatch each stage, by default
with a **user initiated** quality of service.

Your callback is passed `useResult`, which you call to return the result.
Errors thrown in any of the stages will bubble up, so use Swift error
handling to catch them here in the one place. 

```swift
FileOpenStage.read(fileURL: fileURL).execute { useResult in
	do {
		let (text, number, arrayOfText) = try useResult()
		// Use result...
	}
	catch {
		// Handle `error` here
	}
}
```

## Using existing asynchronous libraries

Grain can create tasks for existing asychronous libraries, such as NSURLSession.
Use the `.future` task, and resolve the value, or resolve throwing an error.

```swift
enum HTTPRequestStage: StageProtocol {
	typealias Completion = (response: NSHTTPURLResponse, body: NSData?)
	
	case get(url: NSURL)
	case post(url: NSURL, body: NSData)
	
	case success(Completion)
	
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
						resolve{ .success((response: response as! NSHTTPURLResponse, body: data)) }
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
						resolve { .success((response: response as! NSHTTPURLResponse, body: data)) }
					}
				}
				task.resume()
			}
		case .success:
			return nil
		}
	}
	
	var completion: Completion? {
		guard case let .success(completion) = self else { return nil }
		return completion
	}
}
```

## Customizing GCD

```swift
var customizer = GCDExecutionCustomizer<FileOpenStage>()

let readQueue = dispatch_queue_create("com.example.fileReading", DISPATCH_QUEUE_SERIAL)

// Change queue for particular stages
customizer.serviceForStage = { stage in
	switch stage {
	case .read: return .customQueue(readQueue) // Custom dispatch queue
	default: return .utility // Utility QOS global queue
	}
}

// Complete with user interactive QOS
customizer.completionService = .userInteractive

customizer.beforeStage = { print("About to perform stage \($0)") }

// Execute using customizer
FileOpenStage.read(fileURL: fileURL).execute(customizer: customizer) { useResult in
	// ...
}
```

## Multiple inputs or outputs

Stages can have multiple choices of initial stages: just add multiple cases!

For multiple choice of output, use a `enum` for the `Completion` associated type.

## Motivations

Breaking a data flow into a more declarative form makes it easier to understand.

Each stage is distinct, and can be sychronous or asychronous.

Stages are able to be stored and restored at will, as associated values capture
the entire state of a stage.
This allows easier testing, as you can resume at any stage, not just initial ones.

Swift’s native error handling is used. 

## Composing stages

`StageProtocol` includes `.map` and `.flatMap` methods, allowing stages to be composed
inside other stages. A series of stages can become a single stage in a different
enum, and so on.

For example, combining the previous two stage types:

```swift
enum FileUploadStage: StageProtocol {
	typealias Completion = ()
	
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
	
	var completion: Completion? {
		// CRASHES: guard case let .success(completion) = self else { return nil }
		guard case .success = self else { return nil }
		return ()
	}
}
```

## Installation

### Carthage

```
github "BurntCaramel/Grain"
```
