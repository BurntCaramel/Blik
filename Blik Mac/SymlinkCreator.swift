//
//  SymlinkCreator.swift
//  Blik
//
//  Created by Patrick Smith on 11/06/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


class SymlinkCreator {
	var projectManager: GLAProjectManager {
		return GLAProjectManager.sharedProjectManager()
	}
	
	var allProjectsUser: GLALoadableArrayUsing?
	func useAllProjects() -> GLALoadableArrayUsing {
		if let allProjectsUser = (self.allProjectsUser) {
			return allProjectsUser
		}
		else {
			let pm = projectManager
			let allProjectsUser = pm.useAllProjects()
			
			allProjectsUser.changeCompletionBlock = { [weak self] inspectableArray in
				self?.projectsDidChange()
			}
			
			allProjectsUser.inspectLoadingIfNeeded()
			
			self.allProjectsUser = allProjectsUser
			
			return allProjectsUser
		}
	}
	
	func projectsDidChange() {
		
	}
	
	func URLsForCollectionWithUUID(collectionUUID: NSUUID, inProjectWithUUID projectUUID: NSUUID) {
		
	}
}