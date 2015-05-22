//
//  ChoiceUserDefaults.swift
//  BurntFoundation
//
//  Created by Patrick Smith on 12/05/2015.
//  Copyright (c) 2015 Patrick Smith. All rights reserved.
//

import Foundation


public protocol UserDefaultsChoiceRepresentable: RawRepresentable {
	static var defaultsKey: String { get }
}


public extension NSUserDefaults {
	
	// MARK: Int
	
	public func intChoiceWithFallback<T: UserDefaultsChoiceRepresentable where T.RawValue == Int>(fallbackChoice: T) -> T {
		if let value = T(rawValue: integerForKey(T.defaultsKey)) {
			return value
		}
		else {
			return fallbackChoice
		}
	}
	
	// Int
	public func setIntChoice<T: UserDefaultsChoiceRepresentable where T.RawValue == Int>(choice: T) {
		setInteger(choice.rawValue, forKey: T.defaultsKey)
	}
	
	// Int
	public func registerDefaultForIntChoice<T: UserDefaultsChoiceRepresentable where T.RawValue == Int>(defaultChoice: T) {
		registerDefaults([
			T.defaultsKey: defaultChoice.rawValue
			])
	}
	
	// MARK: String
	
	public func stringChoiceWithFallback<T: UserDefaultsChoiceRepresentable where T.RawValue == String>(fallbackChoice: T) -> T {
		if let
			stringValue = stringForKey(T.defaultsKey),
			value = T(rawValue: stringValue) {
			return value
		}
		else {
			return fallbackChoice
		}
	}
	
	// String
	public func setStringChoice<T: UserDefaultsChoiceRepresentable where T.RawValue == String>(choice: T) {
		setObject(choice.rawValue, forKey: T.defaultsKey)
	}
	
	// String
	public func registerDefaultForStringChoice<T: UserDefaultsChoiceRepresentable where T.RawValue == String>(defaultChoice: T) {
		registerDefaults([
			T.defaultsKey: defaultChoice.rawValue
		])
	}
}
