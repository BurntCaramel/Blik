//
//  GLAProjectItem.m
//  Blik
//
//  Created by Patrick Smith on 18/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLACollection.h"
#import "NSValueTransformer+GLAModel.h"
#import "GLACollectionColor.h"


@interface GLACollection () <GLACollectionEditing>

@property(readwrite, copy, nonatomic) NSUUID *projectUUID;

@property(readwrite, copy, nonatomic) NSString *name;

@property(readwrite, nonatomic) NSString *type;

@property(readwrite, nonatomic) GLACollectionColor *color;
@property(readwrite, nonatomic) NSString *colorIdentifier;

@end

@implementation GLACollection

+ (NSString *)objectJSONPasteboardType
{
	return @"com.burntcaramel.GLACollection.JSONPasteboardType";
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return
	@{
	  @"color": (NSNull.null),
	};
}

+ (NSValueTransformer *)projectUUIDJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

- (NSString *)colorIdentifier
{
	return (self.color.identifier);
}

- (void)setColorIdentifier:(NSString *)colorIdentifier
{
	(self.color) = [[GLACollectionColor alloc] initWithIdentifier:colorIdentifier];
}

- (instancetype)initWithType:(NSString *)collectionType creatingFromEditing:(void(^)(id<GLACollectionEditing> editor))editingBlock
{
	self = [super init];
	if (self) {
		(self.type) = collectionType;
		editingBlock(self);
	}
	return self;
}

+ (instancetype)newWithType:(NSString *)collectionType creatingFromEditing:(void(^)(id<GLACollectionEditing> editor))editingBlock
{
	return [[self alloc] initWithType:collectionType creatingFromEditing:editingBlock];
}

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLACollectionEditing>editor))collectionEditingBlock
{
	GLACollection *copy = [self copy];
	collectionEditingBlock(copy);
	
	return copy;
}

@end


@implementation GLACollection (GLADummyContent)

+ (instancetype)dummyCollectionWithName:(NSString *)name color:(GLACollectionColor *)color type:(NSString *)collectionType
{
	return [self newWithType:collectionType creatingFromEditing:^(id<GLACollectionEditing> collectionEditor) {
		(collectionEditor.name) = name;
		(collectionEditor.color) = color;
	}];
}

@end


@implementation GLACollection (GLACollection_ProjectEditing)

@end


NSString *GLACollectionTypeFilesList = @"filesList";
