//
//  GLAMainContentSection.h
//  Blik
//
//  Created by Patrick Smith on 6/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "Mantle/Mantle.h"
@class GLAProject;
@class GLACollection;
#import "GLAPendingAddedCollectedFilesInfo.h"


@interface GLAMainSection : MTLModel <MTLJSONSerializing>

//+ (instancetype)unknownSection;

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier secondaryIdentifier:(NSString *)secondaryIdentifier previousSection:(GLAMainSection *)previousSection NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainSection *)previousSection;
- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier;

@property(readonly, nonatomic) NSString *baseIdentifier;
@property(readonly, nonatomic) NSString *secondaryIdentifier;
@property(readonly, nonatomic) GLAMainSection *previousSection;
@property(readonly, nonatomic) GLAMainSection *previousUnrelatedSection;

//@property(nonatomic) id state;

#pragma mark -

+ (instancetype)allProjectsSection;
+ (instancetype)plannedProjectsSection;

+ (instancetype)addNewProjectSectionWithPreviousSection:(GLAMainSection *)previousSection;

@end


@interface GLAEditProjectSection : GLAMainSection

// Designated init:
- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainSection *)previousSection project:(GLAProject *)project isNow:(BOOL)isNow;

@property(readonly, nonatomic) GLAProject *project;
@property(readonly, nonatomic) BOOL isNow;

+ (instancetype)editProjectSectionWithProject:(GLAProject *)project previousSection:(GLAMainSection *)previousSection;

+ (instancetype)nowProjectSectionWithProject:(GLAProject *)project;

@end


@interface GLAEditProjectPrimaryFoldersSection : GLAEditProjectSection

+ (instancetype)editProjectPrimaryFoldersSectionWithProject:(GLAProject *)project previousSection:(GLAMainSection *)previousSection;

@end


@interface GLAEditCollectionSection : GLAMainSection

// Designated init:
- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainSection *)previousSection collection:(GLACollection *)collection viewMode:(NSString *)viewMode;

@property(readonly, nonatomic) GLACollection *collection;
@property(readonly, copy, nonatomic) NSString *viewMode;

+ (instancetype)editCollectionSectionWithCollection:(GLACollection *)collection viewMode:(NSString *)viewMode previousSection:(GLAMainSection *)previousSection;
+ (instancetype)editCollectionSectionWithCollection:(GLACollection *)collection previousSection:(GLAMainSection *)previousSection;

@end


@interface GLAAddNewCollectionSection : GLAMainSection

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier secondaryIdentifier:(NSString *)secondaryIdentifier previousSection:(GLAMainSection *)previousSection project:(GLAProject *)project NS_DESIGNATED_INITIALIZER;

@property(readonly, nonatomic) GLAProject *project;

+ (instancetype)addNewCollectionSectionToProject:(GLAProject *)project previousSection:(GLAMainSection *)previousSection;

@end

@interface GLAAddNewCollectedFilesCollectionSection : GLAAddNewCollectionSection

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier secondaryIdentifier:(NSString *)secondaryIdentifier previousSection:(GLAMainSection *)previousSection project:(GLAProject *)project pendingAddedCollectedFilesInfo:(GLAPendingAddedCollectedFilesInfo *)pendingAddedCollectedFilesInfo NS_DESIGNATED_INITIALIZER;

@property(readonly, nonatomic) GLAPendingAddedCollectedFilesInfo *pendingAddedCollectedFilesInfo;

+ (instancetype)addNewCollectionChooseNameAndColorSectionWithProject:(GLAProject *)project pendingAddedCollectedFilesInfo:(GLAPendingAddedCollectedFilesInfo *)pendingAddedCollectedFilesInfo previousSection:(GLAMainSection *)previousSection;

@end

@interface GLAAddNewFilteredFolderCollectionSection : GLAAddNewCollectionSection

@property(readonly, nonatomic) NSURL *chosenFolderURL;
@property(readonly, nonatomic) NSString *chosenTagName;

- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier secondaryIdentifier:(NSString *)secondaryIdentifier previousSection:(GLAMainSection *)previousSection project:(GLAProject *)project chosenFolderURL:(NSURL *)chosenFolderURL chosenTagName:(NSString *)chosenTagName NS_DESIGNATED_INITIALIZER;

+ (instancetype)addNewFilteredFolderCollectionChooseFolderSectionWithProject:(GLAProject *)project previousSection:(GLAMainSection *)previousSection;

+ (instancetype)addNewCollectionChooseNameAndColorSectionWithProject:(GLAProject *)project chosenFolderURL:(NSURL *)folderURL chosenTagName:(NSString *)tagName previousSection:(GLAMainSection *)previousSection;

@end


@interface GLAMainSection (ConvenienceCheckingIdentifier)

- (BOOL)hasBaseIdentifier:(NSString *)baseIdentifier;
- (BOOL)hasSecondaryIdentifier:(NSString *)secondaryIdentifier;

- (BOOL)isAllProjects;
- (BOOL)isPlannedProjects;

- (BOOL)isNow;
- (BOOL)isNowAndHasProject;

- (BOOL)isEditProject;
- (BOOL)isEditProjectPrimaryFolders;

- (BOOL)isEditCollection;

- (BOOL)isAddNewProject;

- (BOOL)isAddNewCollection;
- (BOOL)isAddNewCollectionChooseType;
- (BOOL)isAddNewCollectionChooseNameAndColor;
- (BOOL)isAddNewCollectionFilteredFolderChooseFilteredFolder;

@end


extern NSString *GLAMainContentSectionBaseIdentifierAllProjects;
extern NSString *GLAMainContentSectionBaseIdentifierPlannedProjects;
extern NSString *GLAMainContentSectionBaseIdentifierNow;

extern NSString *GLAMainContentSectionBaseIdentifierEditProject;
extern NSString *GLAMainContentSectionBaseIdentifierEditProjectPrimaryFolders;
extern NSString *GLAMainContentSectionBaseIdentifierEditCollection;

extern NSString *GLAMainContentSectionBaseIdentifierAddNewProject;

extern NSString *GLAMainContentSectionBaseIdentifierAddNewCollection;
extern NSString *GLAMainContentSectionAddNewCollectionSecondaryIdentifierChooseType;
extern NSString *GLAMainContentSectionAddNewCollectionSecondaryIdentifierChooseNameAndColor;
extern NSString *GLAMainContentSectionAddNewCollectionSecondaryIdentifierFilteredFolderChooseFolder;
