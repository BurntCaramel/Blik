//
//  GLAProjectManager.m
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAProjectManager.h"
#import "Mantle/Mantle.h"
#import "GLAModelErrors.h"
#import "GLACollection.h"
#import "GLACollectionColor.h"
#import "GLACollectedFile.h"
#import "GLAArrayEditor.h"
#import "GLAArrayEditorStore.h"
#import "GLAObjectNotificationRepresenter.h"
#import "GLAModelUUIDMap.h"

@class GLAProjectManagerStore;


@interface GLAProjectManagerStoreState : NSObject

@property(nonatomic) NSArray *allProjectsSortedByDateCreatedNewestToOldest;
@property(nonatomic) NSDictionary *allProjectUUIDsToProjects;

@property(nonatomic) NSUUID *nowProjectUUID;

@property(nonatomic) GLAProject *nowProject;

@end


@interface GLAProjectManagerStore : NSObject

- (instancetype)initWithProjectManager:(GLAProjectManager *)projectManager;

@property(weak, nonatomic) GLAProjectManager *projectManager;

@property(readonly, nonatomic) NSURL *version1DirectoryURL;

- (NSString *)statusOfCurrentActivity;
- (NSString *)statusOfCompletedActivity;

#pragma mark All Projects

- (void)requestAllProjects;
@property(readonly, copy, nonatomic) NSArray *allProjectsSortedByDateCreatedNewestToOldest;

- (GLAProject *)projectWithUUID:(NSUUID *)projectUUID;

//- (NSSet *)loadedProjectUUIDsContainingCollection:(GLACollection *)collection;

- (void)addProjects:(NSArray *)projects;
- (void)permanentlyDeleteProject:(GLAProject *)project;

- (GLAProject *)editProject:(GLAProject *)project usingBlock:(void(^)(id<GLAProjectEditing>projectEditor))editBlock;

- (void)requestSaveAllProjects;

#pragma mark Now Project

- (void)requestNowProject;
@property(readonly, copy, nonatomic) GLAProject *nowProject;

- (void)changeNowProject:(GLAProject *)project;
- (void)requestSaveNowProject;

#pragma mark Collections

- (void)requestCollectionsForProject:(GLAProject *)project;
- (GLAArrayEditorStore *)collectionsEditorStoreForProject:(GLAProject *)project;
- (NSArray *)copyCollectionsForProject:(GLAProject *)project;
- (GLACollection *)collectionWithUUID:(NSUUID *)collectionUUID;

- (void)requestSaveCollectionsForProject:(GLAProject *)project;

#pragma mark Collection Files List

- (BOOL)hasLoadedFilesForCollection:(GLACollection *)filesListCollection;
- (void)requestFilesListForCollection:(GLACollection *)filesListCollection;

- (GLAArrayEditorStore *)filesListEditorStoreForCollection:(GLACollection *)filesListCollection;

- (NSArray *)copyFilesListForCollection:(GLACollection *)filesListCollection;
- (GLACollectedFile *)collectedFileWithUUID:(NSUUID *)collectionUUID insideCollection:(GLACollection *)filesListCollection;

- (void)requestSaveFilesListForCollection:(GLACollection *)filesListCollection;

#pragma mark Highlights

- (void)loadHighlightsForProjectIfNeeded:(GLAProject *)project;
- (GLAArrayEditorStore *)highlightsEditorStoreForProject:(GLAProject *)project;
- (NSArray /*id<GLACollectedItem>*/ *)copyHighlightsForProject:(GLAProject *)project;

#pragma mark Saving

//- (void)requestSavePlannedProjects;

- (void)permanentlyDeleteAssociatedFilesForProjects:(NSArray *)projects;
- (void)permanentlyDeleteAssociatedFilesForCollections:(NSArray *)collections;

@end


NSString *GLAProjectManagerJSONAllProjectsKey = @"allProjects";
NSString *GLAProjectManagerJSONNowProjectKey = @"nowProject";
NSString *GLAProjectManagerJSONCollectionsListKey = @"collectionsList";
NSString *GLAProjectManagerJSONHighlightsListKey = @"highlightsList";
NSString *GLAProjectManagerJSONFilesListKey = @"filesList";


@interface GLAProjectManager ()

@property(nonatomic) GLAProjectManagerStore *store;

@property(nonatomic) NSMutableDictionary *projectUUIDNotificationRepresenters;
@property(nonatomic) NSMutableDictionary *collectionUUIDNotificationRepresenters;

//@property(nonatomic) NSArray *allProjects;
//@property(nonatomic) NSArray *plannedProjects;

//@property(nonatomic) GLAProject *nowProject;


#pragma mark Saving and Loading

- (void)loadAllProjects;
- (void)saveAllProjects;

- (void)allProjectsDidChange;
- (void)plannedProjectsDidChange;
- (void)nowProjectDidChange;

- (void)collectionListForProjectDidChange:(GLAProject *)project;
- (void)highlightsListForProjectDidChange:(GLAProject *)project;

//- (void)connectCollections:(NSArray *)collections withProjects:(NSArray *)projects;
//- (void)connectReminders:(NSArray *)collections withProjects:(NSArray *)projects;

//- (void)scheduleSavingProjects;
//- (void)processProjectsNeedingSaving;

@end

#pragma mark -

@implementation GLAProjectManager

- (instancetype)init
{
    self = [super init];
    if (self) {
		_store = [[GLAProjectManagerStore alloc] initWithProjectManager:self];
    }
    return self;
}

+ (instancetype)sharedProjectManager
{
	static GLAProjectManager *sharedProjectManager;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedProjectManager = [GLAProjectManager new];
	});
	
	return sharedProjectManager;
}

#pragma mark -

- (NSOperationQueue *)receivingOperationQueue
{
	return [NSOperationQueue mainQueue];
}

- (void)handleError:(NSError *)error
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		NSLog(@"ERROR %@", error);
		// TODO something a bit more elegant?
		//[NSApp presentError:error];
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}];
}

#pragma mark Using Projects

- (void)loadAllProjects
{
	if (self.allProjectsSortedByDateCreatedNewestToOldest) {
		return;
	}
	
	[(self.store) requestAllProjects];
}

- (NSArray *)allProjectsSortedByDateCreatedNewestToOldest
{
	return (self.store.allProjectsSortedByDateCreatedNewestToOldest);
}

- (GLAProject *)projectWithUUID:(NSUUID *)projectUUID
{
	NSAssert(projectUUID != nil, @"Project UUID must not be nil.");
	return [(self.store) projectWithUUID:projectUUID];
}

- (void)loadNowProject
{
	if (self.nowProject) {
		return;
	}
	
	[(self.store) requestNowProject];
}

- (GLAProject *)nowProject
{
	return (self.store.nowProject);
}

#pragma mark Editing

- (void)changeNowProject:(GLAProject *)project
{
	GLAProjectManagerStore *store = (self.store);
	
	[store changeNowProject:project];
	[self nowProjectDidChange];
	
	[store requestSaveNowProject];
}

- (GLAProject *)createNewProjectWithName:(NSString *)name
{
	GLAProject *project = [[GLAProject alloc] initWithName:name dateCreated:nil];
	
	GLAProjectManagerStore *store = (self.store);
	[store addProjects:@[project]];
	
	//[store requestSaveAllProjects];
	
	return project;
}

- (GLAProject *)renameProject:(GLAProject *)project toName:(NSString *)name
{
	return [(self.store) editProject:project usingBlock:^(id<GLAProjectEditing> projectEditor) {
		(projectEditor.name) = name;
	}];
}

#pragma mark Collections

- (void)loadCollectionsForProjectIfNeeded:(GLAProject *)project
{
	NSAssert(project != nil, @"Project must not be nil.");
	[(self.store) requestCollectionsForProject:project];
}

- (NSArray *)copyCollectionsForProject:(GLAProject *)project
{
	return [(self.store) copyCollectionsForProject:project];
}

- (GLACollection *)collectionWithUUID:(NSUUID *)collectionUUID
{
	NSAssert(collectionUUID != nil, @"Collection UUID must not be nil.");
	return [(self.store) collectionWithUUID:collectionUUID];
}

- (BOOL)editCollectionsOfProject:(GLAProject *)project usingBlock:(void (^)(id<GLAArrayEditing> collectionsEditor))block
{
	GLAProjectManagerStore *store = (self.store);
	GLAArrayEditorStore *collectionsEditorStore = [store collectionsEditorStoreForProject:project];
	
	[collectionsEditorStore editUsingBlock:block handleAddedChildren:^(NSArray *addedChildren) {
		[self collectionsDidChange:addedChildren];
	} handleRemovedChildren:^(NSArray *removedChildren) {
		[store permanentlyDeleteAssociatedFilesForCollections:removedChildren];
	} handleReplacedChildren:^(NSArray *originalChildren, NSArray *replacementChildren) {
		[self collectionsDidChange:replacementChildren];
	}];
	
	[self collectionListForProjectDidChange:project];
	
	return YES;
}

- (GLACollection *)createNewCollectionWithName:(NSString *)name type:(NSString *)type color:(GLACollectionColor *)color inProject:(GLAProject *)project
{
	NSAssert(project != nil, @"Passed project must not be nil.");
	
	GLACollection *collection = [GLACollection newWithType:type creatingFromEditing:^(id<GLACollectionEditing> collectionEditor) {
		(collectionEditor.name) = name;
		(collectionEditor.color) = color;
	}];
	
	[self editCollectionsOfProject:project usingBlock:^(id<GLAArrayEditing> collectionListEditor) {
		[collectionListEditor addChildren:@[collection]];
	}];
	
	return collection;
}

- (GLACollection *)editCollection:(GLACollection *)collection inProject:(GLAProject *)project usingBlock:(void(^)(id<GLACollectionEditing>collectionEditor))editBlock
{
	__block GLACollection *changedCollection = nil;
	
	[self editCollectionsOfProject:project usingBlock:^(id<GLAArrayEditing> collectionListEditor) {
		[collectionListEditor replaceFirstChildWhoseKey:@"UUID" hasValue:(collection.UUID) usingChangeBlock:^GLACollection *(GLACollection *originalCollection) {
			changedCollection = [originalCollection copyWithChangesFromEditing:editBlock];
			return changedCollection;
		}];
	}];
	
	return changedCollection;
}

- (GLACollection *)renameCollection:(GLACollection *)collection inProject:(GLAProject *)project toString:(NSString *)name
{
	return [self editCollection:collection inProject:project usingBlock:^(id<GLACollectionEditing> collectionEditor) {
		(collectionEditor.name) = name;
	}];
}

- (GLACollection *)changeColorOfCollection:(GLACollection *)collection inProject:(GLAProject *)project toColor:(GLACollectionColor *)color
{
	return [self editCollection:collection inProject:project usingBlock:^(id<GLACollectionEditing> collectionEditor) {
		(collectionEditor.color) = color;
	}];
}

- (void)permanentlyDeleteCollection:(GLACollection *)collection fromProject:(GLAProject *)project
{
	[self editCollectionsOfProject:project usingBlock:^(id<GLAArrayEditing> collectionListEditor) {
		NSIndexSet *indexes = [collectionListEditor indexesOfChildrenWhoseKeyPath:@"UUID" hasValue:(collection.UUID)];
		[collectionListEditor removeChildrenAtIndexes:indexes];
	}];
}

#pragma mark Highlights

- (void)loadHighlightsForProjectIfNeeded:(GLAProject *)project
{
	[(self.store) loadHighlightsForProjectIfNeeded:project];
}

- (NSArray *)copyHighlightsForProject:(GLAProject *)project
{
	return [(self.store) copyHighlightsForProject:project];
}

- (BOOL)editHighlightsOfProject:(GLAProject *)project usingBlock:(void (^)(id<GLAArrayEditing>highlightsListEditor))block
{
	GLAProjectManagerStore *store = (self.store);
	GLAArrayEditorStore *highlightsEditorStore = [store highlightsEditorStoreForProject:project];
	
	[highlightsEditorStore editUsingBlock:block handleAddedChildren:nil handleRemovedChildren:^(NSArray *removedChildren) {
		
	} handleReplacedChildren:^(NSArray *originalChildren, NSArray *replacementChildren) {
		
	}];
	
	[self highlightsListForProjectDidChange:project];
	
	return YES;
}

- (void)removeHighlightsWithCollectedFiles:(NSArray *)collectedFiles fromProject:(GLAProject *)project
{
	NSSet *removedCollectionFileUUIDs = [NSSet setWithArray:[collectedFiles valueForKey:@"UUID"]];
	[self editHighlightsOfProject:project usingBlock:^(id<GLAArrayEditing> highlightsEditor) {
		NSIndexSet *indexesOfRemovedFiles = [highlightsEditor indexesOfChildrenWhoseKeyPath:@"UUID" hasValueContainedInSet:removedCollectionFileUUIDs];
		[highlightsEditor removeChildrenAtIndexes:indexesOfRemovedFiles];
	}];
}

#pragma mark Collection Files List

- (BOOL)hasLoadedFilesForCollection:(GLACollection *)filesListCollection
{
	NSAssert(filesListCollection != nil, @"Collection must not be nil.");
	return [(self.store) hasLoadedFilesForCollection:filesListCollection];
}

- (void)loadFilesListForCollectionIfNeeded:(GLACollection *)filesListCollection
{
	NSAssert(filesListCollection != nil, @"Collection must not be nil.");
	[(self.store) requestFilesListForCollection:filesListCollection];
}

- (NSArray *)copyFilesListForCollection:(GLACollection *)filesListCollection
{
	NSAssert(filesListCollection != nil, @"Collection must not be nil.");
	return [(self.store) copyFilesListForCollection:filesListCollection];
}

- (GLACollectedFile *)collectedFileWithUUID:(NSUUID *)collectedFileUUID insideCollection:(GLACollection *)filesListCollection
{
	NSAssert(collectedFileUUID != nil, @"Collected file UUID must not be nil.");
	NSAssert(filesListCollection != nil, @"Collection must not be nil.");
	return [(self.store) collectedFileWithUUID:collectedFileUUID insideCollection:filesListCollection];
}

- (BOOL)editFilesListOfCollection:(GLACollection *)filesListCollection usingBlock:(void (^)(id<GLAArrayEditing> filesListEditor))block
{
	GLAProjectManagerStore *store = (self.store);
	GLAArrayEditorStore *filesListEditorStore = [store filesListEditorStoreForCollection:filesListCollection];
	
	__block NSArray *removedCollectedFiles = nil;
	[filesListEditorStore editUsingBlock:block handleAddedChildren:nil handleRemovedChildren:^(NSArray *removedChildren) {
		removedCollectedFiles = removedChildren;
	} handleReplacedChildren:nil];
	
	if (removedCollectedFiles) {
		GLAProject *project = [self projectWithUUID:(filesListCollection.projectUUID)];
		[self removeHighlightsWithCollectedFiles:removedCollectedFiles fromProject:project];
	}
	
	[self filesListForCollectionDidChange:filesListCollection];
	
	return YES;
}

#pragma mark Highlighted Collected File

- (GLACollection *)collectionForHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile loadIfNeeded:(BOOL)load
{
	NSUUID *collectionUUID = (highlightedCollectedFile.holdingCollectionUUID);
	GLACollection *collection = [self collectionWithUUID:collectionUUID];
	
	if (collection) {
		return collection;
	}
	
	if (load) {
		NSUUID *projectUUID = (highlightedCollectedFile.projectUUID);
		GLAProject *project = [self projectWithUUID:projectUUID];
		[self loadCollectionsForProjectIfNeeded:project];
	}
	
	return nil;
}

- (GLACollectedFile *)collectedFileForHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile loadIfNeeded:(BOOL)load
{
	GLACollection *holdingCollection = [self collectionForHighlightedCollectedFile:highlightedCollectedFile loadIfNeeded:load];
	
	if (holdingCollection) {
		if ([self hasLoadedFilesForCollection:holdingCollection]) {
			NSUUID *collectedFileUUID = (highlightedCollectedFile.collectedFileUUID);
			GLACollectedFile *collectedFile = [self collectedFileWithUUID:collectedFileUUID insideCollection:holdingCollection];
			
			return collectedFile;
		}
		
		if (load) {
			[self loadFilesListForCollectionIfNeeded:holdingCollection];
		}
	}
	
	return nil;
}

#pragma mark Validating

- (NSString *)normalizeName:(NSString *)name
{
	if (!name) {
		return @"";
	}
	
	NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	return [name stringByTrimmingCharactersInSet:whitespaceCharacterSet];
}

- (BOOL)nameIsValid:(NSString *)name
{
	NSString *normalizedName = [self normalizeName:name];
	if ([normalizedName isEqualToString:@""]) {
		return NO;
	}
	
	return YES;
}

#pragma mark Saving

- (void)requestSaveAllProjects
{
	[(self.store) requestSaveAllProjects];
}

- (void)requestSaveCollectionsForProject:(GLAProject *)project
{
	[(self.store) requestSaveCollectionsForProject:project];
}

- (void)requestSaveFilesListForCollections:(GLACollection *)filesListCollection
{
	[(self.store) requestSaveFilesListForCollection:filesListCollection];
}


#pragma mark Notifications

- (id)notificationObjectForProject:(GLAProject *)project
{
	return [self notificationObjectForProjectUUID:(project.UUID)];
}

- (id)notificationObjectForProjectUUID:(NSUUID *)projectUUID
{
	NSAssert(projectUUID != nil, @"Passed project UUID must not be nil.");
	
	NSMutableDictionary *notificationRepresenters = (self.projectUUIDNotificationRepresenters);
	if (!notificationRepresenters) {
		notificationRepresenters = (self.projectUUIDNotificationRepresenters) = [NSMutableDictionary new];
	}
	
	GLAObjectNotificationRepresenter *representer = notificationRepresenters[projectUUID];
	
	if (!representer) {
		representer = notificationRepresenters[projectUUID] = [[GLAObjectNotificationRepresenter alloc] initWithUUID:projectUUID];
	}
	
	return representer;
}

- (id)notificationObjectForCollection:(GLACollection *)collection
{
	return [self notificationObjectForCollectionUUID:(collection.UUID)];
}

- (id)notificationObjectForCollectionUUID:(NSUUID *)collectionUUID
{
	NSAssert(collectionUUID != nil, @"Passed collection UUID must not be nil.");
	
	NSMutableDictionary *notificationRepresenters = (self.collectionUUIDNotificationRepresenters);
	if (!notificationRepresenters) {
		notificationRepresenters = (self.collectionUUIDNotificationRepresenters) = [NSMutableDictionary new];
	}
	
	GLAObjectNotificationRepresenter *representer = notificationRepresenters[collectionUUID];
	
	if (!representer) {
		representer = notificationRepresenters[collectionUUID] = [[GLAObjectNotificationRepresenter alloc] initWithUUID:collectionUUID];
	}
	
	return representer;
}

- (void)allProjectsDidChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerAllProjectsDidChangeNotification object:self];
}

- (void)plannedProjectsDidChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerPlannedProjectsDidChangeNotification object:self];
}

- (void)nowProjectDidChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerNowProjectDidChangeNotification object:self];
}

- (void)collectionListForProjectDidChange:(GLAProject *)project
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectCollectionsDidChangeNotification object:[self notificationObjectForProject:project]];
}

- (void)highlightsListForProjectDidChange:(GLAProject *)project
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectHighlightsDidChangeNotification object:[self notificationObjectForProject:project]];
}

- (void)collectionsDidChange:(NSArray *)collections
{
	for (GLACollection *collection in collections) {
		[self collectionDidChange:collection];
	}
}

- (void)collectionDidChange:(GLACollection *)collection
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLACollectionDidChangeNotification object:[self notificationObjectForCollection:collection]];
}

- (void)filesListForCollectionDidChange:(GLACollection *)collection
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLACollectionFilesListDidChangeNotification object:[self notificationObjectForCollection:collection]];
}

#pragma mark Status

- (NSString *)statusOfCurrentActivity
{
	return [(self.store) statusOfCurrentActivity];
}

- (NSString *)statusOfCompletedActivity
{
	return [(self.store) statusOfCompletedActivity];
}

#pragma mark Dummy

+ (GLAProject *)newDummyProjectWithName:(NSString *)name
{
	GLAProject *project = [[GLAProject alloc] initWithName:name dateCreated:[NSDate date]];
	
	return project;
}

+ (NSArray *)allProjectsDummyContent
{
	static NSArray *dummyAllProjects;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dummyAllProjects =
  @[
	[GLAProjectManager newDummyProjectWithName:@"Project With Big Long Name That Goes On"],
	[GLAProjectManager newDummyProjectWithName:@"Eat a thousand muffins in one day"],
	[GLAProjectManager newDummyProjectWithName:@"Another, yet another project"],
	[GLAProjectManager newDummyProjectWithName:@"The one that just won’t die"],
	[GLAProjectManager newDummyProjectWithName:@"Could this be my favourite project ever?"],
	[GLAProjectManager newDummyProjectWithName:@"Freelance project #82"]
	];
	});
	
	return dummyAllProjects;
	
	
}

+ (GLAProject *)nowProjectDummyContent
{
	NSArray *allProjects = [GLAProjectManager allProjectsDummyContent];
	return allProjects[0];
}

+ (NSArray *)collectionListDummyContent
{
	return
	@[
	  [GLACollection dummyCollectionWithName:@"Working Files" color:[GLACollectionColor pastelLightBlue] type:GLACollectionTypeFilesList],
	  [GLACollection dummyCollectionWithName:@"Briefs" color:[GLACollectionColor pastelGreen] type:GLACollectionTypeFilesList],
	  [GLACollection dummyCollectionWithName:@"Contacts" color:[GLACollectionColor pastelPinkyPurple] type:GLACollectionTypeFilesList],
	  [GLACollection dummyCollectionWithName:@"Apps" color:[GLACollectionColor pastelRed] type:GLACollectionTypeFilesList],
	  [GLACollection dummyCollectionWithName:@"Research" color:[GLACollectionColor pastelYellow] type:GLACollectionTypeFilesList]
	  ];
}

@end


#pragma mark -


@implementation GLAProjectManagerStoreState

@end


#pragma mark -

@interface GLAProjectManagerStore () <GLAArrayEditorStoreDelegate>

//@property(readwrite, nonatomic) NSArray *plannedProjectsSortedByDateNextPlanned;

@property(readonly, nonatomic) NSOperationQueue *foregroundOperationQueue;
@property(nonatomic) NSOperationQueue *backgroundOperationQueue;

@property(readonly, nonatomic) GLAProjectManagerStoreState *foregroundState;
@property(readonly, nonatomic) GLAProjectManagerStoreState *backgroundState;

@property(nonatomic) NSMutableDictionary *projectIDsToCollectionEditorStores;
@property(nonatomic) NSMutableDictionary *projectIDsToHighlightsEditorStores;

@property(nonatomic) NSMutableDictionary *collectionIDsToFilesListEditorStores;

@property(nonatomic) GLAModelUUIDMap *collectionUUIDMap;
//@property(nonatomic) NSMutableDictionary *collectionIdentifiersToProjectIDSets;

@property(readonly, nonatomic) NSURL *allProjectsJSONFileURL;
@property(readonly, nonatomic) NSURL *nowProjectJSONFileURL;

@property(nonatomic) BOOL needsToLoadAllProjects;
- (void)loadAllProjects:(dispatch_block_t)completionBlock;

@property(nonatomic) BOOL needsToSaveAllProjects;
- (void)writeAllProjects:(dispatch_block_t)completionBlock;

//@property(nonatomic) BOOL needsToLoadPlannedProjects;
//- (void)loadPlannedProjects;
//@property(nonatomic) BOOL needsToSavePlannedProjects;
//- (void)writePlannedProjects;

@property(nonatomic) BOOL needsToLoadNowProject;
- (void)loadNowProject:(dispatch_block_t)completionBlock;

@property(nonatomic) BOOL needsToSaveNowProject;
- (void)writeNowProject:(dispatch_block_t)completionBlock;

#pragma Status

@property(nonatomic) NSMutableSet *actionsThatAreRunning;
@property(nonatomic) NSMutableDictionary *actionsToBeginTime;
@property(nonatomic) NSMutableDictionary *actionsToEndTime;

- (dispatch_block_t)beginActionWithIdentifier:(NSString *)actionIdentifierFormat, ... NS_FORMAT_FUNCTION(1,2);

- (NSTimeInterval)durationOfLastRunOfActionWithIdentifier:(NSString *)actionIdentifier;

@end


@implementation GLAProjectManagerStore

- (instancetype)initWithProjectManager:(GLAProjectManager *)projectManager;
{
    self = [super init];
    if (self) {
		(self.projectManager) = projectManager;
		
		_backgroundOperationQueue = [NSOperationQueue new];
		(_backgroundOperationQueue.maxConcurrentOperationCount) = 1;
		
		_foregroundState = [GLAProjectManagerStoreState new];
		_backgroundState = [GLAProjectManagerStoreState new];
		
		_collectionUUIDMap = [GLAModelUUIDMap new];
		
#if 0
		NSError *testError = [GLAModelErrors errorForMissingRequiredKey:GLAProjectManagerJSONAllProjectsKey inJSONFileAtURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
		[projectManager handleError:testError];
#endif
    }
    return self;
}

#pragma mark Queuing Work

- (NSOperationQueue *)foregroundOperationQueue
{
	GLAProjectManager *projectManager = (self.projectManager);
	if (projectManager) {
		return (projectManager.receivingOperationQueue);
	}
	else {
		return nil;
	}
}

- (void)runInBackground:(void (^)(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState))block
{
	__weak GLAProjectManagerStore *weakStore = self;
	
	[(self.backgroundOperationQueue) addOperationWithBlock:^{
		GLAProjectManagerStore *store = weakStore;
		GLAProjectManagerStoreState *backgroundState = (store.backgroundState);
		
		block(store, backgroundState);
	}];
}

- (void)runInForeground:(void (^)(GLAProjectManagerStore *store, GLAProjectManager *projectManager))block
{
	__weak GLAProjectManagerStore *weakStore = self;
	
	[(self.foregroundOperationQueue) addOperationWithBlock:^{
		GLAProjectManagerStore *store = weakStore;
		GLAProjectManager *projectManager = (store.projectManager);
		
		block(store, projectManager);
	}];
}

- (BOOL)shouldLoadTestProjects
{
	GLAProjectManager *pm = (self.projectManager);
	if (pm) {
		return (pm.shouldLoadTestProjects);
	}
	else {
		return NO;
	}
}

- (void)handleError:(NSError *)error
{
	GLAProjectManager *pm = (self.projectManager);
	[pm handleError:error];
}

#pragma mark Files

- (NSURL *)version1DirectoryURLWithInnerDirectoryComponents:(NSArray *)extraPathComponents
{
	GLAProjectManager *projectManager = (self.projectManager);
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	NSURL *directoryURL = [fm URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
	
	if (!directoryURL) {
		[projectManager handleError:error];
		return nil;
	}
	
	// Convert path to its components, so we can add more components
	// and convert back into a URL.
	NSMutableArray *pathComponents = [(directoryURL.pathComponents) mutableCopy];
	
	// {appBundleID}/v1/
	NSString *appBundleID = ([NSBundle mainBundle].bundleIdentifier);
	[pathComponents addObject:appBundleID];
	[pathComponents addObject:@"v1"];
	
	// Append extra path components passed to this method.
	if (extraPathComponents) {
		[pathComponents addObjectsFromArray:extraPathComponents];
	}
	
	// Convert components back into a URL.
	directoryURL = [NSURL fileURLWithPathComponents:pathComponents];
	
	BOOL directorySuccess = [fm createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
	if (!directorySuccess) {
		[projectManager handleError:error];
		return nil;
	}
	
	return directoryURL;
}

- (NSURL *)version1DirectoryURL
{
	return [self version1DirectoryURLWithInnerDirectoryComponents:nil];
}

- (NSURL *)allProjectsJSONFileURL
{
	NSURL *directoryURL = (self.version1DirectoryURL);
	NSURL *fileURL = [directoryURL URLByAppendingPathComponent:@"all-projects.json"];
	
	return fileURL;
}

- (NSURL *)nowProjectJSONFileURL
{
	NSURL *directoryURL = (self.version1DirectoryURL);
	NSURL *fileURL = [directoryURL URLByAppendingPathComponent:@"now-project.json"];
	
	return fileURL;
}

- (NSURL *)projectDirectoryURLForProjectID:(NSUUID *)projectUUID
{
	NSAssert(projectUUID != nil, @"Project UUID must not be nil.");
	
	NSString *projectDirectoryName = [NSString stringWithFormat:@"project-%@", (projectUUID.UUIDString)];
	NSURL *directoryURL = [self version1DirectoryURLWithInnerDirectoryComponents:@[projectDirectoryName]];
	
	return directoryURL;
}

- (NSURL *)collectionsListJSONFileURLForProjectID:(NSUUID *)projectUUID
{
	NSAssert(projectUUID != nil, @"Project UUID must not be nil.");
	
	NSURL *directoryURL = [self projectDirectoryURLForProjectID:projectUUID];
	NSURL *fileURL = [directoryURL URLByAppendingPathComponent:@"collections-list.json"];
	
	return fileURL;
}

- (NSURL *)highlightsListJSONFileURLForProjectID:(NSUUID *)projectUUID
{
	NSAssert(projectUUID != nil, @"Project UUID must not be nil.");
	
	NSURL *directoryURL = [self projectDirectoryURLForProjectID:projectUUID];
	NSURL *fileURL = [directoryURL URLByAppendingPathComponent:@"highlights-list.json"];
	
	return fileURL;
}

- (NSURL *)collectionDirectoryURLForCollectionID:(NSUUID *)collectionUUID
{
	NSAssert(collectionUUID != nil, @"Collection UUID must not be nil.");
	
	NSString *collectionDirectoryName = [NSString stringWithFormat:@"collection-%@", (collectionUUID.UUIDString)];
	NSURL *directoryURL = [self version1DirectoryURLWithInnerDirectoryComponents:@[collectionDirectoryName]];
	
	return directoryURL;
}

- (NSURL *)filesListJSONFileURLForCollectionID:(NSUUID *)collectionUUID
{
	NSAssert(collectionUUID != nil, @"Collection UUID must not be nil.");
	
	NSURL *directoryURL = [self collectionDirectoryURLForCollectionID:collectionUUID];
	NSURL *fileURL = [directoryURL URLByAppendingPathComponent:@"files-list.json"];
	
	return fileURL;
}

#pragma mark -

- (NSDictionary *)background_readJSONDictionaryFromFileURL:(NSURL *)fileURL
{
	GLAProjectManager *projectManager = (self.projectManager);
	NSError *error = nil;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:(fileURL.path)]) {
		return nil;
	}
	
	NSData *JSONData = [NSData dataWithContentsOfURL:fileURL options:0 error:&error];
	if (!JSONData) {
		[projectManager handleError:error];
		return nil;
	}
	
	NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
	if (!JSONDictionary) {
		[projectManager handleError:error];
		return nil;
	}
	
	return JSONDictionary;
}

- (NSArray *)background_readModelsOfClass:(Class)modelClass atDictionaryKey:(NSString *)JSONKey fromJSONFileURL:(NSURL *)fileURL
{
	GLAProjectManager *projectManager = (self.projectManager);
	NSError *error = nil;
	
	NSDictionary *JSONDictionary = [self background_readJSONDictionaryFromFileURL:fileURL];
	if (!JSONDictionary) {
		return nil;
	}
	
	NSArray *JSONArray = JSONDictionary[JSONKey];
	if (!JSONArray) {
		error = [GLAModelErrors errorForMissingRequiredKey:JSONKey inJSONFileAtURL:fileURL];
		[projectManager handleError:error];
		return nil;
	}
	
	NSArray *models = [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:JSONArray error:&error];
	if (!models) {
		[projectManager handleError:error];
		return nil;
	}
	
	return models;
}

- (BOOL)writeJSONDictionary:(NSDictionary *)JSONDictionary toFileURL:(NSURL *)fileURL
{
	GLAProjectManager *projectManager = (self.projectManager);
	NSError *error = nil;
	
	NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONDictionary options:0 error:&error];
	if (!JSONData) {
		[projectManager handleError:error];
		return NO;
	}
	
	[JSONData writeToURL:fileURL atomically:YES];
	
	return YES;
}

#pragma mark - Loading

#pragma mark Load All Projects

- (void)requestAllProjects
{
	if (self.needsToLoadAllProjects) {
		return;
	}
	if (self.needsToSaveAllProjects) {
		return;
	}
	
	(self.needsToLoadAllProjects) = YES;
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Load All Projects"];
	
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[store loadAllProjects:actionTracker];
	}];
}

- (void)loadAllProjects:(dispatch_block_t)completionBlock
{
	NSURL *fileURL = (self.allProjectsJSONFileURL);
	if (!fileURL) {
		return;
	}
	
	BOOL loadTestContent = (self.shouldLoadTestProjects);
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState) {
		NSArray *allProjects = nil;
		
		if (loadTestContent) {
			allProjects = [GLAProjectManager allProjectsDummyContent];
		}
		else {
			allProjects = [store background_readAllProjectsFromJSONFileURL:fileURL];
		}
		
		if (!allProjects) {
			allProjects = @[];
		}
		
		[store background_processLoadedAllProjects:allProjects];
		
		completionBlock();
	}];
}

- (NSArray *)background_readAllProjectsFromJSONFileURL:(NSURL *)fileURL
{
	return [self background_readModelsOfClass:[GLAProject class] atDictionaryKey:GLAProjectManagerJSONAllProjectsKey fromJSONFileURL:fileURL];
}

- (void)background_processLoadedAllProjects:(NSArray *)allProjectsUnsorted
{
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
	NSArray *allProjectsSorted = [allProjectsUnsorted sortedArrayUsingDescriptors:@[sortDescriptor]];
	
	NSArray *projectUUIDs = [allProjectsSorted valueForKey:@"UUID"];
	NSDictionary *allProjectUUIDsToProjects = [NSDictionary dictionaryWithObjects:allProjectsSorted forKeys:projectUUIDs];
	
	(self.backgroundState.allProjectsSortedByDateCreatedNewestToOldest) = allProjectsSorted;
	(self.backgroundState.allProjectUUIDsToProjects) = allProjectUUIDsToProjects;
	[self background_matchNowProjectFromAllProjectsUsingUUID];
	
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		(store.foregroundState.allProjectsSortedByDateCreatedNewestToOldest) = allProjectsSorted;
		(store.foregroundState.allProjectUUIDsToProjects) = allProjectUUIDsToProjects;
		
		[projectManager allProjectsDidChange];
		
		(store.needsToLoadAllProjects) = NO;
	}];
}

- (NSArray *)allProjectsSortedByDateCreatedNewestToOldest
{
	return [(self.foregroundState.allProjectsSortedByDateCreatedNewestToOldest) copy];
}

- (GLAProject *)projectWithUUID:(NSUUID *)projectUUID
{
	NSDictionary *allProjectUUIDsToProjects = (self.foregroundState.allProjectUUIDsToProjects);
	if (allProjectUUIDsToProjects) {
		return allProjectUUIDsToProjects[projectUUID];
	}
	else {
		return nil;
	}
}

#pragma mark Load Now Project

- (void)background_matchNowProjectFromAllProjectsUsingUUID
{
	GLAProjectManagerStoreState *backgroundState = (self.backgroundState);
	NSArray *allProjects = (backgroundState.allProjectsSortedByDateCreatedNewestToOldest);
	if (!allProjects) {
		[self requestAllProjects];
		return;
	}
	
	NSUUID *nowProjectUUID = (backgroundState.nowProjectUUID);
	if (!nowProjectUUID) {
		return;
	}
	
	NSDictionary *allProjectUUIDsToProjects = (backgroundState.allProjectUUIDsToProjects);
	GLAProject *nowProject = allProjectUUIDsToProjects[nowProjectUUID];
	
	NSAssert(nowProject != nil, @"Could not find project to match now project's UUID %@", nowProjectUUID);
	
	(self.backgroundState.nowProject) = nowProject;
	
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		(store.foregroundState.nowProject) = nowProject;
		[projectManager nowProjectDidChange];
	}];
}

- (void)requestNowProject
{
	// Only load once.
	if (self.needsToLoadNowProject) {
		return;
	}
	// If currently saving, don't load anything from disk.
	if (self.needsToSaveNowProject) {
		return;
	}
	
	(self.needsToLoadNowProject) = YES;
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Load Now Project"];
	
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[store loadNowProject:actionTracker];
	}];
}

- (void)loadNowProject:(dispatch_block_t)completionBlock
{
	NSURL *fileURL = (self.nowProjectJSONFileURL);
	if (!fileURL) {
		return;
	}
	
	BOOL loadTestContent = (self.shouldLoadTestProjects);
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState) {
		GLAProject *project = nil;
		
		if (loadTestContent) {
			project = [GLAProjectManager nowProjectDummyContent];
		}
		else {
			project = [store background_readNowProjectFromJSONFileURL:fileURL];
		}
		
		[store background_processLoadedNowProject:project];
		
		completionBlock();
	}];
}

- (GLAProject *)background_readNowProjectFromJSONFileURL:(NSURL *)fileURL
{
	GLAProjectManager *projectManager = (self.projectManager);
	NSError *error = nil;
	
	NSDictionary *JSONDictionary = [self background_readJSONDictionaryFromFileURL:fileURL];
	if (!JSONDictionary) {
		return nil;
	}
	
	NSDictionary *JSONProject = JSONDictionary[GLAProjectManagerJSONNowProjectKey];
	if (!JSONProject) {
		error = [GLAModelErrors errorForMissingRequiredKey:GLAProjectManagerJSONNowProjectKey inJSONFileAtURL:fileURL];
		[projectManager handleError:error];
		return nil;
	}
	
	GLAProject *project = [MTLJSONAdapter modelOfClass:[GLAProject class] fromJSONDictionary:JSONProject error:&error];
	if (!project) {
		[projectManager handleError:error];
		return nil;
	}
	
	return project;
}

- (void)background_processLoadedNowProject:(GLAProject *)project
{
	(self.backgroundState.nowProjectUUID) = (project.UUID);
	
	[self background_matchNowProjectFromAllProjectsUsingUUID];
	
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		(self.needsToLoadNowProject) = NO;
	}];
}

- (GLAProject *)nowProject
{
	return (self.foregroundState.nowProject);
}

#pragma mark Load Collections

- (GLAArrayEditorStore *)collectionsEditorStoreForProject:(GLAProject *)project createIfNeeded:(BOOL)create
{
	NSMutableDictionary *projectIDsToCollectionEditorStores = (self.projectIDsToCollectionEditorStores);
	if (projectIDsToCollectionEditorStores == nil) {
		projectIDsToCollectionEditorStores = (self.projectIDsToCollectionEditorStores) = [NSMutableDictionary new];
	}
	
	NSUUID *projectUUID = (project.UUID);
	GLAArrayEditorStore *collectionsEditorStore = projectIDsToCollectionEditorStores[projectUUID];
	if (collectionsEditorStore) {
		return collectionsEditorStore;
	}
	else if (!create) {
		return nil;
	}
	
	NSURL *JSONFileURL = [self collectionsListJSONFileURLForProjectID:projectUUID];
	NSDictionary *userInfo =
  @{
	@"projectUUID": projectUUID
	};
	
	collectionsEditorStore = [[GLAArrayEditorStore alloc] initWithDelegate:self modelClass:[GLACollection class] JSONFileURL:JSONFileURL JSONDictionaryKey:GLAProjectManagerJSONCollectionsListKey userInfo:userInfo];
	
	projectIDsToCollectionEditorStores[projectUUID] = collectionsEditorStore;
	
	return collectionsEditorStore;
}

- (GLAArrayEditorStore *)collectionsEditorStoreForProject:(GLAProject *)project
{
	return [self collectionsEditorStoreForProject:project createIfNeeded:YES];
}

- (BOOL)hasLoadedCollectionsForProject:(GLAProject *)project
{
	GLAArrayEditorStore *collectionsEditorStore = [self collectionsEditorStoreForProject:project createIfNeeded:NO];
	if (!collectionsEditorStore) {
		return NO;
	}
	
	return (collectionsEditorStore.finishedLoading);
}

- (void)requestCollectionsForProject:(GLAProject *)project
{
	GLAArrayEditorStore *collectionsEditorStore = [self collectionsEditorStoreForProject:project];
	
	if (!(collectionsEditorStore.needsLoading)) {
		return;
	}
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Load Collections for Project \"%@\"", (project.name)];
	[collectionsEditorStore loadWithCompletionBlock:^{
		[(self.projectManager) collectionListForProjectDidChange:project];
		
		actionTracker();
	}];
}

- (NSArray *)copyCollectionsForProject:(GLAProject *)project
{
	GLAArrayEditorStore *collectionsEditorStore = [self collectionsEditorStoreForProject:project];
	if (collectionsEditorStore) {
		return [collectionsEditorStore copyChildren];
	}
	else {
		return nil;
	}
}

- (GLACollection *)collectionWithUUID:(NSUUID *)collectionUUID
{
	GLAModelUUIDMap *collectionUUIDMap = (self.collectionUUIDMap);
	return (GLACollection *)[collectionUUIDMap objectWithUUID:collectionUUID];
}

- (void)permanentlyDeleteAssociatedFilesForCollections:(NSArray *)collections
{
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState) {
		NSFileManager *fm = [NSFileManager defaultManager];
		
		for (GLACollection *collection in collections) {
			NSURL *directoryURL = [self collectionDirectoryURLForCollectionID:(collection.UUID)];
			
			NSError *error = nil;
			
			BOOL success = [fm removeItemAtURL:directoryURL error:&error];
			if (!success) {
				[store handleError:error];
			}
		}
	}];
}

#pragma mark Highlights

- (GLAArrayEditorStore *)highlightsEditorStoreForProject:(GLAProject *)project
{
	NSMutableDictionary *projectIDsToHighlightsEditorStores = (self.projectIDsToHighlightsEditorStores);
	if (projectIDsToHighlightsEditorStores == nil) {
		projectIDsToHighlightsEditorStores = (self.projectIDsToHighlightsEditorStores) = [NSMutableDictionary new];
	}
	
	NSUUID *projectUUID = (project.UUID);
	GLAArrayEditorStore *highlightsEditorStore = projectIDsToHighlightsEditorStores[projectUUID];
	if (highlightsEditorStore) {
		return highlightsEditorStore;
	}
	
	NSURL *JSONFileURL = [self highlightsListJSONFileURLForProjectID:projectUUID];
	NSDictionary *userInfo =
	@{
	  @"projectUUID": projectUUID
	  };
	
	highlightsEditorStore = [[GLAArrayEditorStore alloc] initWithDelegate:self modelClass:[GLAHighlightedItem class] JSONFileURL:JSONFileURL JSONDictionaryKey:GLAProjectManagerJSONHighlightsListKey userInfo:userInfo];
	
	projectIDsToHighlightsEditorStores[projectUUID] = highlightsEditorStore;
	
	return highlightsEditorStore;
}

- (void)loadHighlightsForProjectIfNeeded:(GLAProject *)project
{
	GLAArrayEditorStore *highlightsEditorStore = [self highlightsEditorStoreForProject:project];
	
	if (!(highlightsEditorStore.needsLoading)) {
		return;
	}
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Load Highlights for Project \"%@\"", (project.name)];
	[highlightsEditorStore loadWithCompletionBlock:^{
		[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			[projectManager highlightsListForProjectDidChange:project];
		}];
		
		actionTracker();
	}];
}

- (NSArray /* GLAHighlightedItem */ *)copyHighlightsForProject:(GLAProject *)project
{
	GLAArrayEditorStore *highlightsEditorStore = [self highlightsEditorStoreForProject:project];
	if (highlightsEditorStore) {
		return [highlightsEditorStore copyChildren];
	}
	else {
		return nil;
	}
}

#pragma mark Load Files List

- (GLAArrayEditorStore *)filesListEditorStoreForCollection:(GLACollection *)filesListCollection createIfNeeded:(BOOL)create
{
	NSMutableDictionary *collectionIDsToFilesListEditorStores = (self.collectionIDsToFilesListEditorStores);
	if (collectionIDsToFilesListEditorStores == nil) {
		collectionIDsToFilesListEditorStores = (self.collectionIDsToFilesListEditorStores) = [NSMutableDictionary new];
	}
	
	NSUUID *collectionUUID = (filesListCollection.UUID);
	GLAArrayEditorStore *filesListEditorStore = collectionIDsToFilesListEditorStores[collectionUUID];
	if (filesListEditorStore) {
		return filesListEditorStore;
	}
	else if (!create) {
		return nil;
	}
	
	NSURL *JSONFileURL = [self filesListJSONFileURLForCollectionID:collectionUUID];
	NSDictionary *userInfo =
	@{
	  @"collectionUUID": collectionUUID
	  };
	
	filesListEditorStore = [[GLAArrayEditorStore alloc] initWithDelegate:self modelClass:[GLACollectedFile class] JSONFileURL:JSONFileURL JSONDictionaryKey:GLAProjectManagerJSONFilesListKey userInfo:userInfo];
	
	collectionIDsToFilesListEditorStores[collectionUUID] = filesListEditorStore;
	
	return filesListEditorStore;
}

- (GLAArrayEditorStore *)filesListEditorStoreForCollection:(GLACollection *)filesListCollection
{
	return [self filesListEditorStoreForCollection:filesListCollection createIfNeeded:YES];
}

- (BOOL)hasLoadedFilesForCollection:(GLACollection *)filesListCollection
{
	GLAArrayEditorStore *filesListEditorStore = [self filesListEditorStoreForCollection:filesListCollection createIfNeeded:NO];
	if (!filesListEditorStore) {
		return NO;
	}
	
	return (filesListEditorStore.finishedLoading);
}

- (void)requestFilesListForCollection:(GLACollection *)filesListCollection
{
	GLAArrayEditorStore *filesListEditorStore = [self filesListEditorStoreForCollection:filesListCollection];
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Load Files List for Collection \"%@\"", (filesListCollection.name)];
	[filesListEditorStore loadWithCompletionBlock:^{
		[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			[projectManager filesListForCollectionDidChange:filesListCollection];
		}];
		
		actionTracker();
	}];
}

- (NSArray *)copyFilesListForCollection:(GLACollection *)filesListCollection
{
	GLAArrayEditorStore *filesListEditorStore = [self filesListEditorStoreForCollection:filesListCollection];
	if (filesListEditorStore) {
		return [filesListEditorStore copyChildren];
	}
	else {
		return nil;
	}
}

- (GLACollectedFile *)collectedFileWithUUID:(NSUUID *)collectedFileUUID insideCollection:(GLACollection *)filesListCollection
{
	GLAArrayEditorStore *filesListEditorStore = [self filesListEditorStoreForCollection:filesListCollection];
	id<GLAArrayInspecting> arrayInspector = (filesListEditorStore.inspectArray);
	
	NSIndexSet *indexes = [arrayInspector indexesOfChildrenWhoseKeyPath:@"UUID" hasValue:collectedFileUUID];
	if ((indexes.count) == 1) {
		NSArray *childInArray = [arrayInspector childrenAtIndexes:indexes];
		GLACollectedFile *collectedFile = childInArray[0];
		return collectedFile;
	}
	// No index or multiple indexes in invalid.
	else {
		return nil;
	}
}

#pragma mark - Editing

- (void)addProjects:(NSArray *)projects
{
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState) {
		NSArray *allProjectsBefore = (backgroundState.allProjectsSortedByDateCreatedNewestToOldest);
		NSArray *allProjects = [allProjectsBefore arrayByAddingObjectsFromArray:projects];
		[store background_processLoadedAllProjects:allProjects];
		
		[store runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			[store requestSaveAllProjects];
		}];
	}];
}

- (GLAProject *)editProject:(GLAProject *)project usingBlock:(void(^)(id<GLAProjectEditing>projectEditor))editBlock
{
	GLAProject *changedProject = [project copyWithChangesFromEditing:editBlock];
	NSUUID *projectUUID = (project.UUID);
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState) {
		NSMutableArray *allProjectsBefore = [(backgroundState.allProjectsSortedByDateCreatedNewestToOldest) mutableCopy];
		
		NSUInteger projectIndex = [allProjectsBefore indexOfObjectPassingTest:^BOOL(GLAProject *projectToCheck, NSUInteger idx, BOOL *stop) {
			return [(projectToCheck.UUID) isEqual:projectUUID];
		}];
		
		[allProjectsBefore replaceObjectAtIndex:projectIndex withObject:changedProject];
		
		[self background_processLoadedAllProjects:allProjectsBefore];
		
		[store runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			[store requestSaveAllProjects];
		}];
	}];
	
	return changedProject;
}

- (void)changeNowProject:(GLAProject *)project
{
	(self.foregroundState.nowProject) = project;
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState) {
		(backgroundState.nowProject) = project;
	}];
}

#pragma mark - Saving

#pragma mark Save All Projects

- (void)requestSaveAllProjects
{
	if (self.needsToSaveAllProjects) {
		return;
	}
	
	(self.needsToSaveAllProjects) = YES;
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Save All Projects"];
	
	// Queue so this is done after the current run loop.
	// Multiple calls to -requestSaveAllProjects will be coalsced.
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[store writeAllProjects:actionTracker];
	}];
}

- (void)writeAllProjects:(dispatch_block_t)completionBlock
{
	NSURL *fileURL = (self.allProjectsJSONFileURL);
	if (!fileURL) {
		return;
	}
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState) {
		NSArray *allProjectsSorted = (backgroundState.allProjectsSortedByDateCreatedNewestToOldest);
		
		NSArray *JSONArray = [MTLJSONAdapter JSONArrayFromModels:allProjectsSorted];
		
		NSDictionary *JSONDictionary =
		@{
		  GLAProjectManagerJSONAllProjectsKey: JSONArray
		  };
		
		[store writeJSONDictionary:JSONDictionary toFileURL:fileURL];
		
		completionBlock();
		
		[store runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			(store.needsToSaveAllProjects) = NO;
		}];
	}];
}

#pragma mark Save Now Project

- (void)requestSaveNowProject
{
	// FIXME: if now project is changed while a save is already in process, need a change counter or == here.
	if (self.needsToSaveNowProject) {
		return;
	}
	
	(self.needsToSaveNowProject) = YES;
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Save Now Project"];
	[self writeNowProject:actionTracker];
}

- (void)writeNowProject:(dispatch_block_t)completionBlock
{
	NSURL *fileURL = (self.nowProjectJSONFileURL);
	if (!fileURL) {
		return;
	}
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState) {
		GLAProject *project = (backgroundState.nowProject);
		// TODO support saving no now project.
		NSAssert(project != nil, @"Can't save no now project.");
		NSDictionary *JSONProject = [MTLJSONAdapter JSONDictionaryFromModel:project];
		
		NSDictionary *JSONDictionary =
		@{GLAProjectManagerJSONNowProjectKey: JSONProject};
		
		[store writeJSONDictionary:JSONDictionary toFileURL:fileURL];
		
		completionBlock();
		
		[store runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			(store.needsToSaveAllProjects) = NO;
		}];
	}];
}

- (void)permanentlyDeleteAssociatedFilesForProjects:(NSArray *)projects
{
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState) {
		NSFileManager *fm = [NSFileManager defaultManager];
		
		for (GLAProject *project in projects) {
			NSURL *directoryURL = [self projectDirectoryURLForProjectID:(project.UUID)];
			
			NSError *error = nil;
			
			BOOL success = [fm removeItemAtURL:directoryURL error:&error];
			if (!success) {
				[store handleError:error];
			}
		}
	}];
}

#pragma mark Save Project Collection List

- (void)requestSaveCollectionsForProject:(GLAProject *)project
{
	GLAArrayEditorStore *collectionsEditorStore = [self collectionsEditorStoreForProject:project];
	[collectionsEditorStore saveWithCompletionBlock:nil];
}

#pragma mark Save Collection Content

- (void)requestSaveFilesListForCollection:(GLACollection *)filesListCollection
{
	GLAArrayEditorStore *filesListEditorStore = [self filesListEditorStoreForCollection:filesListCollection];
	[filesListEditorStore saveWithCompletionBlock:nil];
}

#pragma mark Array Editor Store

- (NSOperationQueue *)foregroundOperationQueueForArrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore
{
	return (self.foregroundOperationQueue);
}

- (NSOperationQueue *)backgroundOperationQueueForArrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore
{
	return (self.backgroundOperationQueue);
}

- (void)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore handleError:(NSError *)error fromMethodWithSelector:(SEL)storeMethodSelector
{
	[self handleError:error];
}


- (NSArray *)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore processLoadedChildrenInBackground:(NSArray *)children
{
	Class modelClass = (arrayEditorStore.modelClass);
	if ([modelClass isSubclassOfClass:[GLACollection class]]) {
		NSUUID *projectUUID = (arrayEditorStore.userInfo)[@"projectUUID"];
		
		NSMutableArray *processedChildren = [NSMutableArray arrayWithCapacity:(children.count)];
		for (GLACollection *collection in children) {
			GLACollection *collectionWithProject = [collection copyWithChangesFromEditing:^(id<GLACollectionEditing> editor) {
				(editor.projectUUID) = projectUUID;
			}];
			[processedChildren addObject:collectionWithProject];
		}
		
		return processedChildren;
	}
	else if ([modelClass isSubclassOfClass:[GLAHighlightedItem class]]) {
		NSUUID *projectUUID = (arrayEditorStore.userInfo)[@"projectUUID"];
		
		NSMutableArray *processedChildren = [NSMutableArray arrayWithCapacity:(children.count)];
		for (GLAHighlightedItem *item in children) {
			GLAHighlightedItem *itemWithProject = [item copyWithChangesFromEditing:^(id<GLAHighlightedItemEditing> editor) {
				(editor.projectUUID) = projectUUID;
			}];
			[processedChildren addObject:itemWithProject];
		}
		
		return processedChildren;
	}
	else {
		return children;
	}
}

- (void)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore didLoadChildren:(NSArray *)children
{
	Class modelClass = (arrayEditorStore.modelClass);
	if ([modelClass isEqual:[GLACollection class]]) {
		[(self.collectionUUIDMap) addObjectsReplacing:children];
	}
}

- (void)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore didAddChildren:(NSArray *)addedChildren
{
	Class modelClass = (arrayEditorStore.modelClass);
	if ([modelClass isEqual:[GLACollection class]]) {
		[(self.collectionUUIDMap) addObjectsReplacing:addedChildren];
	}
}

- (void)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore didRemoveChildren:(NSArray *)removedChildren
{
	Class modelClass = (arrayEditorStore.modelClass);
	if ([modelClass isEqual:[GLACollection class]]) {
		[(self.collectionUUIDMap) removeObjects:removedChildren];
	}
}

- (void)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore didReplaceChildren:(NSArray *)replacedChildrenBefore with:(NSArray *)replacedChildrenAfter
{
	Class modelClass = (arrayEditorStore.modelClass);
	if ([modelClass isEqual:[GLACollection class]]) {
		[(self.collectionUUIDMap) addObjectsReplacing:replacedChildrenAfter];
	}
}

#pragma mark Status

- (dispatch_block_t)beginActionWithIdentifier:(NSString *)actionIdentifierFormat, ... NS_FORMAT_FUNCTION(1,2)
{
	NSDate *nowDate = [NSDate date];
	
	va_list args;
	va_start(args, actionIdentifierFormat);
	NSString *actionIdentifier = [[NSString alloc] initWithFormat:actionIdentifierFormat arguments:args];
	va_end(args);
	
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		if (!(store.actionsThatAreRunning)) {
			(store.actionsThatAreRunning) = [NSMutableSet new];
			(store.actionsToBeginTime) = [NSMutableDictionary new];
			(store.actionsToEndTime) = [NSMutableDictionary new];
		}
		
		[(store.actionsThatAreRunning) addObject:actionIdentifier];
		(store.actionsToBeginTime)[actionIdentifier] = nowDate;
	}];
	
	return ^ {
		NSDate *nowDate = [NSDate date];
		
		[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			[(store.actionsThatAreRunning) removeObject:actionIdentifier];
			(store.actionsToEndTime)[actionIdentifier] = nowDate;
		}];
	};
}

- (NSTimeInterval)durationOfLastRunOfActionWithIdentifier:(NSString *)actionIdentifier
{
	NSDate *beginDate = (self.actionsToBeginTime)[actionIdentifier];
	NSDate *endDate = (self.actionsToEndTime)[actionIdentifier];
	
	return [endDate timeIntervalSinceDate:beginDate];
}

- (NSString *)statusOfActions:(NSArray *)actionIdentifiers
{
	NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
	(numberFormatter.minimumFractionDigits) = 3;
	(numberFormatter.maximumFractionDigits) = 3;
	
	NSMutableArray *lines = [NSMutableArray array];
	for (NSString *actionIdentifier in actionIdentifiers) {
		NSTimeInterval duration = [self durationOfLastRunOfActionWithIdentifier:actionIdentifier];
		NSString *statusForAction = [NSString localizedStringWithFormat:@"%@s: %@", [numberFormatter stringFromNumber:@(duration)], actionIdentifier];
		[lines addObject:statusForAction];
	}
	
	return [lines componentsJoinedByString:@"\n"];
}

- (NSString *)statusOfCurrentActivity
{
	if (!(self.actionsThatAreRunning)) {
		return @"No activity yet";
	}
	
	return [self statusOfActions:[(self.actionsThatAreRunning) allObjects]];
}

- (NSString *)statusOfCompletedActivity
{
	if (!(self.actionsThatAreRunning)) {
		return @"Nothing completed yet";
	}
	
	return [self statusOfActions:[(self.actionsToEndTime) allKeys]];
}

@end


NSString *GLAProjectManagerAllProjectsDidChangeNotification = @"GLAProjectManagerAllProjectsDidChangeNotification";
NSString *GLAProjectManagerPlannedProjectsDidChangeNotification = @"GLAProjectManagerPlannedProjectsDidChangeNotification";
NSString *GLAProjectManagerNowProjectDidChangeNotification = @"GLAProjectManagerNowProjectDidChangeNotification";

NSString *GLAProjectCollectionsDidChangeNotification = @"GLAProjectCollectionsDidChangeNotification";
//NSString *GLAProjectManagerProjectRemindersDidChangeNotification = @"GLAProjectManagerProjectRemindersDidChangeNotification";

NSString *GLAProjectHighlightsDidChangeNotification = @"GLAProjectHighlightsDidChangeNotification";

NSString *GLACollectionDidChangeNotification = @"GLACollectionDidChangeNotification";
NSString *GLACollectionFilesListDidChangeNotification = @"GLACollectionFilesListDidChangeNotification";
