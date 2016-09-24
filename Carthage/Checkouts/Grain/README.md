# Grain

Grain makes data flow easier, using an enum with explicit cases
for each stage in the data flow.
Associated values are used to keep state for each stage.

## Installation

### Carthage

```
github "BurntCaramel/Grain"
```

## Usage

```swift
enum FileOpenStage : StageProtocol {
  typealias Result = (text: String, number: Double, arrayOfText: [String])

  /// Initial stages
  case read(fileURL: NSURL)
  /// Intermediate stages
  case unserializeJSON(data: NSData)
  case parseJSON(object: AnyObject)
  /// Completed stages
  case success(Result)

  // Any errors thrown by the stages
  enum Error: ErrorType {
    case invalidJSON
    case missingData
  }
}
```

Each stage creates a task, which resolves to the next stage.
Deferreds can be synchronous subroutines (`Deferred()`) or asynchronous futures (`Deferred.future()`).

Grain by default runs tasks on a background queue, even synchronous ones.

```swift
extension FileOpenStage {
	/// The task for each stage
	func next() -> Deferred<FileOpenStage> {
		return Deferred{
			switch self {
			case let .read(fileURL):
				return .unserializeJSON(
					data: try NSData(contentsOfURL: fileURL, options: .DataReadingMappedIfSafe)
				)
			case let .unserializeJSON(data):
				return .parseJSON(
					object: try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
				)
			case let .parseJSON(object):
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
			case .success:
				completedStage(self)
			}
		}
	}
}
```

To run, create an initial stage and call `.execute()`, which uses
Grand Central Dispatch to asychronously dispatch each stage, by default
with a **utility** quality of service.

Your callback is passed `useResult`, which you call to either
return the result or throw an error.
Errors thrown in any of the stages will bubble up, so use Swift error
handling to catch them here in the one place. 

```swift
FileOpenStage.read(fileURL: fileURL).execute { useResult in
	do {
		let (text, number, arrayOfText) = try useResult()
		// Do something with result
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
enum HTTPRequestStage : StageProtocol {
	typealias Result = (response: NSHTTPURLResponse, body: NSData?)
	
	case get(url: NSURL)
	case post(url: NSURL, body: NSData)
	
	case success(Result)
	
	func next() -> Deferred<HTTPRequestStage> {
		return Deferred.future{ resolve in
			switch self {
			case let .get(url):
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
			case let .post(url, body):
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
```

## Motivations

Breaking a data flow into a more declarative form makes it easier to understand.

Associated values capture the entire state at a particular stage in the flow.
There’s no external state or side effects, just what’s in each case.

Each stage is distinct, produces its next stage in a sychronous or
asychronous manner.

Stages are able to be stored and restored at will as they are just enums. 
This allows easier testing, since you can resume at any stage, not just initial ones.

Swift’s native error handling is used. 

## Multiple inputs or outputs

Stages can have multiple choices of initial stages: just add multiple cases!

For multiple choice of output, use a `enum` for the `Completion` associated type.

## Composing stages

`StageProtocol` includes `.map` and `.flatMap` methods, allowing stages to be composed
inside other stages. A series of stages can become a single stage in a different
enum, and so on.

For example, combining the previous two stage types:

```swift
enum FileUploadStage : StageProtocol {
	typealias Result = AnyObject?
	
	case openFile(fileStage: FileUnserializeStage, destinationURL: NSURL)
	case uploadRequest(request: HTTPRequestStage)
	case parseUploadResponse(data: NSData?)
	case success(Result)
	
	enum Error : ErrorType {
		case uploadFailed(statusCode: Int, body: NSData?)
		case uploadResponseParsing(body: NSData?)
	}
	
	func next() -> Deferred<FileUploadStage> {
		switch self {
		case let .openFile(stage, destinationURL):
			return stage.compose(
				transformNext: {
					.openFile(fileStage: $0, destinationURL: destinationURL)
				},
				transformResult: { result in
					.uploadRequest(
						request: .post(
							url: destinationURL,
							body: try NSJSONSerialization.dataWithJSONObject([ "number": result.number ], options: [])
						)
					)
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
					try data.map{ try NSJSONSerialization.JSONObjectWithData($0, options: []) }
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
```
