//
//  GLAMainSectionNavigator.h
//  Blik
//
//  Created by Patrick Smith on 11/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLAMainSection.h"
#import "GLAProject.h"
#import "GLAProjectManager.h"
#import "GLAPendingAddedCollectedFilesInfo.h"


@protocol GLAMainSectionNavigationStateReading <NSObject>

@property(readonly, nonatomic) GLAMainSection *currentSection;

@end

@interface GLAMainSectionNavigator : NSObject <GLAMainSectionNavigationStateReading>

- (instancetype)initWithProjectManager:(GLAProjectManager *)projectManager NS_DESIGNATED_INITIALIZER;

+ (instancetype)sharedMainSectionNavigator;

@property(nonatomic) GLAProjectManager *projectManager;

- (void)goToSection:(GLAMainSection *)newSection;
- (void)goToPreviousSection;
- (void)goToPreviousUnrelatedSection;

- (void)goToAllProjects;

- (void)goToNowProject;

- (void)goToProject:(GLAProject *)project;
- (void)editPrimaryFoldersOfProject:(GLAProject *)project;

- (void)addNewProject;

- (void)goToCollection:(GLACollection *)collection;
- (void)collectionMakeViewModeList;
- (void)collectionMakeViewModeExpanded;

- (void)addNewCollectionToProject:(GLAProject *)project;
- (void)addNewCollectionGoToCollectedFilesSection;
- (void)addNewCollectionGoToFilteredFolderSection;

- (void)addNewCollectedFilesCollectionToProject:(GLAProject *)project;
- (void)addNewCollectedFilesCollectionToProject:(GLAProject *)project pendingCollectedFilesInfo:(GLAPendingAddedCollectedFilesInfo *)pendingCollectedFilesInfo;
- (void)addNewCollectedFilesCollectionGoToChooseNameAndColor;

- (void)addNewFilteredFolderCollectionToProject:(GLAProject *)project;
- (void)addNewFilteredFolderCollectionGoToChooseNameAndColorWithChosenFolder:(NSURL *)folderURL chosenTagName:(NSString *)tagName;

@end


extern NSString *GLAMainSectionNavigatorDidChangeCurrentSectionNotification;
extern NSString *GLAMainSectionNavigatorNotificationUserInfoPreviousSection;
