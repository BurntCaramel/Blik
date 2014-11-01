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
	if (JSONDictionary[@"collection"]) {
		return [GLAHighlightedCollection class];
	}
	else if (JSONDictionary[@"collectedFile"]) {
		return [GLAHighlightedCollectedFile class];
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

+ (instancetype)newCreatingFromEditing:(void(^)(id<GLAHighlightedCollectionEditing> editor))editingBlock
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

@property(readwrite, nonatomic) GLACollectedFile *collectedFile;
@property(readwrite, nonatomic) GLACollection *holdingCollection;

@property(readwrite, nonatomic) GLACollectedFile *applicationToOpenFile;

@end

@implementation GLAHighlightedCollectedFile

+ (NSString *)objectJSONPasteboardType
{
	return @"com.burntcaramel.GLAHighlightedCollectedFile.JSONPasteboardType";
}

+ (NSValueTransformer *)collectedFileJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLACollectedFile class]];
}

+ (NSValueTransformer *)holdingCollectionJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLACollection class]];
}

+ (NSValueTransformer *)applicationToOpenFileJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLACollectedFile class]];
}

+ (instancetype)newCreatingFromEditing:(void(^)(id<GLAHighlightedCollectedFileEditing> editor))editingBlock
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