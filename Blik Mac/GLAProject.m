//
//  GLAProject.m
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAProject.h"
#import "GLAProjectCollectionListEditor.h"
#import "NSValueTransformer+GLAModel.h"


@interface GLAProject ()

@property(readwrite, copy, nonatomic) NSArray *collectionsForMantle;
@property(readwrite, copy, nonatomic) NSArray *loadedCollections;
@property(readonly, nonatomic) GLAProjectCollectionListEditor *collectionListEditor;

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
	return [(self.collectionListEditor.mutableCollections) copy];
}

- (void)setCollectionsForMantle:(NSArray *)collections
{
	(self.loadedCollections) = collections;
}

- (NSArray *)collectionsForMantle
{
	return [self copyCollections];
}

- (id<GLACollectionListEditing>)collectionsEditing
{
	if (!_collectionListEditor) {
		_collectionListEditor = [[GLAProjectCollectionListEditor alloc] initWithCollections:(self.loadedCollections)];
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
