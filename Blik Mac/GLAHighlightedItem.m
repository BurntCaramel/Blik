//
//  GLAHighlightedItem.m
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAHighlightedItem.h"


@interface GLAHighlightedItem ()

@property(readwrite, copy, nonatomic) NSUUID *projectUUID;

@end

@interface GLAHighlightedItem (GLAHighlightedItemEditing) <GLAHighlightedItemEditing>

@end

@implementation GLAHighlightedItem

+ (NSValueTransformer *)projectUUIDJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary
{
	if (JSONDictionary[@"collectedFileUUID"]) {
		return [GLAHighlightedCollectedFile class];
	}
	else {
		return nil;
	}
}

- (instancetype)initByEditing:(void(^)(id<GLAHighlightedItemEditing> editor))editingBlock
{
	self = [super init];
	if (self) {
		editingBlock(self);
	}
	return self;
}

+ (instancetype)newCreatedFromEditing:(void(^)(id<GLAHighlightedItemEditing> editor))editingBlock
{
	return [[self alloc] initByEditing:editingBlock];
}

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedItemEditing>editor))editingBlock
{
	GLAHighlightedItem *copy = [self copy];
	editingBlock(copy);
	
	return copy;
}

@end


#pragma mark -

#if 0

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

- (instancetype)initByEditing:(void(^)(id<GLAHighlightedCollectionEditing> editor))editingBlock
{
	return [super initByEditing:editingBlock];
}

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedCollectionEditing>editor))editingBlock
{
	GLAHighlightedCollection *copy = [self copy];
	editingBlock(copy);
	
	return copy;
}

@end

#endif


#pragma mark -

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

- (instancetype)initByEditing:(void(^)(id<GLAHighlightedCollectedFileEditing> editor))editingBlock
{
	return [super initByEditing:editingBlock];
}

+ (instancetype)newCreatedFromEditing:(void(^)(id<GLAHighlightedCollectedFileEditing> editor))editingBlock
{
	return [[self alloc] initByEditing:editingBlock];
}

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedCollectedFileEditing>editor))editingBlock
{
	return [super copyWithChangesFromEditing:editingBlock];
}

@end