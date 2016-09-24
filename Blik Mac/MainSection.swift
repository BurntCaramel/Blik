//
//  MainSection.swift
//  Blik
//
//  Created by Patrick Smith on 28/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


protocol SectionProtocol {
	var previousSection: Self { get }
}


indirect enum MainSection {
	case allProjects
	case addNewProject(previousSection: MainSection?)
	
	case project(projectUUID: UUID, isNow: Bool?)
	case projectMasterFolders(projectUUID: UUID)
	
	case collection(collectionUUID: UUID, projectUUID: UUID)
	//case handpickedFilesCollection(collectionUUID: NSUUID, projectUUID: NSUUID)
	//case filteredFilesCollection(collectionUUID: NSUUID, projectUUID: NSUUID)
	
	case addNewCollection(subsection: AddNewCollectionSubsection, projectUUID: UUID, indexInList: Int?)
	
	indirect enum AddNewCollectionSubsection {
		case chooseType
		case handpickedFiles(fileURLsToAdd: [URL])
		case filteredFiles(filterKind: FileFilterKind)
		case nameAndColor(previousSubsection: AddNewCollectionSubsection?)
	}
}

extension MainSection : SectionProtocol {
	var previousSection: MainSection {
		switch self {
		case let .addNewProject(previousSection):
			return previousSection ?? .allProjects
		case let .projectMasterFolders(projectUUID):
			return .project(projectUUID: projectUUID, isNow: nil)
		case let .collection(_, projectUUID):
			return .project(projectUUID: projectUUID, isNow: nil)
		case let .addNewCollection(subsection, projectUUID, indexInList):
			switch subsection {
			case .chooseType:
				return .project(projectUUID: projectUUID, isNow: nil)
			case .handpickedFiles, .filteredFiles:
				return .addNewCollection(subsection: .chooseType, projectUUID: projectUUID, indexInList: indexInList)
			case let .nameAndColor(previousSubsection):
				if let previousSubsection = previousSubsection {
					return .addNewCollection(subsection: previousSubsection, projectUUID: projectUUID, indexInList: indexInList)
				}
				else {
					return .project(projectUUID: projectUUID, isNow: nil)
				}
			}
		default:
			return .allProjects
		}
	}
}
