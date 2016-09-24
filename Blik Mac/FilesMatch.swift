//
//  FolderFilter.swift
//  Blik
//
//  Created by Patrick Smith on 28/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


let fm = FileManager()


func folderMatches(_ folderURL: URL, containingFileNamed: String? = nil) throws -> Bool {
	if let
		containingFileNamed = containingFileNamed
		, containingFileNamed != ""
	{
		let urls = try fm.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [URLResourceKey.nameKey], options: [])
		let names = try urls.map{ try ($0 as NSURL).resourceValues(forKeys: [URLResourceKey.nameKey])[URLResourceKey.nameKey]! as! String }
		if !names.contains(containingFileNamed) {
			return false
		}
	}
	
	return true
}


enum FilesMatchStage : StageProtocol {
	typealias Result = [URL]
	
	case folders(
		folderURLs: [URL],
		containingFileNamed: String?
	)
	case completed(Result)
	
	func next() -> Deferred<FilesMatchStage> {
		switch self {
		case let .folders(folderURLs, containingFileNamed):
			return Deferred{
				try .completed(folderURLs.filter{
					try folderMatches($0, containingFileNamed: containingFileNamed)
				})
			}
		case .completed: completedStage(self)
		}
	}
	
	var result: Result? {
		guard case let .completed(result) = self else { return nil }
		return result
	}
}
