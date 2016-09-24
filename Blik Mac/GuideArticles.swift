//
//  GuideArticles.swift
//  Blik
//
//  Created by Patrick Smith on 26/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntCocoaUI


private enum Link: String {
	case OrganizingYourMacsFiles = "https://medium.com/burnt-caramel-apps/how-to-organize-your-mac-s-files-with-blik-4f3d28faa7cd"
	case WhatsNew = "https://medium.com/@concreteniche/what-s-new-in-blik-for-mac-5e210ea8b9e0"
	
	var title: String {
		switch self {
		case .OrganizingYourMacsFiles:
			return "A guide to organizing your Mac’s files with Blik"
		case .WhatsNew:
			return "What’s new in Blik?"
		}
	}
	
	var url: Foundation.URL {
		return Foundation.URL(string: rawValue)!
	}
	
	static var chosenLinks: [Link] {
		return [
			.WhatsNew,
			.OrganizingYourMacsFiles
		]
	}
}

extension Link: UIChoiceRepresentative {
	typealias UniqueIdentifier = Foundation.URL
	var uniqueIdentifier: UniqueIdentifier {
		return url
	}
}


class GuideArticlesAssistant: NSObject {
	fileprivate let menuItemAssistant: PlaceholderMenuItemAssistant<Link>
	
	init(placeholderMenuItem: NSMenuItem) {
		menuItemAssistant = PlaceholderMenuItemAssistant<Link>(placeholderMenuItem: placeholderMenuItem)
		
		super.init()
		
		menuItemAssistant.customization.actionAndTarget = { [weak self] link in
			return (action: #selector(GuideArticlesAssistant.openLink(_:)), target: self)
		}
		
		menuItemAssistant.menuItemRepresentatives = Link.chosenLinks.map { $0 }
		menuItemAssistant.update()
	}
	
	@IBAction func openLink(_ menuItem: NSMenuItem) {
    if let link = menuItemAssistant.itemRepresentative(for: menuItem) {
			NSWorkspace.shared().open(link.url)
		}
	}
}
