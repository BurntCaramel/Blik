//
//  GLAModel.m
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAModel.h"


@interface GLAModel ()

@property(readwrite, nonatomic) NSUUID *UUID;

@end

@implementation GLAModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return @{};
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
	}
	return self;
}
/*
 // Not sure what behaviour is right here.
- (BOOL)isEqual:(id)object
{
	if (object == self) {
		return YES;
	}
	if (!object || [object isKindOfClass:[GLAModel class]]) {
		return NO;
	}
	
	GLAModel *model
}
*/
- (instancetype)duplicate
{
	GLAModel *copy = [self copy];
	(copy.UUID) = [NSUUID new];
	
	return copy;
}

@end


@implementation GLAModel (PasteboardSupport)

+ (NSString *)objectJSONPasteboardType
{
	NSAssert(NO, @"+[GLAModel objectJSONPasteboardType] must be overridden with e.g. com.yourcompany.class-name.JSONPasteboardType");
	return nil;
}

#pragma mark NSPasteboardReading

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard
{
	return @[[self objectJSONPasteboardType]];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard
{
	return NSPasteboardReadingAsData;
}

- (instancetype)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type
{
	BOOL isValid = [type isEqualToString:[[self class] objectJSONPasteboardType]] && [propertyList isKindOfClass:[NSData class]];
	if (!isValid) {
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
	return @[[[self class] objectJSONPasteboardType]];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
	NSDictionary *selfAsJSON = [MTLJSONAdapter JSONDictionaryFromModel:self];
	NSError *error = nil;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:selfAsJSON options:0 error:&error];
	return jsonData;
}

#pragma mark -

+ (BOOL)canCopyObjectsFromPasteboard:(NSPasteboard *)pboard
{
	NSString *pboardType = [pboard availableTypeFromArray:@[[self objectJSONPasteboardType]]];
	if (!pboardType) {
		return NO;
	}
	
	return YES;
}

+ (NSArray *)copyObjectsFromPasteboard:(NSPasteboard *)pboard
{
	NSString *pboardType = [pboard availableTypeFromArray:@[[self objectJSONPasteboardType]]];
	if (!pboardType) {
		return nil;
	}
	
	return [pboard readObjectsForClasses:@[[self class]] options:nil];
}

@end