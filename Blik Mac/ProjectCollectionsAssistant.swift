//
//  ProjectCollectionsAssistant.swift
//  Blik
//
//  Created by Patrick Smith on 28/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import BurntFoundation


public enum CollectionItemSource {
	case collection(collection: GLACollection)
	case masterFolders
	case filteredFiles(collection: GLACollection)
}
