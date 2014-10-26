//
//  GLAModel.m
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAModel.h"


@implementation GLAModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return @{};
}

@end


@implementation GLAModel (PasteboardSupport)

+ (NSString *)objectJSONPasteboardType
{
	NSAssert(NO, @"+[GLAModel objectJSONPasteboardType] must be overridden.");
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
	if (![type isEqualToString:[[self class] objectJSONPasteboardType]] || [propertyList isKindOfClass:[NSData class]]) {
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