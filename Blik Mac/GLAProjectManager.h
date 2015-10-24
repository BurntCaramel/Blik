//
//  GLAProjectManager.h
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;
#import "GLAProject.h"
#import "GLACollection.h"
#import "GLAFolderQuery.h"
#import "GLAHighlightedItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface GLAProjectManager : NSObject

+ (instancetype)sharedProjectManager; // Works on the main queue

@property(readonly, nonatomic) NSOperationQueue *receivingOperationQueue; // Main queue by default

@property(nonatomic) BOOL shouldLoadTestProjects;

#pragma mark Status

- (NSString *)statusOfCurrentActivity;
- (NSString *)statusOfCompletedActivity;

#pragma mark Using Projects

#pragma mark Projects

- (void)loadAllProjectsIfNeeded;

// All of these may be nil until they are loaded.
// Use the notifications below to react to when they are ready.
- (NSArray *)copyAllProjects;
- (GLAProject * __nullable)projectWithUUID:(NSUUID *)projectUUID;

- (BOOL)editAllProjectsUsingBlock:(void (^)(id<GLAArrayEditing> allProjectsEditor))block;

- (id<GLALoadableArrayUsing>)useAllProjects;

- (GLAProject *)createNewProjectWithName:(NSString *)name;

- (GLAProject *)renameProject:(GLAProject *)project toName:(NSString *)name;
- (GLAProject *)setProject:(GLAProject *)project hidesFromLauncherMenu:(BOOL)hidesInLauncherMenu;

- (void)permanentlyDeleteProject:(GLAProject *)project;


#pragma mark Now Project

- (void)loadNowProjectIfNeeded;

@property(readonly, copy, nonatomic) GLAProject * _Nullable nowProject;

- (void)changeNowProject:(GLAProject * _Nullable)project;

#pragma mark Project Master Folders

- (id<GLALoadableArrayUsing>)usePrimaryFoldersForProject:(GLAProject *)project;

- (BOOL)hasLoadedPrimaryFoldersForProject:(GLAProject *)project;
- (void)loadPrimaryFoldersForProjectIfNeeded:(GLAProject *)project;
- (NSArray /* GLACollectedFile */ *)copyPrimaryFoldersForProject:(GLAProject *)project;

- (BOOL)editPrimaryFoldersOfProject:(GLAProject *)project usingBlock:(void (^)(id<GLAArrayEditing> collectedFoldersListEditor))block;

#pragma mark Collections

- (id<GLALoadableArrayUsing>)useCollectionsForProject:(GLAProject *)project;

- (BOOL)hasLoadedCollectionsForProject:(GLAProject *)project;
- (void)loadCollectionsForProjectIfNeeded:(GLAProject *)project;
- (NSArray *)copyCollectionsForProject:(GLAProject *)project;

- (GLACollection * __nullable)collectionWithUUID:(NSUUID *)collectionUUID inProjectWithUUID:(NSUUID *)projectUUID;

- (BOOL)editCollectionsOfProject:(GLAProject *)project usingBlock:(void (^)(id<GLAArrayEditing> collectionListEditor))block;

- (GLACollection *)createNewCollectionWithName:(NSString *)name type:(NSString *)type color:(GLACollectionColor *)color inProject:(GLAProject *)project insertingInCollectionsListAtIndex:(NSUInteger)indexInList;

- (GLACollection *)editCollection:(GLACollection *)collection inProject:(GLAProject *)project usingBlock:(void(^)(id<GLACollectionEditing>collectionEditor))editBlock;

- (GLACollection *)renameCollection:(GLACollection *)collection inProject:(GLAProject *)project toString:(NSString *)name;
- (GLACollection *)changeColorOfCollection:(GLACollection *)collection inProject:(GLAProject *)project toColor:(GLACollectionColor *)color;

- (void)permanentlyDeleteCollection:(GLACollection *)collection;

#pragma mark Highlights

- (id<GLALoadableArrayUsing>)useHighlightsForProject:(GLAProject *)project;

- (BOOL)hasLoadedHighlightsForProject:(GLAProject *)project;
- (void)loadHighlightsForProjectIfNeeded:(GLAProject *)project;

- (NSArray /* GLAHighlightedItem */ *)copyHighlightsForProject:(GLAProject *)project;

- (BOOL)highlightsOfProject:(GLAProject *)project containsCollectedFile:(GLACollectedFile *)collectedFile;
- (NSArray *)filterCollectedFiles:(NSArray *)collectedFiles notInHighlightsOfProject:(GLAProject *)project;

- (void)editHighlightsOfProjectWithUUID:(NSUUID *)projectUUID usingBlock:(void (^)(id<GLAArrayEditing> highlightsEditor))block;
- (void)editHighlightsOfProject:(GLAProject *)project usingBlock:(void (^)(id<GLAArrayEditing> highlightsEditor))block;

- (GLAHighlightedCollectedFile *)editHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile usingBlock:(void(^)(id<GLAHighlightedCollectedFileEditing>editor))editBlock;

#pragma mark Collection Files List

- (id<GLALoadableArrayUsing>)useFilesListForCollection:(GLACollection *)filesListCollection;

- (BOOL)hasLoadedFilesForCollection:(GLACollection *)filesListCollection;
- (void)loadFilesListForCollectionIfNeeded:(GLACollection *)filesListCollection;

- (NSArray *)copyFilesListForCollection:(GLACollection *)filesListCollection;

- (NSArray *)filterFileURLs:(NSArray *)fileURLs notInFilesListCollectionWithUUID:(NSUUID *)filesListCollectionUUID;

//- (BOOL)editFilesListOfCollectionWithUUID:(NSUUID *)filesListCollectionUUID inProjectWithUUID:(NSUUID *)projectUUID usingBlock:(void (^)(id<GLAArrayEditing> filesListEditor))block;
- (BOOL)editFilesListOfCollection:(GLACollection *)filesListCollection usingBlock:(void (^)(id<GLAArrayEditing> filesListEditor))block;
- (void)editFilesListOfCollection:(GLACollection *)filesListCollection insertingCollectedFiles:(NSArray *)collectedFiles atOptionalIndex:(NSUInteger)index;

- (void)editFilesListOfCollection:(GLACollection *)filesListCollection addingCollectedFiles:(NSArray *)collectedFiles queueIfNeedsLoading:(BOOL)queue;

#pragma mark Collection Filtered Folder

- (GLAFolderQuery *)folderQueryLoadingIfNeededForFilteredFolderCollectionWithUUID:(NSUUID *)collectionUUID; // Notifies with GLACollectionFolderQueryDidChangeNotification when loaded.
- (void)setFolderQuery:(GLAFolderQuery *)folderQuery forFilteredFolderCollectionWithUUID:(NSUUID *)collectionUUID;

#pragma mark Highlighted Collected File

- (GLACollection *)collectionForHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile loadIfNeeded:(BOOL)load;
- (GLACollectedFile *)collectedFileForHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile loadIfNeeded:(BOOL)load;

#pragma mark Validating

- (BOOL)nameIsValid:(NSString *)name;
- (NSString *)normalizeName:(NSString *)name;

#pragma mark Notifications

- (id)notificationObjectForProjectUUID:(NSUUID *)projectUUID;
- (id)notificationObjectForProject:(GLAProject *)project;
- (id)notificationObjectForCollectionUUID:(NSUUID *)collectionUUID;
- (id)notificationObjectForCollection:(GLACollection *)collection;

//- (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName project:(GLAProject *)project;

@end


//extern NSString *GLAProjectManagerChangeWasInitialLoadKey;

extern NSString *GLAProjectManagerAllProjectsDidChangeNotification;
extern NSString *GLAProjectManagerPlannedProjectsDidChangeNotification;
extern NSString *GLAProjectManagerNowProjectDidChangeNotification;

// Object is notificationObjectForProject: GLAProject
extern NSString *GLAProjectDidChangeNotification;
extern NSString *GLAProjectWasDeletedNotification;
extern NSString *GLAProjectPrimaryFoldersDidChangeNotification;
extern NSString *GLAProjectCollectionsDidChangeNotification;
extern NSString *GLAProjectHighlightsDidChangeNotification;
extern NSString *GLAProjectAnyCollectionFilesListDidChangeNotification; // Has GLANotificationUserInfoCollectionKey

// Object is notificationObjectForCollection: GLACollection
extern NSString *GLACollectionWasDeletedNotification;
extern NSString *GLACollectionDidChangeNotification;
extern NSString *GLACollectionFilesListDidChangeNotification;
extern NSString *GLACollectionFolderQueryDidChangeNotification;

// Keys
extern NSString *GLANotificationUserInfoCollectionKey;

//extern NSString *GLAProjectManagerProjectRemindersDidChangeNotification;

//extern NSString *GLAProjectManagerNotificationChangedPropertiesKey;

NS_ASSUME_NONNULL_END
