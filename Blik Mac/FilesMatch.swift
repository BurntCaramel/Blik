//
//  FolderFilter.swift
//  Blik
//
//  Created by Patrick Smith on 28/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


let fm = NSFileManager()


func folderMatches(folderURL: NSURL, containingFileNamed: String? = nil) throws -> Bool {
	if let
		containingFileNamed = containingFileNamed
		where containingFileNamed != ""
	{
		let urls = try fm.contentsOfDirectoryAtURL(folderURL, includingPropertiesForKeys: [NSURLNameKey], options: [])
		let names = try urls.map{ try $0.resourceValuesForKeys([NSURLNameKey])[NSURLNameKey]! as! String }
		if !names.contains(containingFileNamed) {
			return false
		}
	}
	
	return true
}


enum FilesMatchStage : StageProtocol {
	typealias Completion = [NSURL]
	
	case folders(
		folderURLs: [NSURL],
		containingFileNamed: String?
	)
	case completed(Completion)
	
	var nextTask: Task<FilesMatchStage>? {
		switch self {
		case let .folders(folderURLs, containingFileNamed):
			return Task{
				try .completed(folderURLs.filter{
					try folderMatches($0, containingFileNamed: containingFileNamed)
				})
			}
		case .completed: return nil
		}
	}
	
	var completion: Completion? {
		guard case let .completed(completion) = self else { return nil }
		return completion
	}
}
