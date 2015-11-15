//
//  GLAProject.m
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAProject.h"
#import "GLAArrayEditor.h"
#import "NSValueTransformer+GLAModel.h"


@interface GLAProject ()

@property(readwrite, copy, nonatomic) NSString *name;
@property(readwrite, nonatomic) NSDate *dateCreated;

@property(readwrite, nonatomic) BOOL hideFromLauncherMenu;
@property(readwrite, nonatomic) BOOL groupHighlights;

@end

@interface GLAProject (GLAProjectEditing) <GLAProjectEditing>

@end

@implementation GLAProject

+ (NSString *)objectJSONPasteboardType
{
	return @"com.burntcaramel.GLAProject.JSONPasteboardType";
}

+ (NSValueTransformer *)dateCreatedJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLADateRFC3339ValueTransformerName];
}

- (instancetype)initWithName:(NSString *)name dateCreated:(NSDate *)dateCreated groupHighlights:(BOOL)groupHighlights
{
	self = [super init];
	if (self) {
		if (!dateCreated) {
			dateCreated = [NSDate date];
		}
		
		_name = name;
		_dateCreated = dateCreated;
		_groupHighlights = groupHighlights;
	}
	return self;
}

- (instancetype)init
{
	return [self initWithName:nil dateCreated:nil groupHighlights:NO];
}

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAProjectEditing> editor))editingBlock
{
	GLAProject *copy = [self copy];
	editingBlock(copy);
	
	return copy;
}

@end
