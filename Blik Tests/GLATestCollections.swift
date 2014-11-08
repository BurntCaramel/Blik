//
//  GLATestCollections.swift
//  Blik
//
//  Created by Patrick on 8/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

import Cocoa
import XCTest
//import GLACollection


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
	
	func newCollection() -> GLACollection
	{
		let collection = GLACollection(type: GLACollectionTypeFilesList) { (editor) -> Void in
			editor.projectUUID = NSUUID()
			editor.name = "Test collection"
		}
	
		return collection
	}

    func testCreateCollection()
	{
		let collection = newCollection()
		XCTAssertNotNil(collection, "Collection was made");
    }
	
	func testJSONifyCollection()
	{
		let collection = newCollection();
		XCTAssertNotNil(collection, "Collection was created")
	
		let JSONDictionary = MTLJSONAdapter.JSONDictionaryFromModel(collection)
		XCTAssertNotNil(JSONDictionary, "JSON dictionary is not nil")
	
		let isValidJSON = NSJSONSerialization.isValidJSONObject(JSONDictionary)
		XCTAssertTrue(isValidJSON, "JSON dictionary is valid")
	}
	
	func testCreateCollectedFile()
	{
		let collectedFile = GLACollectedFile(fileURL: NSURL(fileURLWithPath: NSHomeDirectory()))
		XCTAssertNotNil(collectedFile, "Collected file was created")
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
		let highlightedItemFromJSON: GLAHighlightedCollectedFile = MTLJSONAdapter.modelOfClass(modelClass, fromJSONDictionary: JSONDictionary, error: &error) as GLAHighlightedCollectedFile
		
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
