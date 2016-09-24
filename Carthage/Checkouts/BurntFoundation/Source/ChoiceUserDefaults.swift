//
//  ChoiceUserDefaults.swift
//  BurntFoundation
//
//  Created by Patrick Smith on 12/05/2015.
//  Copyright (c) 2015 Patrick Smith. All rights reserved.
//

import Foundation


public protocol UserDefaultsChoiceRepresentable : RawRepresentable {
	static var identifier: String { get }
	static var defaultValue: Self { get }
}


public extension UserDefaults {
	
	// MARK: Int
	
	public func choice
		<T : UserDefaultsChoiceRepresentable>
		(_ choiceType: T.Type) -> T where T.RawValue == Int
	{
		if let value = T(rawValue: integer(forKey: T.identifier)) {
			return value
		}
		else {
			return T.defaultValue
		}
	}
	
	public func setChoice
		<T : UserDefaultsChoiceRepresentable>
		(_ choice: T) where T.RawValue == Int
	{
		set(choice.rawValue, forKey: T.identifier)
	}
	
	// MARK: String
	
	public func choice
		<T : UserDefaultsChoiceRepresentable>
		(_ choiceType: T.Type) -> T where T.RawValue == String
	{
		if let
			stringValue = string(forKey: T.identifier),
			let value = T(rawValue: stringValue)
		{
			return value
		}
		else {
			return T.defaultValue
		}
	}
	
	public func setChoice
		<T : UserDefaultsChoiceRepresentable>
		(_ choice: T) where T.RawValue == String
	{
		set(choice.rawValue, forKey: T.identifier)
	}
	
	// MARK: Bool
	
	public func choice
		<T : UserDefaultsChoiceRepresentable>
		(_ choiceType: T.Type) -> T where T.RawValue == Bool
	{
		if let value = T(rawValue: bool(forKey: T.identifier)) {
			return value
		}
		else {
			return T.defaultValue
		}
	}
	
	public func setChoice
		<T : UserDefaultsChoiceRepresentable>
		(_ choice: T) where T.RawValue == Bool
	{
		set(choice.rawValue, forKey: T.identifier)
	}
}
