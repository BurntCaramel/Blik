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

+ (instancetype)dummyCollectionWithTitle:(NSString *)title colorIdentifier:(GLACollectionColor)colorIdentifier
{
	GLACollection *item = [self new];
	(item.title) = title;
	(item.colorIdentifier) = colorIdentifier;
	
	return item;
}

@end
