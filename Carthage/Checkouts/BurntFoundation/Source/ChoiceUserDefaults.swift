//
//  ChoiceUserDefaults.swift
//  BurntFoundation
//
//  Created by Patrick Smith on 12/05/2015.
//  Copyright (c) 2015 Patrick Smith. All rights reserved.
//

import Foundation


public protocol UserDefaultsChoiceRepresentable: RawRepresentable {
	static var identifier: String { get }
	static var defaultValue: Self { get }
}


public extension NSUserDefaults {
	
	// MARK: Int
	
	public func choice<T: UserDefaultsChoiceRepresentable where T.RawValue == Int>(choiceType: T.Type) -> T {
		if let value = T(rawValue: integerForKey(T.identifier)) {
			return value
		}
		else {
			return T.defaultValue
		}
	}
	
	public func setChoice<T: UserDefaultsChoiceRepresentable where T.RawValue == Int>(choice: T) {
		setInteger(choice.rawValue, forKey: T.identifier)
	}
	
	// MARK: String
	
	public func choice<T: UserDefaultsChoiceRepresentable where T.RawValue == String>(choiceType: T.Type) -> T {
		if let
			stringValue = stringForKey(T.identifier),
			value = T(rawValue: stringValue)
		{
			return value
		}
		else {
			return T.defaultValue
		}
	}
	
	public func setChoice<T: UserDefaultsChoiceRepresentable where T.RawValue == String>(choice: T) {
		setObject(choice.rawValue, forKey: T.identifier)
	}
	
	// MARK: Bool
	
	public func choice<T: UserDefaultsChoiceRepresentable where T.RawValue == Bool>(choiceType: T.Type) -> T {
		if let value = T(rawValue: boolForKey(T.identifier)) {
			return value
		}
		else {
			return T.defaultValue
		}
	}
	
	public func setChoice<T: UserDefaultsChoiceRepresentable where T.RawValue == Bool>(choice: T) {
		setBool(choice.rawValue, forKey: T.identifier)
	}
}
