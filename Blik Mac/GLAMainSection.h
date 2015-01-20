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

// Designated init:
- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainSection *)previousSection;
- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier;

@property(readonly, nonatomic) NSString *baseIdentifier;
@property(readonly, nonatomic) GLAMainSection *previousSection;

#pragma mark -

+ (instancetype)allProjectsSection;
+ (instancetype)plannedProjectsSection;

+ (instancetype)addNewProjectSectionWithPreviousSection:(GLAMainSection *)previousSection;

+ (instancetype)addNewCollectionSectionWithPreviousSection:(GLAMainSection *)previousSection;

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
- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainSection *)previousSection collection:(GLACollection *)collection;

@property(readonly, nonatomic) GLACollection *collection;

+ (instancetype)editCollectionSectionWithCollection:(GLACollection *)collection previousSection:(GLAMainSection *)previousSection;

@end


@interface GLAAddNewCollectionSection : GLAMainSection

// Designated init:
- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier pendingAddedCollectedFilesInfo:(GLAPendingAddedCollectedFilesInfo *)pendingAddedCollectedFilesInfo previousSection:(GLAMainSection *)previousSection project:(GLAProject *)project;

@property(readonly, nonatomic) GLAProject *project;
@property(readonly, nonatomic) GLAPendingAddedCollectedFilesInfo *pendingAddedCollectedFilesInfo;

+ (instancetype)addNewCollectionSectionToProject:(GLAProject *)project previousSection:(GLAMainSection *)previousSection;
+ (instancetype)addNewCollectionSectionToProject:(GLAProject *)project pendingAddedCollectedFilesInfo:(GLAPendingAddedCollectedFilesInfo *)pendingAddedCollectedFilesInfo previousSection:(GLAMainSection *)previousSection;

@end


@interface GLAMainSection (ConvenienceCheckingIdentifier)

- (BOOL)hasBaseIdentifier:(NSString *)baseIdentifier;

- (BOOL)isAllProjects;
- (BOOL)isPlannedProjects;

- (BOOL)isNow;
- (BOOL)isNowAndHasProject;

- (BOOL)isEditProject;
- (BOOL)isEditProjectPrimaryFolders;

- (BOOL)isEditCollection;

- (BOOL)isAddNewProject;
- (BOOL)isAddNewCollection;

@end


extern NSString *GLAMainContentSectionBaseIdentifierAllProjects;
extern NSString *GLAMainContentSectionBaseIdentifierPlannedProjects;
extern NSString *GLAMainContentSectionBaseIdentifierNow;

extern NSString *GLAMainContentSectionBaseIdentifierEditProject;
extern NSString *GLAMainContentSectionBaseIdentifierEditProjectPrimaryFolders;
extern NSString *GLAMainContentSectionBaseIdentifierEditCollection;

extern NSString *GLAMainContentSectionBaseIdentifierAddNewProject;
extern NSString *GLAMainContentSectionBaseIdentifierAddNewCollection;
