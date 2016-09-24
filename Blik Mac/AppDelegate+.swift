//
//  AppDelegate+.swift
//  Blik
//
//  Created by Patrick Smith on 28/06/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


var global_symlinkCreator: SymlinkCreator?


extension AppDelegate {
	var hidesMainWindowWhenInactive: Bool {
		let settings = GLAApplicationSettingsManager.shared()
		return settings!.hidesMainWindowWhenInactive
	}
	
	@IBAction func toggleHideMainWindowWhenInactive(_ sender: AnyObject?) {
		let settings = GLAApplicationSettingsManager.shared()
		settings?.toggleHidesMainWindowWhenInactive(sender)
	}
	
	@IBAction func createSymlinks(_ sender: AnyObject?) {
		SymlinkCreator.chooseFolderAndCreateSymlinks { symlinkCreator in
			symlinkCreator.createLinks()
			global_symlinkCreator = symlinkCreator
		}
	}
}


/*enum MainWindowVisibilityWhenInactiveChoice: Bool {
	case Shows = true
	case Hides = false
}*/
