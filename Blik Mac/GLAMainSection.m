//
//  GLAMainContentSection.m
//  Blik
//
//  Created by Patrick Smith on 6/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAMainSection.h"
#import "GLAProject.h"


@implementation GLAMainSection

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return @{};
}

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier secondaryIdentifier:(NSString *)secondaryIdentifier previousSection:(GLAMainSection *)previousSection
{
	self = [super init];
	if (self) {
		_baseIdentifier = [baseIdentifier copy];
		_secondaryIdentifier = [secondaryIdentifier copy];
		_previousSection = previousSection;
	}
	return self;
}

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainSection *)previousSection;
{
	return [self initWithBaseIdentifier:baseIdentifier secondaryIdentifier:nil previousSection:previousSection];
}

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier
{
	return [self initWithBaseIdentifier:baseIdentifier previousSection:nil];
}

- (GLAMainSection *)previousUnrelatedSection
{
	return (self.previousSection);
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

+ (instancetype)addNewProjectSectionWithPreviousSection:(GLAMainSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierAddNewProject previousSection:previousSection];
}

#pragma mark - JSON

+ (NSValueTransformer *)previousSectionJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLAMainSection class]];
}

@end


@implementation GLAEditProjectSection

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainSection *)previousSection project:(GLAProject *)project isNow:(BOOL)isNow
{
	self = [super initWithBaseIdentifier:baseIdentifier previousSection:previousSection];
	if (self) {
		_project = project;
		_isNow = isNow;
	}
	return self;
}

+ (instancetype)editProjectSectionWithProject:(GLAProject *)project previousSection:(GLAMainSection *)previousSection isCurrentlyNow:(BOOL)isNow
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierEditProject previousSection:previousSection project:project isNow:isNow];
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


@implementation GLAEditProjectPrimaryFoldersSection

+ (instancetype)editProjectPrimaryFoldersSectionWithProject:(GLAProject *)project previousSection:(GLAMainSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierEditProjectPrimaryFolders previousSection:previousSection project:project isNow:NO];
}

@end


#pragma mark -


@implementation GLAEditCollectionSection

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainSection *)previousSection collection:(GLACollection *)collection viewMode:(NSString *)viewMode
{
	self = [super initWithBaseIdentifier:baseIdentifier previousSection:previousSection];
	if (self) {
		_collection = collection;
		_viewMode = [viewMode copy];
	}
	return self;
}

+ (instancetype)editCollectionSectionWithCollection:(GLACollection *)collection viewMode:(NSString *)viewMode previousSection:(GLAMainSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierEditCollection previousSection:previousSection collection:collection viewMode:viewMode];
}

+ (instancetype)editCollectionSectionWithCollection:(GLACollection *)collection previousSection:(GLAMainSection *)previousSection
{
	return [self editCollectionSectionWithCollection:collection viewMode:(collection.viewMode) previousSection:previousSection];
}

#pragma mark JSON

+ (NSValueTransformer *)previousSectionJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLAEditProjectSection class]];
}

+ (NSValueTransformer *)collectionJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLACollection class]];
}

@end


@implementation GLAAddNewCollectionSection

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier secondaryIdentifier:(NSString *)secondaryIdentifier previousSection:(GLAMainSection *)previousSection project:(GLAProject *)project
{
	self = [super initWithBaseIdentifier:baseIdentifier secondaryIdentifier:secondaryIdentifier previousSection:previousSection];
	if (self) {
		_project = project;
	}
	return self;
}

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier secondaryIdentifier:(NSString *)secondaryIdentifier previousSection:(GLAMainSection *)previousSection __unavailable
{
	return nil;
}

+ (instancetype)addNewCollectionSectionToProject:(GLAProject *)project previousSection:(GLAMainSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierAddNewCollection secondaryIdentifier:GLAMainContentSectionAddNewCollectionSecondaryIdentifierChooseType previousSection:previousSection project:project];
}

#pragma mark -

- (GLAMainSection *)previousUnrelatedSection
{
	GLAMainSection *previousSection = (self.previousSection);
	while (previousSection && (previousSection.isAddNewCollection)) {
		previousSection = (previousSection.previousSection);
	}
	
	return previousSection;
}

#pragma mark JSON

+ (NSValueTransformer *)projectJSONTransformer
{
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[GLAProject class]];
}

@end

@implementation GLAAddNewCollectedFilesCollectionSection

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier secondaryIdentifier:(NSString *)secondaryIdentifier previousSection:(GLAMainSection *)previousSection project:(GLAProject *)project pendingAddedCollectedFilesInfo:(GLAPendingAddedCollectedFilesInfo *)pendingAddedCollectedFilesInfo;
{
	self = [super initWithBaseIdentifier:baseIdentifier secondaryIdentifier:secondaryIdentifier previousSection:previousSection project:project];
	if (self) {
		_pendingAddedCollectedFilesInfo = pendingAddedCollectedFilesInfo;
	}
	return self;
}

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier secondaryIdentifier:(NSString *)secondaryIdentifier previousSection:(GLAMainSection *)previousSection project:(GLAProject *)project __unavailable
{
	return nil;
}

+ (instancetype)addNewCollectionChooseNameAndColorSectionWithProject:(GLAProject *)project pendingAddedCollectedFilesInfo:(GLAPendingAddedCollectedFilesInfo *)pendingAddedCollectedFilesInfo previousSection:(GLAMainSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierAddNewCollection secondaryIdentifier:GLAMainContentSectionAddNewCollectionSecondaryIdentifierChooseNameAndColor previousSection:previousSection project:project pendingAddedCollectedFilesInfo:pendingAddedCollectedFilesInfo];
}

@end

@implementation GLAAddNewFilteredFolderCollectionSection

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier secondaryIdentifier:(NSString *)secondaryIdentifier previousSection:(GLAMainSection *)previousSection project:(GLAProject *)project chosenFolderURL:(NSURL *)chosenFolderURL chosenTagName:(NSString *)chosenTagName
{
	self = [super initWithBaseIdentifier:baseIdentifier secondaryIdentifier:secondaryIdentifier previousSection:previousSection project:project];
	if (self) {
		_chosenFolderURL = chosenFolderURL;
		_chosenTagName = [chosenTagName copy];
	}
	return self;
}

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier secondaryIdentifier:(NSString *)secondaryIdentifier previousSection:(GLAMainSection *)previousSection project:(GLAProject *)project __unavailable
{
	return nil;
}

+ (instancetype)addNewFilteredFolderCollectionChooseFolderSectionWithProject:(GLAProject *)project previousSection:(GLAMainSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierAddNewCollection secondaryIdentifier:GLAMainContentSectionAddNewCollectionSecondaryIdentifierFilteredFolderChooseFolder previousSection:previousSection project:project chosenFolderURL:nil chosenTagName:nil];
}

+ (instancetype)addNewCollectionChooseNameAndColorSectionWithProject:(GLAProject *)project chosenFolderURL:(NSURL *)folderURL chosenTagName:(NSString *)tagName previousSection:(GLAMainSection *)previousSection
{
	return [[self alloc] initWithBaseIdentifier:GLAMainContentSectionBaseIdentifierAddNewCollection secondaryIdentifier:GLAMainContentSectionAddNewCollectionSecondaryIdentifierChooseNameAndColor previousSection:previousSection project:project chosenFolderURL:folderURL chosenTagName:tagName];
}

@end


@implementation GLAMainSection (ConvenienceCheckingIdentifier)

- (BOOL)hasBaseIdentifier:(NSString *)baseIdentifier
{
	return [(self.baseIdentifier) isEqualToString:baseIdentifier];
}

- (BOOL)hasSecondaryIdentifier:(NSString *)secondaryIdentifier
{
	return [(self.secondaryIdentifier) isEqualToString:secondaryIdentifier];
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

- (BOOL)isNowAndHasProject
{
	if (!(self.isNow)) {
		return NO;
	}
	
	GLAEditProjectSection *editProjectSection = (id)(self);
	return (editProjectSection.project) != nil;
}

- (BOOL)isEditProject
{
	return [self hasBaseIdentifier:GLAMainContentSectionBaseIdentifierEditProject];
}

- (BOOL)isEditProjectPrimaryFolders
{
	return [self hasBaseIdentifier:GLAMainContentSectionBaseIdentifierEditProjectPrimaryFolders];
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

- (BOOL)isAddNewCollectionChooseType
{
	return [self hasSecondaryIdentifier:GLAMainContentSectionAddNewCollectionSecondaryIdentifierChooseType];
}

- (BOOL)isAddNewCollectionChooseNameAndColor
{
	return [self hasSecondaryIdentifier:GLAMainContentSectionAddNewCollectionSecondaryIdentifierChooseNameAndColor];
}

- (BOOL)isAddNewCollectionFilteredFolderChooseFilteredFolder
{
	return [self hasSecondaryIdentifier:GLAMainContentSectionAddNewCollectionSecondaryIdentifierFilteredFolderChooseFolder];
}
@end


NSString *GLAMainContentSectionBaseIdentifierAllProjects = @"allProjects";
NSString *GLAMainContentSectionBaseIdentifierPlannedProjects = @"plannedProjects";
NSString *GLAMainContentSectionBaseIdentifierNow = @"now";

NSString *GLAMainContentSectionBaseIdentifierEditProject = @"editProject";
NSString *GLAMainContentSectionBaseIdentifierEditProjectPrimaryFolders = @"editProject.primaryFolders";
NSString *GLAMainContentSectionBaseIdentifierEditCollection = @"editCollection";

NSString *GLAMainContentSectionBaseIdentifierAddNewProject = @"addNewProject";

NSString *GLAMainContentSectionBaseIdentifierAddNewCollection = @"addNewCollection";
NSString *GLAMainContentSectionAddNewCollectionSecondaryIdentifierChooseType = @"addNewCollection.chooseType";
NSString *GLAMainContentSectionAddNewCollectionSecondaryIdentifierChooseNameAndColor = @"addNewCollection.chooseNameAndColor";
NSString *GLAMainContentSectionAddNewCollectionSecondaryIdentifierFilteredFolderChooseFolder = @"addNewCollection.filteredFolder.chooseFolder";
