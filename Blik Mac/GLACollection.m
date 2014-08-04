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


@implementation GLACollection

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return
	@{
	  @"UUID": @"UUID",
	  @"title": @"title",
	  @"colorIdentifier": @"colorIdentifier"
	};
}

+ (NSValueTransformer *)UUIDJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

+ (NSValueTransformer *)colorIdentifierValueTransformer
{
	static NSValueTransformer *vt;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSDictionary *stringToColorIdentifiers =
		@{
		  [NSNull null]: @(GLACollectionColorUnknown),
		  @"lightBlue": @(GLACollectionColorLightBlue),
		  @"green": @(GLACollectionColorGreen),
		  @"pinkyPurple": @(GLACollectionColorPinkyPurple),
		  @"red": @(GLACollectionColorRed),
		  @"yellow": @(GLACollectionColorYellow)
		  };
		
		vt = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:stringToColorIdentifiers defaultValue:@(GLACollectionColorUnknown) reverseDefaultValue:[NSNull null]];
	});
	return vt;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _UUID = [NSUUID new];
		//_title = @"";
		_colorIdentifier = GLACollectionColorUnknown;
    }
    return self;
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

+ (instancetype)dummyCollectionWithTitle:(NSString *)title colorIdentifier:(GLACollectionColor)colorIdentifier
{
	GLACollection *item = [self new];
	(item.title) = title;
	(item.colorIdentifier) = colorIdentifier;
	
	return item;
}

@end
