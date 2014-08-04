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

@property(copy, nonatomic) NSArray *collectionsForMantle;
@property(copy, nonatomic) NSArray *loadedCollections;
@property(readonly, nonatomic) GLAArrayEditor *collectionListEditor;

@property(nonatomic) NSArray *mutableReminders;

@end

@implementation GLAProject

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return
	@{
	  @"UUID": @"UUID",
	  @"name": @"name",
	  @"collections": @"collectionsForMantle",
	  @"reminders": @"remindersForMantle"
	  };
}

+ (NSValueTransformer *)UUIDJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

+ (NSValueTransformer *)collectionsForMantleJSONTransformer
{
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[GLACollection class]];
}

+ (NSValueTransformer *)remindersForMantleJSONTransformer
{
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[GLAReminder class]];
}


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

- (NSSet *)copyRemindersOrderedByPriority
{
	return [(self.mutableReminders) copy];
}

- (id<GLAReminderListEditing>)remindersEditing
{
	return nil;
}

@end
