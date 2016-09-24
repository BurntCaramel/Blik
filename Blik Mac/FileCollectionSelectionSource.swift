//
//  FileCollectionSelectionAssistant.swift
//  Blik
//
//  Created by Patrick Smith on 18/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


@objc public protocol FileSelectionSourcing {
	var selectedFileURLs: [URL] { get }
}

@objc public protocol CollectedFileSelectionSourcing: FileSelectionSourcing {
	var isReadyToHighlight: Bool { get }
	var selectedCollectedFiles: [GLACollectedFile] { get }
}


@objc public protocol FileCollectionSelectionSourcing: FileSelectionSourcing {
	var collectedFileSource: CollectedFileSelectionSourcing? { get }
}
