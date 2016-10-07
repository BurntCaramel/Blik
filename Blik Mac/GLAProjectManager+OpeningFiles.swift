//
//  GLAProjectManager+OpeningFiles.swift
//  Blik
//
//  Created by Patrick Smith on 5/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum OpeningBehaviour: Int {
	case `default` = 0
	case showInFinder = 1
	case edit = 2
}

extension OpeningBehaviour {
	init(modifierFlags: NSEventModifierFlags) {
		if modifierFlags.contains(.command) {
			self = .showInFinder
		}
		else if modifierFlags.contains(.option) {
			self = .edit;
		}
		else {
			self = .default
		}
	}
}


extension GLAProjectManager {
	func openCollectedFile(_ collectedFile: GLACollectedFile, behaviour: OpeningBehaviour, withApplication applicationURL: URL? = nil) {
		let accessedFileInfo = collectedFile.accessFile()
		
		withExtendedLifetime(accessedFileInfo) {
      guard let fileURL = accessedFileInfo?.filePathURL
        else { return }
			
			switch behaviour {
			case .showInFinder:
				NSWorkspace.shared().activateFileViewerSelecting([fileURL])
			case .default:
				if let bundleInfo = Bundle(url: fileURL)?.infoDictionary {
					let isApplication = "APPL" == bundleInfo["CFBundlePackageType"] as? String
					if isApplication {
						NSWorkspace.shared().open(fileURL)
						return
					}
				}
				fallthrough
			case .edit:
				GLAFileOpenerApplicationFinder.openFileURLs([fileURL], withApplicationURL: applicationURL, useSecurityScope: true)
			}
		}
	}

	func openHighlightedCollectedFile(_ highlightedCollectedFile: GLAHighlightedCollectedFile, behaviour: OpeningBehaviour) -> Bool {
		guard let collectedFile = collectedFile(for: highlightedCollectedFile, loadIfNeeded: false) else { return false }
		if collectedFile.empty { return false }
		
		let applicationToOpenFileAccess = highlightedCollectedFile.applicationToOpenFile?.accessFile()
		withExtendedLifetime(applicationToOpenFileAccess) {
			let applicationURL = applicationToOpenFileAccess?.filePathURL
			openCollectedFile(collectedFile, behaviour: behaviour, withApplication: applicationURL)
		}
		
		return true
	}
}
