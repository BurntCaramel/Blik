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

@property(readwrite, copy, nonatomic) NSArray *collections;
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
	  @"title": @"title",
	  @"collections": @"collections",
	  @"reminders": @"reminders"
	  };
}

+ (NSValueTransformer *)UUIDJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

+ (NSValueTransformer *)collectionsJSONTransformer
{
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[GLACollection class]];
}

+ (NSValueTransformer *)remindersJSONTransformer
{
	return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[GLAReminder class]];
}



- (void)setCollections:(NSArray *)collections
{
	(self.loadedCollections) = collections;
}

- (NSArray *)copyCollections
{
	return [(self.collectionListEditor.mutableCollections) copy];
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
