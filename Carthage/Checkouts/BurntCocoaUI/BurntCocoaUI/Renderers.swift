//
//  Renderers.swift
//  BurntCocoaUI
//
//  Created by Patrick Smith on 27/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa


public func textFieldRenderer
	<TextField : NSTextField>
	(onChange onChange: (String) -> ())
	-> (String?) -> TextField
{
	let textField = TextField()
	textField.cell?.sendsActionOnEndEditing = true
	
	let target = textField.setActionHandler { _ in
		onChange(textField.stringValue)
	}
	
	return { stringValue in
		withExtendedLifetime(target) {
			textField.stringValue = stringValue ?? ""
		}
		return textField
	}
}

public func checkboxRenderer
	<Button : NSButton>
	(onChange onChange: (NSCellStateValue) -> (), title: String)
	-> (NSCellStateValue) -> Button
{
	let button = Button()
	button.title = title
	button.setButtonType(.SwitchButton)
	
	let target = button.setActionHandler { _ in
		onChange(button.state)
	}
	
	return { state in
		withExtendedLifetime(target) {
			button.state = state
		}
		return button
	}
}

public func popUpButtonRenderer<
	PopUpButton : NSPopUpButton,
	Value : UIChoiceRepresentative
	where
	Value : UIChoiceEnumerable>
	(onChange onChange: (Value?) -> ())
	-> (Value?) -> PopUpButton
{
	let popUpButton = PopUpButton()
	let assistant = PopUpButtonAssistant<Value>(popUpButton: popUpButton)
	assistant.menuItemRepresentatives = Value.allChoices.map{ $0 }
	
	assistant.update()
	
	let target = assistant.popUpButton.setActionHandler { _ in
		onChange(assistant.selectedItemRepresentative)
	}
	
	return { value in
		withExtendedLifetime(target) {
			assistant.selectedUniqueIdentifier = value?.uniqueIdentifier
		}
		return popUpButton
	}
}