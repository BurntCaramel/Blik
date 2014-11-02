//
//  GLAHighlightedItem.m
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAHighlightedItem.h"


@implementation GLAHighlightedItem

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return @{};
}

+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary
{
	if (JSONDictionary[@"collectedFileUUID"]) {
		return [GLAHighlightedCollectedFile class];
	}
	else if (JSONDictionary[@"collection"]) {
		return [GLAHighlightedCollection class];
	}
	else {
		return nil;
	}
}

@end



@interface GLAHighlightedCollection () <GLAHighlightedCollectionEditing>

@property(readwrite, nonatomic) GLACollection *collection;

@end

@implementation GLAHighlightedCollection

+ (NSString *)objectJSONPasteboardType
{
	return @"com.burntcaramel.GLAHighlightedCollection.JSONPasteboardType";
}

+ (NSValueTransformer *)collectionJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLACollection class]];
}

+ (instancetype)newCreatedFromEditing:(void(^)(id<GLAHighlightedCollectionEditing> editor))editingBlock
{
	GLAHighlightedCollection *instance = [self new];
	editingBlock(instance);
	
	return instance;
}

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedCollectionEditing>editor))editingBlock
{
	GLAHighlightedCollection *copy = [self copy];
	editingBlock(copy);
	
	return copy;
}

@end



@interface GLAHighlightedCollectedFile () <GLAHighlightedCollectedFileEditing>

@property(readwrite, nonatomic) NSUUID *holdingCollectionUUID;
@property(readwrite, nonatomic) NSUUID *collectedFileUUID;

@property(readwrite, nonatomic) GLACollectedFile *applicationToOpenFile;

@end

@implementation GLAHighlightedCollectedFile

+ (NSString *)objectJSONPasteboardType
{
	return @"com.burntcaramel.GLAHighlightedCollectedFile.JSONPasteboardType";
}

+ (NSValueTransformer *)holdingCollectionUUIDJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

+ (NSValueTransformer *)collectedFileUUIDJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

+ (NSValueTransformer *)applicationToOpenFileJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLACollectedFile class]];
}

+ (instancetype)newCreatedFromEditing:(void(^)(id<GLAHighlightedCollectedFileEditing> editor))editingBlock
{
	GLAHighlightedCollectedFile *instance = [self new];
	editingBlock(instance);
	
	return instance;
}

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedCollectedFileEditing>editor))editingBlock
{
	GLAHighlightedCollectedFile *copy = [self copy];
	editingBlock(copy);
	
	return copy;
}

@end