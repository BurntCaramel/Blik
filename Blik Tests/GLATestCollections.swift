//
//  GLATestCollections.swift
//  Blik
//
//  Created by Patrick on 8/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

import Cocoa
import XCTest


class GLATestCollections: XCTestCase {

    override func setUp()
	{
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown()
	{
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func newCollection(name: String = "Test collection") -> GLACollection
	{
		let collection = GLACollection(type: GLACollectionTypeFilesList) { editor in
			editor.projectUUID = NSUUID()
			editor.name = name
		}
	
		return collection
	}

    func testCreateCollection()
	{
		let name = "ABCDEF"
		let collection = newCollection(name)
		XCTAssertNotNil(collection, "Collection was made");
		XCTAssertEqual(collection.name, name, "Name is correct");
    }
	
	func testJSONifyCollection()
	{
		let collection = newCollection("Test collection");
		XCTAssertNotNil(collection, "Collection was created")
	
		let JSONDictionary = MTLJSONAdapter.JSONDictionaryFromModel(collection)
		XCTAssertNotNil(JSONDictionary, "JSON dictionary is not nil")
	
		let isValidJSON = NSJSONSerialization.isValidJSONObject(JSONDictionary)
		XCTAssertTrue(isValidJSON, "JSON dictionary is valid")
		
		let modelClass = GLACollection.self
		var error: NSError?
		let collectionFromJSON: GLACollection = (try! MTLJSONAdapter.modelOfClass(modelClass, fromJSONDictionary: JSONDictionary)) as! GLACollection
		
		XCTAssertNotNil(collectionFromJSON, "Created collection from JSON")
		XCTAssertEqual(collection.UUID, collectionFromJSON.UUID, "Have same UUID")
		XCTAssertEqual(collection.name, collectionFromJSON.name, "Have same name")
	}
	
	func testCreateCollectedFile()
	{
		let collectedFile = GLACollectedFile(fileURL: NSURL(fileURLWithPath: NSHomeDirectory()))
		XCTAssertNotNil(collectedFile, "Collected file was created")
		
		let bookmarkData = collectedFile.bookmarkData
		XCTAssertNotNil(bookmarkData, "Bookmark data")
		
		let JSONDictionary = MTLJSONAdapter.JSONDictionaryFromModel(collectedFile)
		XCTAssertNotNil(JSONDictionary, "JSON dictionary is not nil")
		XCTAssertNotNil(JSONDictionary["bookmarkData"], "Has 'bookmarkData' JSON key")
		
		let isValidJSON = NSJSONSerialization.isValidJSONObject(JSONDictionary)
		XCTAssertTrue(isValidJSON, "JSON dictionary is valid")
		
		var error: NSError?
		let recreatedCollectedFile = MTLJSONAdapter.modelOfClass(GLACollectedFile.self, fromJSONDictionary: JSONDictionary) as? GLACollectedFile
		XCTAssertNotNil(recreatedCollectedFile, "Recreated collected file")
	}
	
	func testCreateHighlightedCollectedItem()
	{
		let collection = newCollection()
		
		let collectedFile = GLACollectedFile(fileURL: NSURL(fileURLWithPath: NSHomeDirectory()))
		XCTAssertNotNil(collectedFile, "Collected file was created")
		
		let highlightedItem = GLAHighlightedCollectedFile { (editor) -> Void in
			editor.holdingCollectionUUID = collection.UUID
			editor.collectedFileUUID = collectedFile.UUID
		}
		
		let JSONDictionary = MTLJSONAdapter.JSONDictionaryFromModel(highlightedItem)
		XCTAssertNotNil(JSONDictionary, "JSON dictionary is not nil")
		XCTAssertNotNil(JSONDictionary["holdingCollectionUUID"], "Has 'holdingCollectionUUID' JSON key")
		XCTAssertNotNil(JSONDictionary["collectedFileUUID"], "Has 'collectedFileUUID' JSON key")
		
		let isValidJSON = NSJSONSerialization.isValidJSONObject(JSONDictionary)
		XCTAssertTrue(isValidJSON, "JSON dictionary is valid")
		
		let modelClass = GLAHighlightedCollectedFile.self
		var error: NSError?
		let highlightedItemFromJSON: GLAHighlightedCollectedFile = (try! MTLJSONAdapter.modelOfClass(modelClass, fromJSONDictionary: JSONDictionary)) as! GLAHighlightedCollectedFile
		
		XCTAssertNotNil(highlightedItemFromJSON, "Created highlighted item from JSON")
		XCTAssertEqual(highlightedItem.UUID, highlightedItemFromJSON.UUID, "Have same UUID")
		XCTAssertEqual(highlightedItem.holdingCollectionUUID, highlightedItemFromJSON.holdingCollectionUUID, "Have same holdingCollectionUUID")
		XCTAssertEqual(highlightedItem.collectedFileUUID, highlightedItemFromJSON.collectedFileUUID, "Have same collectedFileUUID")
	}
	
	/*
    func testPerformanceExample()
	{
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }*/

}
