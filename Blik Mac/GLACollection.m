//
//  GLAProjectItem.m
//  Blik
//
//  Created by Patrick Smith on 18/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLACollection.h"
#import "NSValueTransformer+GLAModel.h"
#import "GLACollectionColor.h"


@interface GLACollection ()

@property(readwrite, copy, nonatomic) NSUUID *projectUUID;

@property(readwrite, copy, nonatomic) NSString *name;

@property(readwrite, nonatomic) GLACollectionColor *color;
@property(readwrite, nonatomic) NSString *colorIdentifier;

@property(readwrite, copy, nonatomic) NSString *viewMode;

@end

@interface GLACollection (GLACollectionEditing) <GLACollectionEditing>

@end

@implementation GLACollection

+ (NSString *)objectJSONPasteboardType
{
	return @"com.burntcaramel.GLACollection.JSONPasteboardType";
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return
	@{
	  @"color": (NSNull.null),
	};
}

+ (NSValueTransformer *)projectUUIDJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:GLAUUIDValueTransformerName];
}

+ (NSValueTransformer *)viewModeJSONTransformer
{
	NSSet *allowedViewModes = [NSSet setWithObjects:GLACollectionViewModeList, GLACollectionViewModeExpanded, nil];
	
	return [MTLValueTransformer reversibleTransformerWithBlock:^ NSString *(NSString *inputViewMode) {
		if (inputViewMode && [allowedViewModes containsObject:inputViewMode]) {
			return inputViewMode;
		}
		else {
			return GLACollectionViewModeList;
		}
	}];
}

- (NSString *)colorIdentifier
{
	return (self.color.identifier);
}

- (void)setColorIdentifier:(NSString *)colorIdentifier
{
	(self.color) = [[GLACollectionColor alloc] initWithIdentifier:colorIdentifier];
}

- (instancetype)initWithType:(NSString *)collectionType creatingFromEditing:(void(^)(id<GLACollectionEditing> editor))editingBlock
{
	self = [super init];
	if (self) {
		_type = collectionType;
		editingBlock(self);
	}
	return self;
}

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLACollectionEditing>editor))collectionEditingBlock
{
	GLACollection *copy = [self copy];
	collectionEditingBlock(copy);
	
	return copy;
}

@end


@implementation GLACollection (GLADummyContent)

+ (instancetype)dummyCollectionWithName:(NSString *)name color:(GLACollectionColor *)color type:(NSString *)collectionType
{
	return [[self alloc] initWithType:collectionType creatingFromEditing:^(id<GLACollectionEditing> collectionEditor) {
		(collectionEditor.name) = name;
		(collectionEditor.color) = color;
	}];
}

@end


@implementation GLACollection (GLACollection_ProjectEditing)

@end


NSString *GLACollectionTypeFilesList = @"filesList";
NSString *GLACollectionTypeFilteredFolder = @"filteredFolder";

NSString *GLACollectionViewModeList = @"list";
NSString *GLACollectionViewModeExpanded = @"expanded";
