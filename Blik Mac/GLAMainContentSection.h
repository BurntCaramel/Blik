//
//  GLAMainContentSection.h
//  Blik
//
//  Created by Patrick Smith on 6/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "Mantle/Mantle.h"
@class GLAProject;
@class GLACollection;


@interface GLAMainContentSection : MTLModel <MTLJSONSerializing>

//+ (instancetype)unknownSection;

// Designated init:
- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainContentSection *)previousSection;
- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier;

@property(readonly, nonatomic) NSString *baseIdentifier;
@property(readonly, nonatomic) GLAMainContentSection *previousSection;

#pragma mark -

+ (instancetype)allProjectsSection;
+ (instancetype)plannedProjectsSection;
+ (instancetype)nowSection;

+ (instancetype)addNewProjectSectionWithPreviousSection:(GLAMainContentSection *)previousSection;

+ (instancetype)addNewCollectionSectionWithPreviousSection:(GLAMainContentSection *)previousSection;

@end


@interface GLAMainContentEditProjectSection : GLAMainContentSection

// Designated init:
- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainContentSection *)previousSection project:(GLAProject *)project;

@property(readonly, nonatomic) GLAProject *project;

+ (instancetype)editProjectSectionWithProject:(GLAProject *)project previousSection:(GLAMainContentSection *)previousSection;

@end


@interface GLAMainContentEditCollectionSection : GLAMainContentSection

// Designated init:
- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainContentSection *)previousSection collection:(GLACollection *)collection;

@property(readonly, nonatomic) GLACollection *collection;

+ (instancetype)editCollectionSectionWithCollection:(GLACollection *)collection previousSection:(GLAMainContentSection *)previousSection;

@end


@interface GLAMainContentAddNewCollectionSection : GLAMainContentSection

// Designated init:
- (instancetype)initWithBaseIdentifier:(NSString *)baseIdentifier previousSection:(GLAMainContentSection *)previousSection project:(GLAProject *)project;

@property(readonly, nonatomic) GLAProject *project;

+ (instancetype)addNewCollectionSectionToProject:(GLAProject *)project previousSection:(GLAMainContentSection *)previousSection;

@end


@interface GLAMainContentSection (ConvenienceCheckingIdentifier)

- (BOOL)hasBaseIdentifier:(NSString *)baseIdentifier;

- (BOOL)isAllProjects;
- (BOOL)isPlannedProjects;
- (BOOL)isNow;

- (BOOL)isEditProject;
- (BOOL)isEditCollection;

- (BOOL)isAddNewProject;
- (BOOL)isAddNewCollection;

@end


extern NSString *GLAMainContentSectionBaseIdentifierAllProjects;
extern NSString *GLAMainContentSectionBaseIdentifierPlannedProjects;
extern NSString *GLAMainContentSectionBaseIdentifierNow;

extern NSString *GLAMainContentSectionBaseIdentifierEditProject;
extern NSString *GLAMainContentSectionBaseIdentifierEditCollection;

extern NSString *GLAMainContentSectionBaseIdentifierAddNewProject;
extern NSString *GLAMainContentSectionBaseIdentifierAddNewCollection;
