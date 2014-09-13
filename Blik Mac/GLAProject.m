//
//  GLAProject.m
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAProject.h"
#import "GLAArrayEditor.h"
#import "NSValueTransformer+GLAModel.h"


@interface GLAProject ()

@property(readwrite, nonatomic) NSUUID *UUID;
@property(readwrite, copy, nonatomic) NSString *name;
@property(readwrite, nonatomic) NSDate *dateCreated;

#if 0
@property(copy, nonatomic) NSArray *collectionUUIDs;
#endif

#if 0
@property(copy, nonatomic) NSArray *collectionsForMantle;
@property(copy, nonatomic) NSArray *loadedCollections;
@property(readonly, nonatomic) GLAArrayEditor *collectionListEditor;
#endif

@property(nonatomic) NSArray *mutableReminders;

@end

@implementation GLAProject

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return
	@{
	  @"UUID": @"UUID",
	  @"name": @"name",
	  @"dateCreated": @"dateCreated",
	  //@"collectionUUIDs": @"collectionUUIDs",
	  @"remindersForMantle": @"reminders",
	  @"loadedCollections": (NSNull.null),
	  @"collectionListEditor": (NSNull.null),
	  @"mutableReminders": (NSNull.null)
	  };
}

+ (NSValueTransformer *)UUIDJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

+ (NSValueTransformer *)dateCreatedJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLADateRFC3339ValueTransformerName];
}

+ (NSValueTransformer *)collectionUUIDsJSONTransformer
{
	NSValueTransformer *UUIDValueTransformer = [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
	
	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSArray *JSONArrayOfUUIDs) {
		if (!JSONArrayOfUUIDs) {
			return nil;
		}
		
		NSMutableArray *UUIDs = [NSMutableArray array];
		for (id JSONValue in JSONArrayOfUUIDs) {
			NSUUID *UUID = [UUIDValueTransformer transformedValue:JSONValue];
			if (UUID && [UUID isKindOfClass:[NSUUID class]]) {
				[UUIDs addObject:UUID];
			}
		}
		
		return UUIDs;
	} reverseBlock:^id(NSArray *UUIDs) {
		if (!UUIDs) {
			return nil;
		}
		
		NSMutableArray *JSONArrayOfUUIDs = [NSMutableArray array];
		for (NSUUID *UUID in UUIDs) {
			id JSONValue = [UUIDValueTransformer reverseTransformedValue:UUID];
			if (JSONValue) {
				[JSONArrayOfUUIDs addObject:JSONValue];
			}
		}
		
		return JSONArrayOfUUIDs;
	}];
}
#if 0
+ (NSValueTransformer *)collectionsForMantleJSONTransformer
{
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[GLACollection class]];
}

+ (NSValueTransformer *)remindersForMantleJSONTransformer
{
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[GLAReminder class]];
}
#endif
- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name dateCreated:(NSDate *)dateCreated
{
	self = [super init];
	if (self) {
		if (!UUID) {
			UUID = [NSUUID UUID];
		}
		
		if (!dateCreated) {
			dateCreated = [NSDate date];
		}
		
		_UUID = UUID;
		_name = name;
		_dateCreated = dateCreated;
	}
	return self;
}

- (instancetype)init
{
	return [self initWithUUID:nil name:nil dateCreated:nil];
}
#if 0
- (NSArray *)copyCollections
{
	return [(self.collectionListEditor) copyChildren];
}

- (void)setCollectionsForMantle:(NSArray *)collections
{
	(self.loadedCollections) = collections;
}

- (NSArray *)collectionsForMantle
{
	return [self copyCollections];
}

- (id<GLAArrayEditing>)collectionsEditing
{
	if (!_collectionListEditor) {
		NSArray *collections = (self.loadedCollections);
		if (!collections) {
			collections = [NSArray array];
		}
		_collectionListEditor = [[GLAArrayEditor alloc] initWithObjects:collections];
	}
	
	return _collectionListEditor;
}
#endif
- (NSSet *)copyRemindersOrderedByPriority
{
	return [(self.mutableReminders) copy];
}

- (id<GLAReminderListEditing>)remindersEditing
{
	return nil;
}

@end
