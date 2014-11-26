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
#import "GLAHighlightedItem.h"


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
- (GLAProject *)projectWithUUID:(NSUUID *)projectUUID;

- (BOOL)editAllProjectsUsingBlock:(void (^)(id<GLAArrayEditing> allProjectsEditor))block;

- (GLAProject *)createNewProjectWithName:(NSString *)name;

- (GLAProject *)renameProject:(GLAProject *)project toName:(NSString *)name;

- (void)permanentlyDeleteProject:(GLAProject *)project;


#pragma mark Now Project

- (void)loadNowProjectIfNeeded;

@property(readonly, copy, nonatomic) GLAProject *nowProject;

- (void)changeNowProject:(GLAProject *)project;

#pragma mark Collections

- (BOOL)hasLoadedCollectionsForProject:(GLAProject *)project;
- (void)loadCollectionsForProjectIfNeeded:(GLAProject *)project;
- (NSArray *)copyCollectionsForProject:(GLAProject *)project;

- (BOOL)editCollectionsOfProject:(GLAProject *)project usingBlock:(void (^)(id<GLAArrayEditing> collectionListEditor))block;

- (GLACollection *)createNewCollectionWithName:(NSString *)name type:(NSString *)type color:(GLACollectionColor *)color inProject:(GLAProject *)project;

- (GLACollection *)editCollection:(GLACollection *)collection inProject:(GLAProject *)project usingBlock:(void(^)(id<GLACollectionEditing>collectionEditor))editBlock;

- (GLACollection *)renameCollection:(GLACollection *)collection inProject:(GLAProject *)project toString:(NSString *)name;
- (GLACollection *)changeColorOfCollection:(GLACollection *)collection inProject:(GLAProject *)project toColor:(GLACollectionColor *)color;

- (void)permanentlyDeleteCollection:(GLACollection *)collection fromProject:(GLAProject *)project;

#pragma mark Highlights

- (BOOL)hasLoadedHighlightsForProject:(GLAProject *)project;
- (void)loadHighlightsForProjectIfNeeded:(GLAProject *)project;
- (NSArray /* GLAHighlightedItem */ *)copyHighlightsForProject:(GLAProject *)project;

- (BOOL)editHighlightsOfProject:(GLAProject *)project usingBlock:(void (^)(id<GLAArrayEditing> highlightsEditor))block;

- (GLAHighlightedCollectedFile *)editHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile usingBlock:(void(^)(id<GLAHighlightedCollectedFileEditing>editor))editBlock;

#pragma mark Collection Files List

- (BOOL)hasLoadedFilesForCollection:(GLACollection *)filesListCollection;
- (void)loadFilesListForCollectionIfNeeded:(GLACollection *)filesListCollection;
- (NSArray *)copyFilesListForCollection:(GLACollection *)filesListCollection;
- (GLACollectedFile *)collectedFileWithUUID:(NSUUID *)collectionUUID insideCollection:(GLACollection *)filesListCollection;

- (BOOL)editFilesListOfCollection:(GLACollection *)filesListCollection usingBlock:(void (^)(id<GLAArrayEditing> filesListEditor))block;

#pragma mark Highlighted Collected File

- (GLACollection *)collectionForHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile loadIfNeeded:(BOOL)load;
- (GLACollectedFile *)collectedFileForHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile loadIfNeeded:(BOOL)load;

#pragma mark Validating

- (BOOL)nameIsValid:(NSString *)name;
- (NSString *)normalizeName:(NSString *)name;

#pragma mark Saving

- (void)requestSaveAllProjects;
- (void)requestSaveCollectionsForProject:(GLAProject *)project;
- (void)requestSaveFilesListForCollections:(GLACollection *)filesListCollection;

#pragma mark Notifications

- (id)notificationObjectForProject:(GLAProject *)project;
- (id)notificationObjectForProjectUUID:(NSUUID *)projectUUID;
- (id)notificationObjectForCollection:(GLACollection *)collection;
- (id)notificationObjectForCollectionUUID:(NSUUID *)collectionUUID;

//- (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName project:(GLAProject *)project;

@end


//extern NSString *GLAProjectManagerChangeWasInitialLoadKey;

extern NSString *GLAProjectManagerAllProjectsDidChangeNotification;
extern NSString *GLAProjectManagerPlannedProjectsDidChangeNotification;
extern NSString *GLAProjectManagerNowProjectDidChangeNotification;

// Object is notificationObjectForProject: GLAProject
extern NSString *GLAProjectDidChangeNotification;
extern NSString *GLAProjectCollectionsDidChangeNotification;
extern NSString *GLAProjectHighlightsDidChangeNotification;

// Object is notificationObjectForCollection: GLACollection
extern NSString *GLACollectionDidChangeNotification;
extern NSString *GLACollectionFilesListDidChangeNotification;

//extern NSString *GLAProjectManagerProjectRemindersDidChangeNotification;

//extern NSString *GLAProjectManagerNotificationChangedPropertiesKey;
