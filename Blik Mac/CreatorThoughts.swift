//
//  CreatorThoughts.swift
//  Blik
//
//  Created by Patrick Smith on 25/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntCocoaUI


private enum Link {
	case siriThePlatform
	case appleCaredAggressively
	case thingsSomeSteveJobsGuyOnceSaid
	case perfectionIsADirection
	case alasOnlyApple
	case theHeartOfUserInterfaces
	case theDailyExpectation
	
	var title: String {
		switch self {
		case .siriThePlatform:
			return "Siri, the Platform"
		case .appleCaredAggressively:
			return "Apple Cared Aggressively"
		case .thingsSomeSteveJobsGuyOnceSaid:
			return "Things Some Steve Jobs Guy Once Said"
		case .perfectionIsADirection:
			return "Perfection is a Direction, Not a Destination"
		case .alasOnlyApple:
			return "Alas, Only Apple"
		case .theHeartOfUserInterfaces:
			return "The Heart of User Interfaces"
		case .theDailyExpectation:
			return "The Daily Expectation"
			
		}
	}
	
	var url: Foundation.URL {
		switch self {
		case .siriThePlatform:
			return Foundation.URL(string: "https://medium.com/@concreteniche/siri-the-new-platform-deec9cc4d5db")!
		case .appleCaredAggressively:
			return Foundation.URL(string: "https://medium.com/@concreteniche/apple-cared-aggressively-65cec1c906e0")!
		case .thingsSomeSteveJobsGuyOnceSaid:
			return Foundation.URL(string: "https://medium.com/@concreteniche/things-some-steve-jobs-guy-once-said-a7ec8810047e")!
		case .perfectionIsADirection:
			return Foundation.URL(string: "https://medium.com/@concreteniche/perfection-is-a-direction-not-a-destination-9237caade2a5")!
		case .alasOnlyApple:
			return Foundation.URL(string: "https://medium.com/@concreteniche/alas-only-apple-20e0bc8b1c8f")!
		case .theHeartOfUserInterfaces:
			return Foundation.URL(string: "https://medium.com/@concreteniche/the-heart-of-user-interfaces-78d9411e0af5")!
		case .theDailyExpectation:
			return Foundation.URL(string: "https://medium.com/@concreteniche/the-daily-expectation-bcf7107c0875")!
			
		}
	}
	
	static var chosenLinks: [Link] {
		return [
			.siriThePlatform,
			.appleCaredAggressively,
			.thingsSomeSteveJobsGuyOnceSaid,
			.perfectionIsADirection,
			.alasOnlyApple,
			.theHeartOfUserInterfaces,
			.theDailyExpectation
		]
	}
}

extension Link: UIChoiceRepresentative {
	typealias UniqueIdentifier = Foundation.URL
	var uniqueIdentifier: UniqueIdentifier {
		return url
	}
}


class CreatorThoughtsAssistant : NSObject {
	fileprivate let menuAssistant: MenuAssistant<Link>
	
	init(menu: NSMenu) {
		menuAssistant = MenuAssistant<Link>(menu: menu)
		
		super.init()
		
		menuAssistant.customization.actionAndTarget = { [weak self] link in
			return (
				action: #selector(CreatorThoughtsAssistant.openLink(_:)),
				target: self
			)
		}
		
		menuAssistant.menuItemRepresentatives = Link.chosenLinks.map { $0 }
		menuAssistant.update()
	}
	
	@IBAction func openLink(_ menuItem: NSMenuItem) {
    if let link = menuAssistant.itemRepresentative(for: menuItem) {
			NSWorkspace.shared().open(link.url)
		}
	}
}
