//
//  IdentifierUniter.swift
//  Blik
//
//  Created by Patrick Smith on 8/06/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


func commonPrefix(stringA: String, stringB: String, separators: Set<Character>) -> String? {
	var prefix = ""
	
	for (characterA, characterB) in Zip2(stringA, stringB) {
		if characterA != characterB {
			break
		}
		else if separators.contains(characterA) {
			break
		}
		
		prefix.append(characterA)
	}
	
	if prefix == "" {
		return nil
	}
	else {
		return prefix
	}
}

func commonSuffix(stringA: String, stringB: String, separators: Set<Character>) -> String? {
	var suffix = ""
	
	for (characterA, characterB) in Zip2(reverse(stringA), reverse(stringB)) {
		if characterA != characterB {
			break
		}
		else if separators.contains(characterA) {
			break
		}
		
		suffix.insert(characterA, atIndex: suffix.startIndex)
	}
	
	if suffix == "" {
		return nil
	}
	else {
		return suffix
	}
}


struct IdentifierGroup {
	var commonComponents: [String]
	var identifiers: [String]
	var validSeparators: Set<Character>
	
	init?(stringA: String, stringB: String, validSeparators: Set<Character>) {
		if let prefix = commonPrefix(stringA, stringB, validSeparators) {
			commonComponents = [prefix]
			identifiers = [stringA, stringB]
			self.validSeparators = validSeparators
		}
		else {
			return nil
		}
	}
	
	mutating func addIdentifier(identifier: String) {
		identifiers.append(identifier)
	}
	
	func hasSameCommonComponentsAs(other: IdentifierGroup) -> Bool {
		return equal(commonComponents, other.commonComponents)
	}
}


public class IdentifierUniter {
	public private(set) var sortedIdentifiers = [String]()
	var identifierGroups = [IdentifierGroup]()
	var identifierToGroupIndex = [String: Int]()
	
	var validSeparators = Set([Character(" "), Character("-"), Character("_"), Character("."), Character("+")])
	
	private func sort() {
		//sort(&identifiers)
		sortedIdentifiers.sort { (identifierA, identifierB) -> Bool in
			return identifierA < identifierB
		}
	}
	
	private func group() {
		identifierGroups.removeAll(keepCapacity: true)
		
		var previousIdentifier: String?
		var activeIdentifierGroupIndex: Int?
		
		for identifier in sortedIdentifiers {
			if let previousIdentifier = previousIdentifier {
				if let identifierGroup = IdentifierGroup(stringA: previousIdentifier, stringB: identifier, validSeparators: validSeparators) {
					if var activeIdentifierGroupIndex = activeIdentifierGroupIndex where identifierGroups[activeIdentifierGroupIndex].hasSameCommonComponentsAs(identifierGroup) {
						identifierGroups[activeIdentifierGroupIndex].addIdentifier(identifier)
					}
					else {
						activeIdentifierGroupIndex = identifierGroups.endIndex
						identifierGroups.append(identifierGroup)
					}
				}
				else {
					activeIdentifierGroupIndex = nil
				}
			}
			previousIdentifier = identifier
		}
	}
	
	public func addIdentifiers(identifiers: [String]) {
		sortedIdentifiers.extend(identifiers)
		sort()
		group()
	}
	
	public func commonPrefixesForIdentifier(identifier: String) -> [String]? {
		if let groupIndex = identifierToGroupIndex[identifier] {
			let group = identifierGroups[groupIndex]
			return group.commonComponents
		}
		else {
			return nil
		}
	}
}
