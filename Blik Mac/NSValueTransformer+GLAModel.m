//
//  NSValueTransformer+GLAModel.m
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "NSValueTransformer+GLAModel.h"


NSString *const GLAUUIDValueTransformerName = @"GLAUUIDValueTransformerName";
NSString *const GLADataBase64ValueTransformerName = @"GLADataBase64ValueTransformerName";


@implementation NSValueTransformer (GLAModel)

+ (void)load
{
	@autoreleasepool {
		MTLValueTransformer *UUIDValueTransformer = [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *UUIDString) {
			return [[NSUUID alloc] initWithUUIDString:UUIDString];
		} reverseBlock:^id(NSUUID *UUID) {
			return [UUID UUIDString];
		}];
		[NSValueTransformer setValueTransformer:UUIDValueTransformer forName:GLAUUIDValueTransformerName];
		
		
		MTLValueTransformer *dataBase64ValueTransformer = [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *base64String) {
			return [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
		} reverseBlock:^id(NSData *data) {
			return [data base64EncodedStringWithOptions:0];
		}];
		[NSValueTransformer setValueTransformer:dataBase64ValueTransformer forName:GLADataBase64ValueTransformerName];
	}
}

+ (instancetype)GLA_UUIDValueTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

+ (instancetype)GLA_DataBase64ValueTransformer
{
	return [NSValueTransformer valueTransformerForName:GLADataBase64ValueTransformerName];
}

@end
