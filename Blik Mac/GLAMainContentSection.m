//
//  GLAMainContentSection.m
//  Blik
//
//  Created by Patrick Smith on 6/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
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

+ (instancetype)addNewProjectSectionWithPreviousSection:(GLAMainContentSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierAddNewProject previousSection:previousSection];
}

+ (instancetype)addNewCollectionSectionWithPreviousSection:(GLAMainContentSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierAddNewCollection previousSection:previousSection];
}

#pragma mark - JSON

+ (NSValueTransformer *)previousSectionJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLAMainContentSection class]];
}

@end


@implementation GLAMainContentEditProjectSection

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainContentSection *)previousSection project:(GLAProject *)project isNow:(BOOL)isNow
{
	self = [super initWithBaseIdentifier:baseIdentifier previousSection:previousSection];
	if (self) {
		_project = project;
		_isNow = isNow;
	}
	return self;
}

+ (instancetype)editProjectSectionWithProject:(GLAProject *)project previousSection:(GLAMainContentSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierEditProject previousSection:previousSection project:project isNow:NO];
}

+ (instancetype)nowProjectSectionWithProject:(GLAProject *)project
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierNow previousSection:nil project:project isNow:YES];
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


@implementation GLAMainContentAddNewCollectionSection

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainContentSection *)previousSection project:(GLAProject *)project
{
	self = [super initWithBaseIdentifier:baseIdentifier previousSection:previousSection];
	if (self) {
		_project = project;
	}
	return self;
}

+ (instancetype)addNewCollectionSectionToProject:(GLAProject *)project previousSection:(GLAMainContentSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierAddNewCollection previousSection:previousSection project:project];
}

#pragma mark JSON

+ (NSValueTransformer *)projectJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLAProject class]];
}

@end


@implementation GLAMainContentSection (ConvenienceCheckingIdentifier)

- (BOOL)hasBaseIdentifier:(NSString *)baseIdentifier
{
	return [(self.baseIdentifier) isEqualToString:baseIdentifier];
}

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

- (BOOL)isEditProject
{
	return [self hasBaseIdentifier:GLAMainContentSectionBaseIdentifierEditProject];
}

- (BOOL)isEditCollection
{
	return [self hasBaseIdentifier:GLAMainContentSectionBaseIdentifierEditCollection];
}

- (BOOL)isAddNewProject
{
	return [self hasBaseIdentifier:GLAMainContentSectionBaseIdentifierAddNewProject];
}

- (BOOL)isAddNewCollection
{
	return [self hasBaseIdentifier:GLAMainContentSectionBaseIdentifierAddNewCollection];
}

@end


NSString *GLAMainContentSectionBaseIdentifierAllProjects = @"allProjects";
NSString *GLAMainContentSectionBaseIdentifierPlannedProjects = @"plannedProjects";
NSString *GLAMainContentSectionBaseIdentifierNow = @"now";

NSString *GLAMainContentSectionBaseIdentifierEditProject = @"editProject";
NSString *GLAMainContentSectionBaseIdentifierEditCollection = @"editCollection";

NSString *GLAMainContentSectionBaseIdentifierAddNewProject = @"addNewProject";
NSString *GLAMainContentSectionBaseIdentifierAddNewCollection = @"addNewCollection";
