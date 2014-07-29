//
//  GLAProjectItem.m
//  Blik
//
//  Created by Patrick Smith on 18/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollection.h"
#import "NSValueTransformer+GLAModel.h"


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

@end


@implementation GLACollection (PasteboardSupport)

NSString *GLACollectionJSONPasteboardType = @"com.burntcaramel.GLACollection.JSONPasteboardType";

- (NSPasteboardItem *)newPasteboardItem
{
	NSDictionary *selfAsJSON = [MTLJSONAdapter JSONDictionaryFromModel:self];
	return [[NSPasteboardItem alloc] initWithPasteboardPropertyList:selfAsJSON ofType:GLACollectionJSONPasteboardType];
}

+ (void)writeCollections:(NSArray *)collections toPasteboard:(NSPasteboard *)pboard
{
	[pboard declareTypes:@[GLACollectionJSONPasteboardType] owner:nil];
	
	NSArray *draggedCollectionsJSON = [MTLJSONAdapter JSONArrayFromModels:collections];
	[pboard setPropertyList:draggedCollectionsJSON forType:GLACollectionJSONPasteboardType];
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
	
	id possibleCollectionsJSON = [pboard propertyListForType:GLACollectionJSONPasteboardType];
	if (![possibleCollectionsJSON isKindOfClass:[NSArray class]]) {
		return nil;
	}
	
	NSArray *collectionsJSON = possibleCollectionsJSON;
	NSError *error = nil;
	NSArray *collections = [MTLJSONAdapter modelsOfClass:[self class] fromJSONArray:collectionsJSON error:&error];
	
	return collections;
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
