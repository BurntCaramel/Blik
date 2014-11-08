//
//  GLATestCollectionsObjC.m
//  Blik
//
//  Created by Patrick on 8/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "Mantle/Mantle.h"
#import "GLACollection.h"


@interface GLATestCollectionsObjC : XCTestCase

@end

@implementation GLATestCollectionsObjC

- (void)setUp
{
	[super setUp];
	// Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
	// Put teardown code here. This method is called after the invocation of each test method in the class.
	[super tearDown];
}

- (GLACollection *)newCollection
{
	GLACollection *collection = [[GLACollection alloc] initWithType:GLACollectionTypeFilesList creatingFromEditing:^(id<GLACollectionEditing> editor) {
		(editor.projectUUID) = [NSUUID new];
		(editor.name) = @"Test Collection Name";
	}];
	
	return collection;
}

- (void)testCreateCollection
{
	// This is an example of a functional test case.
	GLACollection *collection = [self newCollection];
	XCTAssert(collection != nil, @"Collection is not nil");
}

- (void)testJSONifyCollection
{
	GLACollection *collection = [self newCollection];
	XCTAssertNotNil(collection, @"Collection is not nil");
	
	NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:collection];
	XCTAssertNotNil(JSONDictionary, @"JSON dictionary is not nil");
	
	BOOL isValidJSON = [NSJSONSerialization isValidJSONObject:JSONDictionary];
	XCTAssertTrue(isValidJSON, @"JSON dictionary is valid");
}

#if 0
- (void)testPerformanceExample
{
	// This is an example of a performance test case.
	[self measureBlock:^{
		// Put the code you want to measure the time of here.
	}];
}
#endif

@end
