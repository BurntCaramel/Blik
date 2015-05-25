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
	case AlasOnlyApple
	case TheHeartOfUserInterfaces
	case TheDailyExpectation
	
	var title: String {
		switch self {
		case .AlasOnlyApple:
			return "Alas, Only Apple"
		case .TheHeartOfUserInterfaces:
			return "The Heart of User Interfaces"
		case .TheDailyExpectation:
			return "The Daily Expectation"
			
		}
	}
	
	var URL: NSURL {
		switch self {
		case .AlasOnlyApple:
			return NSURL(string: "https://medium.com/@concreteniche/alas-only-apple-20e0bc8b1c8f")!
		case .TheHeartOfUserInterfaces:
			return NSURL(string: "https://medium.com/@concreteniche/the-heart-of-user-interfaces-78d9411e0af5")!
		case .TheDailyExpectation:
			return NSURL(string: "https://medium.com/@concreteniche/the-daily-expectation-bcf7107c0875")!
			
		}
	}
	
	static var chosenLinks: [Link] {
		return [
			.AlasOnlyApple,
			.TheHeartOfUserInterfaces,
			.TheDailyExpectation
		]
	}
}

extension Link: UIChoiceRepresentative {
	typealias UniqueIdentifier = NSURL
	var uniqueIdentifier: UniqueIdentifier {
		return URL
	}
}


class CreatorThoughtsAssistant: NSObject {
	let menu: NSMenu
	private let menuAssistant: MenuAssistant<Link>
	
	init(menu: NSMenu) {
		self.menu = menu
		menuAssistant = MenuAssistant<Link>(menu: menu)
		
		super.init()
		
		menuAssistant.customization.actionAndTarget = { [weak self] link in
			return (action: "openLink:", target: self)
		}
		
		menuAssistant.menuItemRepresentatives = Link.chosenLinks.map { $0 }
		menuAssistant.update()
	}
	
	@IBAction func openLink(menuItem: NSMenuItem) {
		if let link = menuAssistant.itemRepresentativeForMenuItem(menuItem) {
			NSWorkspace.sharedWorkspace().openURL(link.URL)
		}
	}
}
