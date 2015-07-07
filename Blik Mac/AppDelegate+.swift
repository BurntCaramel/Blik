//
//  AppDelegate+.swift
//  Blik
//
//  Created by Patrick Smith on 28/06/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


var global_symlinkCreator: SymlinkCreator?


extension GLAAppDelegate {
	@IBAction func createSymlinks(sender: AnyObject?) {
		SymlinkCreator.chooseFolderAndCreateSymlinks { symlinkCreator in
			symlinkCreator.createLinks()
			global_symlinkCreator = symlinkCreator
		}
	}
}
