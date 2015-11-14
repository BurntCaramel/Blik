//
//  GLAProjectManager+OpeningFiles.swift
//  Blik
//
//  Created by Patrick Smith on 5/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum OpeningBehaviour: Int {
	case Default = 0
	case ShowInFinder = 1
	case Edit = 2
}

extension OpeningBehaviour {
	init(modifierFlags: NSEventModifierFlags) {
		if modifierFlags.contains(.CommandKeyMask) {
			self = .ShowInFinder
		}
		else if modifierFlags.contains(.AlternateKeyMask) {
			self = .Edit;
		}
		else {
			self = .Default
		}
	}
}


extension GLAProjectManager {
	func openCollectedFile(collectedFile: GLACollectedFile, behaviour: OpeningBehaviour, withApplication applicationURL: NSURL? = nil) {
		let accessedFileInfo = collectedFile.accessFile()
		
		withExtendedLifetime(accessedFileInfo) {
			let fileURL = accessedFileInfo.filePathURL
			
			switch behaviour {
			case .ShowInFinder:
				NSWorkspace.sharedWorkspace().activateFileViewerSelectingURLs([fileURL])
			case .Default:
				if let bundleInfo = NSBundle(URL: fileURL)?.infoDictionary {
					let isApplication = "APPL" == bundleInfo["CFBundlePackageType"] as? String
					if isApplication {
						NSWorkspace.sharedWorkspace().openURL(fileURL)
						return
					}
				}
				fallthrough
			case .Edit:
				GLAFileOpenerApplicationFinder.openFileURLs([fileURL], withApplicationURL: applicationURL, useSecurityScope: true)
			}
		}
	}

	func openHighlightedCollectedFile(highlightedCollectedFile: GLAHighlightedCollectedFile, behaviour: OpeningBehaviour) -> Bool {
		guard let collectedFile = collectedFileForHighlightedCollectedFile(highlightedCollectedFile, loadIfNeeded: false) else { return false }
		if collectedFile.empty { return false }
		
		let applicationToOpenFileAccess = highlightedCollectedFile.applicationToOpenFile?.accessFile()
		withExtendedLifetime(applicationToOpenFileAccess) {
			let applicationURL = applicationToOpenFileAccess?.filePathURL
			openCollectedFile(collectedFile, behaviour: behaviour, withApplication: applicationURL)
		}
		
		return true
	}
}
