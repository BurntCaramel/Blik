//
//  GLAProject.m
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAProject.h"
#import "GLAArrayEditor.h"
#import "NSValueTransformer+GLAModel.h"


@interface GLAProject () <GLAProjectEditing>

@property(readwrite, nonatomic) NSUUID *UUID;
@property(readwrite, copy, nonatomic) NSString *name;
@property(readwrite, nonatomic) NSDate *dateCreated;

@end

@implementation GLAProject

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return
	@{
	  @"UUID": @"UUID",
	  @"name": @"name",
	  @"dateCreated": @"dateCreated"
	  };
}

+ (NSValueTransformer *)UUIDJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

+ (NSValueTransformer *)dateCreatedJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLADateRFC3339ValueTransformerName];
}

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name dateCreated:(NSDate *)dateCreated
{
	self = [super init];
	if (self) {
		if (!UUID) {
			UUID = [NSUUID UUID];
		}
		
		if (!dateCreated) {
			dateCreated = [NSDate date];
		}
		
		_UUID = UUID;
		_name = name;
		_dateCreated = dateCreated;
	}
	return self;
}

- (instancetype)init
{
	return [self initWithUUID:nil name:nil dateCreated:nil];
}

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAProjectEditing> editor))editingBlock
{
	GLAProject *copy = [self copy];
	editingBlock(copy);
	
	return copy;
}

@end
