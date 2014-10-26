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

@property(readwrite, nonatomic) NSUUID *UUID;
@property(readwrite, copy, nonatomic) NSString *name;

@property(readwrite, nonatomic) NSString *type;

@property(readwrite, nonatomic) GLACollectionColor *color;
@property(readwrite, nonatomic) NSString *colorIdentifier;

@end

@implementation GLACollection

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return
	@{
	  @"color": (NSNull.null),
	};
}

+ (NSValueTransformer *)UUIDJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

+ (NSValueTransformer *)projectUUIDJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _UUID = [NSUUID new];
    }
    return self;
}

- (NSString *)colorIdentifier
{
	return (self.color.identifier);
}

- (void)setColorIdentifier:(NSString *)colorIdentifier
{
	(self.color) = [[GLACollectionColor alloc] initWithIdentifier:colorIdentifier];
}

+ (instancetype)newWithType:(NSString *)collectionType creatingFromEditing:(void(^)(id<GLACollectionEditing> editor))editingBlock
{
	GLACollection *collection = [self new];
	(collection.type) = collectionType;
	editingBlock(collection);
	
	return collection;
}

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLACollectionEditing>editor))collectionEditingBlock
{
	GLACollection *copy = [self copy];
	collectionEditingBlock(copy);
	
	return copy;
}

@end


@implementation GLACollection (PasteboardSupport)

NSString *GLACollectionJSONPasteboardType = @"com.burntcaramel.GLACollection.JSONPasteboardType";

#pragma mark NSPasteboardReading

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard
{
	return @[GLACollectionJSONPasteboardType];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard
{
	return NSPasteboardReadingAsData;
}

- (instancetype)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type
{
	if (![type isEqualToString:GLACollectionJSONPasteboardType] || [propertyList isKindOfClass:[NSData class]]) {
		return nil;
	}
	
	NSData *jsonData = propertyList;
	NSError *error = nil;
	NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
	if (!jsonDictionary) {
		return nil;
	}
	
	self = [super initWithDictionary:jsonDictionary error:&error];
	if (self) {
		
	}
	return self;
}

#pragma mark NSPasteboardWriting

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
	return @[GLACollectionJSONPasteboardType];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
	NSDictionary *selfAsJSON = [MTLJSONAdapter JSONDictionaryFromModel:self];
	NSError *error = nil;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:selfAsJSON options:0 error:&error];
	return jsonData;
}

#pragma mark -

+ (BOOL)canCopyCollectionsFromPasteboard:(NSPasteboard *)pboard
{
	NSString *pboardType = [pboard availableTypeFromArray:@[GLACollectionJSONPasteboardType]];
	if (!pboardType) {
		return NO;
	}
	
	return YES;
}

+ (NSArray *)copyCollectionsFromPasteboard:(NSPasteboard *)pboard
{
	NSString *pboardType = [pboard availableTypeFromArray:@[GLACollectionJSONPasteboardType]];
	if (!pboardType) {
		return nil;
	}
	
	return [pboard readObjectsForClasses:@[[GLACollection class]] options:nil];
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
