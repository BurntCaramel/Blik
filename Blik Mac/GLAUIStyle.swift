//
//  GLAUIStyle.swift
//  Blik
//
//  Created by Patrick Smith on 20/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


extension GLAUIStyle {
	@objc var launcherMenuFont: NSFont? {
		if #available(OSX 10.11, *) {
			return nil
		}
		else {
			return menuFont
		}
	}
}