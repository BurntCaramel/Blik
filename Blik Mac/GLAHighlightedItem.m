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

@property(readwrite, copy, nonatomic) NSString * __nullable customName;

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

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedItemEditing>editor))editingBlock
{
	GLAHighlightedItem *copy = [self copy];
	editingBlock(copy);
	
	return copy;
}

@end


#pragma mark -

@interface GLAHighlightedCollectedFile ()

@property(readwrite, nonatomic) NSUUID *holdingCollectionUUID;
@property(readwrite, nonatomic) NSUUID *collectedFileUUID;

@property(readwrite, nonatomic) GLACollectedFile *applicationToOpenFile;

@end

@interface GLAHighlightedCollectedFile (GLAHighlightedCollectedFileEditing) <GLAHighlightedCollectedFileEditing>
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

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAHighlightedCollectedFileEditing>editor))editingBlock
{
	return [super copyWithChangesFromEditing:editingBlock];
}

@end