//
//  GLAProjectItem.m
//  Blik
//
//  Created by Patrick Smith on 18/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollection.h"
#import "NSValueTransformer+GLAModel.h"
#import "GLACollectionContent.h"
#import "GLACollectionColor.h"


@interface GLACollection () <GLACollectionEditing>

@property(readwrite, nonatomic) GLACollectionContent *content;

@property(readwrite, nonatomic) NSUUID *UUID;
@property(readwrite, copy, nonatomic) NSString *title;

@property(readwrite, nonatomic) GLACollectionColor *color;

@property(readwrite, nonatomic) NSString *colorIdentifier;

@end

@implementation GLACollection

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return
	@{
	  @"project": (NSNull.null),
	  @"content": @"content",
	  @"UUID": @"UUID",
	  @"title": @"title",
	  @"color": (NSNull.null),
	  @"colorIdentifier": @"colorIdentifier"
	};
}

+ (NSValueTransformer *)contentJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLACollectionContent class]];
}

+ (NSValueTransformer *)UUIDJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _UUID = [NSUUID new];
		//_title = @"";
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

+ (instancetype)newWithCreationFromEditing:(void (^)(id<GLACollectionEditing>))editingBlock
{
	GLACollection *collection = [self new];
	editingBlock(collection);
	
	return collection;
}

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLACollectionEditing>collectionEditor))collectionEditingBlock
{
	GLACollection *copy = [self copy];
	collectionEditingBlock(copy);
	
	return copy;
}

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

@end


@implementation GLACollection (PasteboardSupport)

NSString *GLACollectionJSONPasteboardType = @"com.burntcaramel.GLACollection.JSONPasteboardType";

- (NSPasteboardItem *)newPasteboardItem
{
	NSDictionary *selfAsJSON = [MTLJSONAdapter JSONDictionaryFromModel:self];
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:selfAsJSON options:0 error:NULL];
	return [[NSPasteboardItem alloc] initWithPasteboardPropertyList:jsonData ofType:GLACollectionJSONPasteboardType];
}

+ (void)writeCollections:(NSArray *)collections toPasteboard:(NSPasteboard *)pboard
{
	[pboard writeObjects:collections];
}

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

+ (instancetype)dummyCollectionWithTitle:(NSString *)title color:(GLACollectionColor *)color content:(GLACollectionContent *)content
{
	GLACollection *item = [self new];
	(item.title) = title;
	(item.color) = color;
	(item.content) = content;
	
	return item;
}

@end
