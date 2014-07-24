//
//  NSValueTransformer+GLAModel.m
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "NSValueTransformer+GLAModel.h"


NSString * const GLAUUIDValueTransformerName = @"GLAUUIDValueTransformerName";


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
	}
}

+ (instancetype)GLA_UUIDValueTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

@end
