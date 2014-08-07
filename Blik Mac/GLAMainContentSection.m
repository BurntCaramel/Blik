//
//  GLAMainContentSection.m
//  Blik
//
//  Created by Patrick Smith on 6/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAMainContentSection.h"
#import "GLAProject.h"


@implementation GLAMainContentSection

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainContentSection *)previousSection;
{
	self = [super init];
	if (self) {
		_baseIdentifier = baseIdentifier;
		_previousSection = previousSection;
	}
	return self;
}

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier
{
	return [self initWithBaseIdentifier:baseIdentifier previousSection:nil];
}

- (BOOL)hasBaseIdentifier:(NSString *)baseIdentifier
{
	return [(self.baseIdentifier) isEqualToString:baseIdentifier];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p %@; %@>", (self.class), self, (self.baseIdentifier), (self.previousSection)];
}

#pragma mark -

+ (instancetype)allProjectsSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierAllProjects];
}

+ (instancetype)plannedProjectsSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierPlannedProjects];
}

+ (instancetype)nowSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierNow];
}

+ (instancetype)addNewProjectSectionWithPreviousSection:(GLAMainContentSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierAddNewProject previousSection:previousSection];
}

#pragma mark - JSON

+ (NSValueTransformer *)previousSectionJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLAMainContentSection class]];
}

@end


@implementation GLAMainContentEditProjectSection

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainContentSection *)previousSection project:(GLAProject *)project
{
	self = [super initWithBaseIdentifier:baseIdentifier previousSection:previousSection];
	if (self) {
		_project = project;
	}
	return self;
}

+ (instancetype)editProjectSectionWithProject:(GLAProject *)project previousSection:(GLAMainContentSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierEditProject previousSection:previousSection project:project];
}

#pragma mark JSON

+ (NSValueTransformer *)projectJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLAProject class]];
}

@end


@implementation GLAMainContentEditCollectionSection

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainContentSection *)previousSection collection:(GLACollection *)collection
{
	self = [super initWithBaseIdentifier:baseIdentifier previousSection:previousSection];
	if (self) {
		_collection = collection;
	}
	return self;
}

+ (instancetype)editCollectionSectionWithCollection:(GLACollection *)collection previousSection:(GLAMainContentSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierEditCollection previousSection:previousSection collection:collection];
}

#pragma mark JSON

+ (NSValueTransformer *)previousSectionJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLAMainContentEditProjectSection class]];
}

+ (NSValueTransformer *)collectionJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLACollection class]];
}

@end


@implementation GLAMainContentSection (ConvenienceCheckingIdentifier)

- (BOOL)isAllProjects
{
	return [self hasBaseIdentifier:GLAMainContentSectionBaseIdentifierAllProjects];
}

- (BOOL)isPlannedProjects
{
	return [self hasBaseIdentifier:GLAMainContentSectionBaseIdentifierPlannedProjects];
}

- (BOOL)isNow
{
	return [self hasBaseIdentifier:GLAMainContentSectionBaseIdentifierNow];
}

- (BOOL)isAddNewProject
{
	return [self hasBaseIdentifier:GLAMainContentSectionBaseIdentifierAddNewProject];
}

- (BOOL)isEditProject
{
	return [self hasBaseIdentifier:GLAMainContentSectionBaseIdentifierEditProject];
}

- (BOOL)isEditCollection
{
	return [self hasBaseIdentifier:GLAMainContentSectionBaseIdentifierEditCollection];
}

@end


NSString *GLAMainContentSectionBaseIdentifierAllProjects = @"allProjects";
NSString *GLAMainContentSectionBaseIdentifierPlannedProjects = @"plannedProjects";
NSString *GLAMainContentSectionBaseIdentifierNow = @"now";
NSString *GLAMainContentSectionBaseIdentifierAddNewProject = @"addNewProject";
NSString *GLAMainContentSectionBaseIdentifierEditProject = @"editProject";
NSString *GLAMainContentSectionBaseIdentifierEditCollection = @"editCollection";
