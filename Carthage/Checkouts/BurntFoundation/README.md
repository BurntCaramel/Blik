# BurntFoundation
Pleasant Swift additions to Foundation

## Examples

### User Defaults

```swift
enum ExampleIntChoice: Int, UserDefaultsChoiceRepresentable {
	case One = 1
	case Two = 2
	case Three = 3
	
	// The key that will be used with NSUserDefaults
	static var identifier: String = "exampleInt"
	static var defaultValue = ExampleIntChoice.One
}
```

Setting:

```swift
// Before:
ud.setInteger(3, forKey: "exampleInt")

// After:
ud.setChoice(ExampleIntChoice.Three)
```

Getting:

```swift
// Before:
let intValue = ud.integerForKey("exampleInt")

// After:
let intChoice = ud.choice(ExampleIntChoice)

```

### Notifications

```swift
class Example {
	enum Notification: String {
		case DidUpdate = "NotificationTestsDidUpdateNotification"
	}
	
	func update() {
		// Do stuff...
		
		// Post the notification
		nc.postNotification(Example.Notification.DidUpdate, object: self)
	}
}

let example = Example()
let notificationObserver = NotificationObserver<Example.Notification>(object: example)
notificationObserver.observe(.DidUpdate) { notification in
	// Observe the notification
}
```

## Installation

To integrate BurntFoundation into your Xcode project using Carthage, specify it in your Cartfile:

```
github "BurntCaramel/BurntFoundation" >= 0.3
```
