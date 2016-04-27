//
//  FileFilterFields.swift
//  Blik
//
//  Created by Patrick Smith on 25/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntCocoaUI


enum FileFilterField {
	case kind(FileFilterKind)
	
	// Folder
	case hasFileNamed(String?)
	case notWithin(String?)
	
	case tagged(FileTag?)
	
	case sortedBy(FileSort)
	case upTo(FileQueryUpTo)
	//case openWith(NSURL)
	case highlight(Bool)
	
	enum Kind {
		case kind
		
		// Folder
		case hasFileNamed
		case notWithin
		
		case tagged
		
		case sortedBy
		case upTo
		//case openWith(NSURL)
		case highlight
	}
}

extension FileFilterField.Kind {
	var fieldKind: FieldKind {
		switch self {
		case .kind, .tagged, .sortedBy, .upTo: return .popUp
		case .hasFileNamed, .notWithin: return .text
		case .highlight: return .checkbox
		}
	}
	
	var label: String? {
		switch self {
		case .kind: return nil
			
		case .hasFileNamed: return NSLocalizedString("Has file named", comment: "Label for .hasFileNamed")
		case .notWithin: return NSLocalizedString("Not within", comment: "Label for .notWithin")
			
		case .tagged: return NSLocalizedString("Tagged", comment: "Label for .tagged")
			
		case .sortedBy: return NSLocalizedString("Sorted by", comment: "Label for .sortedBy")
		case .upTo: return NSLocalizedString("Up to", comment: "Label for .upTo")
		//case .openWith: return NSLocalizedString("Open with", comment: "Label for .openWith")
		case .highlight: return NSLocalizedString("Highlight", comment: "Label for .highlight")
		}
	}
}

extension FileFilterField : FieldProtocol {
	var kind: FileFilterField.Kind {
		switch self {
		case .kind: return .kind
		case .hasFileNamed: return .hasFileNamed
		case .notWithin: return .notWithin
		case .tagged: return .tagged
		case .sortedBy: return .sortedBy
		case .upTo: return .upTo
		case .highlight: return .highlight
		}
	}
	
	var fieldKind: FieldKind {
		return self.kind.fieldKind
	}
	
	var label: String? {
		return self.kind.label
	}
}


enum FileFilterKind : String, UIChoiceRepresentative, UIChoiceEnumerable {
	case folders = "folders"
	case images = "images"
	
	var title: String {
		switch self {
		case .folders: return NSLocalizedString("Folders", comment: "Title for .folders")
		case .images: return NSLocalizedString("Images", comment: "Title for .images")
		}
	}
	
	typealias UniqueIdentifier = FileFilterKind
	var uniqueIdentifier: UniqueIdentifier { return self }
	
	static var allChoices: [FileFilterKind] {
		return [
			.folders,
			.images
		]
	}
}

struct FileTag : UIChoiceRepresentative, UIChoiceEnumerable {
	var value: String
	
	var title: String { return value }
	var uniqueIdentifier: String { return value }
	
	// FIXME: what if file labels change?
	static var allChoices: [FileTag] = NSWorkspace.sharedWorkspace().fileLabels.map{ FileTag(value: $0) }
}

extension FileSort : UIChoiceRepresentative, UIChoiceEnumerable {
	var title: String {
		switch self {
		case .name:
			return NSLocalizedString("Name", comment: "Title for name file sorting")
		case .dateModified:
			return NSLocalizedString("Date modified", comment: "Title for date modified file sorting")
		case .dateOpened:
			return NSLocalizedString("Date opened", comment: "Title for date opened file sorting")
		}
	}
	var uniqueIdentifier: FileSort { return self }
	
	static var allChoices: [FileSort] = [
		.name,
		.dateModified,
		.dateOpened
	]
}

enum FileQueryUpTo : Int {
	case three = 3
	case five = 5
	case twelve = 12
}

extension FileQueryUpTo : UIChoiceRepresentative, UIChoiceEnumerable {
	var title: String {
		return String(rawValue)
	}
	
	var uniqueIdentifier: Int { return rawValue }
	
	static var allChoices: [FileQueryUpTo] = [
		.three,
		.five,
		.twelve
	]
}



class FileQueryFieldsProducer {
	var onFieldChange: (Field) -> ()
	
	init(onFieldChange: (Field) -> ()) {
		self.onFieldChange = onFieldChange
	}
	
	private func valueChanged<Value>(fieldCreator: (Value) -> Field) -> (Value) -> () {
		let onFieldChange = self.onFieldChange
		return { value in
			onFieldChange(fieldCreator(value))
		}
	}
	
	private func optionalValueChanged<Value>(fieldCreator: (Value) -> Field) -> (Value?) -> () {
		let onFieldChange = self.onFieldChange
		return { value in
			if let value = value {
				onFieldChange(fieldCreator(value))
			}
		}
	}
	
	private func buttonStateChanged(fieldCreator: (Bool) -> Field) -> (NSCellStateValue) -> () {
		let onFieldChange = self.onFieldChange
		return { state in
			onFieldChange(fieldCreator(state == NSOnState))
		}
	}
	
	lazy var kindRenderer: FileFilterKind -> NSPopUpButton = popUpButtonRenderer(onChange: self.optionalValueChanged(Field.kind))
	
	lazy var hasFileNamedRenderer: String? -> NSTextField = textFieldRenderer(onChange: self.valueChanged(Field.hasFileNamed))
	lazy var notWithinRenderer: String? -> NSTextField = textFieldRenderer(onChange: self.valueChanged(Field.notWithin))
	
	lazy var taggedRenderer: FileTag? -> NSPopUpButton = popUpButtonRenderer(onChange: self.optionalValueChanged(Field.tagged))
	
	lazy var sortedByRenderer: FileSort -> NSPopUpButton = popUpButtonRenderer(onChange: self.optionalValueChanged(Field.sortedBy))
	lazy var upToRenderer: FileQueryUpTo -> NSPopUpButton = popUpButtonRenderer(onChange: self.optionalValueChanged(Field.upTo))
	//lazy var openWithRenderer: NSURL -> NSPopUpButton = popUpButtonRenderer(onChange: self.optionalValueChanged(Field.openWith))
	lazy var highlightRenderer: NSCellStateValue -> NSButton = checkboxRenderer(onChange: self.buttonStateChanged(Field.highlight), title: FileFilterField.Kind.highlight.label!)
}

extension FileQueryFieldsProducer : FieldsProducer {
	typealias Field = FileFilterField
	
	func control(forField field: Field) -> NSView {
		switch field {
		case let .kind(kind): return kindRenderer(kind)
		case let .hasFileNamed(fileName): return hasFileNamedRenderer(fileName)
		case let .notWithin(directoryName): return notWithinRenderer(directoryName)
		case let .tagged(tag): return taggedRenderer(tag)
		case let .sortedBy(sortBy): return sortedByRenderer(sortBy)
		case let .upTo(upTo): return upToRenderer(upTo)
		//case .openWith: return NSView()
		case let .highlight(highlighted): return highlightRenderer(highlighted ? NSOnState : NSOffState)
		}
	}
}

struct FileQueryFieldsState {
	var kind: FileFilterKind = .folders
	
	var hasFileNamed: String? = nil
	var notWithin: String? = nil
	
	var tagged: FileTag? = nil
	
	var sortedBy: FileSort = .name
	var upTo: FileQueryUpTo = .three
	//var openWith: NSURL
	var highlight: Bool = false
	
	var fields: [FileFilterField?] {
		let unflattened: [[FileFilterField?]] = [
			[
				FileFilterField.kind(kind),
				nil
			],
			{
				switch kind {
				case .folders:
					return [
						FileFilterField.hasFileNamed(hasFileNamed),
						FileFilterField.notWithin(notWithin),
						nil
					]
				case .images:
					return []
				}
			}(),
			[
				FileFilterField.tagged(tagged),
				nil,
				FileFilterField.sortedBy(sortedBy),
				FileFilterField.upTo(upTo),
				//FileFilterField.openWith(openWith),
				FileFilterField.highlight(highlight)
			]
		]

		return Array(unflattened.flatten())
	}
	
	mutating func mergeField(field: FileFilterField) {
		switch field {
		case let .kind(kind): self.kind = kind
		case let .hasFileNamed(hasFileNamed): self.hasFileNamed = hasFileNamed
		case let .notWithin(notWithin): self.notWithin = notWithin
		case let .tagged(tagged): self.tagged = tagged
		case let .sortedBy(sortedBy): self.sortedBy = sortedBy
		case let .upTo(upTo): self.upTo = upTo
		case let .highlight(highlight): self.highlight = highlight
		}
	}
}

extension FileQueryFieldsState {
	var queryKind: FileFilterQuery.Kind {
		switch kind {
		case .folders:
			return .folders(
				containingFileNamed: hasFileNamed,
				pathNotContaining: notWithin
			)
		case .images:
			return .images()
		}
	}
	
	var query: FileFilterQuery {
		return FileFilterQuery(
			kind: queryKind,
			tagNames: tagged.map{ [$0.value] } ?? []
		)
	}
	
	func toRequest(sourceFolderURLs sourceFolderURLs: [NSURL]) -> FileFilterRequest {
		return FileFilterRequest(sourceFolderURLs: sourceFolderURLs, query: query, maxCount: upTo.rawValue, attributes: FileFilterRequest.defaultAttributes, sortingAttributes: FileFilterRequest.defaultSortingAttributes)
	}
}
