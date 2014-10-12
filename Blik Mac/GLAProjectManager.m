//
//  GLAProjectManager.m
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAProjectManager.h"
#import "Mantle/Mantle.h"
#import "GLAModelErrors.h"
#import "GLACollection.h"
#import "GLACollectionColor.h"
#import "GLACollectedFile.h"
#import "GLAArrayEditor.h"


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

#pragma mark Loading

- (void)requestAllProjects;
- (void)requestNowProject;
- (void)requestCollectionsForProject:(GLAProject *)project;
- (void)requestFilesListForCollection:(GLACollection *)filesListCollection;

@property(readonly, copy, nonatomic) NSArray *allProjectsSortedByDateCreatedNewestToOldest;
//@property(readonly, copy, nonatomic) NSArray *plannedProjects;

- (GLAProject *)projectWithUUID:(NSUUID *)projectUUID;

@property(readonly, copy, nonatomic) GLAProject *nowProject;

- (GLAArrayEditor *)collectionEditorForProject:(GLAProject *)project;
- (NSArray *)copyCollectionsForProject:(GLAProject *)project;

- (GLAArrayEditor *)filesListEditorForCollection:(GLACollection *)filesListCollection;
- (NSArray *)copyFilesListForCollection:(GLACollection *)filesListCollection;

//- (NSSet *)loadedProjectUUIDsContainingCollection:(GLACollection *)collection;

#pragma mark Editing

- (void)addProjects:(NSArray *)projects;

- (GLAProject *)editProject:(GLAProject *)project usingBlock:(void(^)(id<GLAProjectEditing>projectEditor))editBlock;

- (void)changeNowProject:(GLAProject *)project;

#pragma mark Saving

- (void)requestSaveAllProjects;
//- (void)requestSavePlannedProjects;
- (void)requestSaveNowProject;
- (void)requestSaveCollectionsForProject:(GLAProject *)project;
- (void)requestSaveFilesListForCollection:(GLACollection *)filesListCollection;

@end


NSString *GLAProjectManagerJSONAllProjectsKey = @"allProjects";
NSString *GLAProjectManagerJSONNowProjectKey = @"nowProject";
NSString *GLAProjectManagerJSONCollectionsListKey = @"collectionsList";
NSString *GLAProjectManagerJSONFilesListKey = @"filesList";


@interface GLAProjectManager ()

@property(nonatomic) GLAProjectManagerStore *store;

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

- (void)requestAllProjects
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
	return [(self.store) projectWithUUID:projectUUID];
}

- (void)requestNowProject
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

- (void)requestCollectionsForProject:(GLAProject *)project
{
	[(self.store) requestCollectionsForProject:project];
}

- (NSArray *)copyCollectionsForProject:(GLAProject *)project
{
	return [(self.store) copyCollectionsForProject:project];
}

- (void)requestFilesListForCollection:(GLACollection *)filesListCollection
{
	[(self.store) requestFilesListForCollection:filesListCollection];
}

- (NSArray *)copyFilesListForCollection:(GLACollection *)filesListCollection
{
	return [(self.store) copyFilesListForCollection:filesListCollection];
}

#pragma mark Editing

- (void)changeNowProject:(GLAProject *)project
{NSLog(@"CHANGE NOW PROJECT %@", project);
	GLAProjectManagerStore *store = (self.store);
	
	[store changeNowProject:project];
	[self nowProjectDidChange];
	
	[store requestSaveNowProject];
}

- (GLAProject *)createNewProjectWithName:(NSString *)name
{
	GLAProject *project = [[GLAProject alloc] initWithUUID:nil name:name dateCreated:nil];
	
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

- (BOOL)editProjectCollections:(GLAProject *)project usingBlock:(void (^)(id<GLAArrayEditing> collectionsEditor))block
{
	GLAProjectManagerStore *store = (self.store);
	
	GLAArrayEditor *arrayEditor = [store collectionEditorForProject:project];
	if (!arrayEditor) {
		return NO;
	}
	
	// Call the passed block to make changes.
	block(arrayEditor);
	
	[self collectionListForProjectDidChange:project];
	[store requestSaveCollectionsForProject:project];
	
	return YES;
}

- (GLACollection *)createNewCollectionWithName:(NSString *)name type:(NSString *)type color:(GLACollectionColor *)color inProject:(GLAProject *)project
{
	NSAssert(project != nil, @"Passed project must not be nil.");
	
	GLACollection *collection = [GLACollection newWithType:type creatingFromEditing:^(id<GLACollectionEditing> collectionEditor) {
		(collectionEditor.name) = name;
		(collectionEditor.color) = color;
	}];
	
	[self editProjectCollections:project usingBlock:^(id<GLAArrayEditing> collectionListEditor) {
		[collectionListEditor addChildren:@[collection]];
	}];
	
	return collection;
}

- (GLACollection *)editCollection:(GLACollection *)collection inProject:(GLAProject *)project usingBlock:(void(^)(id<GLACollectionEditing>collectionEditor))editBlock
{
	GLACollection *changedCollection = [collection copyWithChangesFromEditing:editBlock];
	
	[self editProjectCollections:project usingBlock:^(id<GLAArrayEditing> collectionListEditor) {
		[collectionListEditor replaceChildWithValueForKey:@"UUID" equalToValue:(collection.UUID) withObject:changedCollection];
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

- (BOOL)editFilesListOfCollection:(GLACollection *)filesListCollection usingBlock:(void (^)(id<GLAArrayEditing> filesListEditor))block
{
	GLAProjectManagerStore *store = (self.store);
	
	GLAArrayEditor *arrayEditor = [store filesListEditorForCollection:filesListCollection];
	if (!arrayEditor) {
		return NO;
	}
	
	// Call the passed block to make changes.
	block(arrayEditor);
	
	[self filesListForCollectionDidChange:filesListCollection];
	[store requestSaveFilesListForCollection:filesListCollection];
	
	return YES;
}

#pragma mark Notifications

- (void)allProjectsDidChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerAllProjectsDidChangeNotification object:self];
}

- (void)plannedProjectsDidChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerPlannedProjectsDidChangeNotification object:self];
}

- (void)nowProjectDidChange
{NSLog(@"PM nowProjectDidChange %@", (self.nowProject));
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerNowProjectDidChangeNotification object:self];
}

- (void)collectionListForProjectDidChange:(GLAProject *)project
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectCollectionsDidChangeNotification object:project];
}

- (void)filesListForCollectionDidChange:(GLACollection *)collection
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLACollectionFilesListDidChangeNotification object:collection];
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
	GLAProject *project = [[GLAProject alloc] initWithUUID:[NSUUID UUID] name:name dateCreated:[NSDate date]];
	
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
	  [GLACollection dummyCollectionWithName:@"Working Files" color:[GLACollectionColor lightBlue] type:GLACollectionTypeFilesList],
	  [GLACollection dummyCollectionWithName:@"Briefs" color:[GLACollectionColor green] type:GLACollectionTypeFilesList],
	  [GLACollection dummyCollectionWithName:@"Contacts" color:[GLACollectionColor pinkyPurple] type:GLACollectionTypeFilesList],
	  [GLACollection dummyCollectionWithName:@"Apps" color:[GLACollectionColor red] type:GLACollectionTypeFilesList],
	  [GLACollection dummyCollectionWithName:@"Research" color:[GLACollectionColor yellow] type:GLACollectionTypeFilesList]
	  ];
}

@end


#pragma mark -


@implementation GLAProjectManagerStoreState

@end


#pragma mark -

@interface GLAProjectManagerStore ()

//@property(readwrite, nonatomic) NSArray *plannedProjectsSortedByDateNextPlanned;

@property(readonly, nonatomic) NSOperationQueue *foregroundOperationQueue;
@property(nonatomic) NSOperationQueue *backgroundOperationQueue;

@property(readonly, nonatomic) GLAProjectManagerStoreState *foregroundState;
@property(readonly, nonatomic) GLAProjectManagerStoreState *backgroundState;

@property(nonatomic) NSMutableDictionary *projectIDsToCollectionLists;

@property(nonatomic) NSMutableDictionary *collectionIDsToFilesLists;
//@property(nonatomic) NSMutableDictionary *collectionIdentifiersToProjectIDSets;

@property(readonly, nonatomic) NSURL *allProjectsJSONFileURL;
@property(readonly, nonatomic) NSURL *nowProjectJSONFileURL;

@property(nonatomic) BOOL needsToLoadAllProjects;
@property(nonatomic) BOOL needsToLoadPlannedProjects;
@property(nonatomic) BOOL needsToLoadNowProject;
@property(nonatomic) NSMutableSet *projectIDsNeedingCollectionsLoaded;
@property(nonatomic) NSMutableSet *collectionIDsNeedingFilesListsLoaded;

- (void)loadAllProjects:(dispatch_block_t)completionBlock;
//- (void)loadPlannedProjects;
- (void)loadNowProject:(dispatch_block_t)completionBlock;

- (void)loadCollectionsForProject:(GLAProject *)project completionBlock:(dispatch_block_t)completionBlock;

@property(nonatomic) BOOL needsToSaveAllProjects;
@property(nonatomic) BOOL needsToSavePlannedProjects;
@property(nonatomic) BOOL needsToSaveNowProject;
@property(nonatomic) NSMutableSet *projectIDsNeedingCollectionsSaved;
@property(nonatomic) NSMutableSet *collectionIDsNeedingFilesListsSaved;

- (void)writeAllProjects:(dispatch_block_t)completionBlock;
//- (void)writePlannedProjects;
- (void)writeNowProject:(dispatch_block_t)completionBlock;

- (void)writeCollectionsForProject:(GLAProject *)project completionBlock:(dispatch_block_t)completionBlock;

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

- (NSURL *)collectionsListJSONFileURLForProjectID:(NSUUID *)projectUUID
{
	NSString *projectDirectoryName = [NSString stringWithFormat:@"project-%@", (projectUUID.UUIDString)];
	NSURL *directoryURL = [self version1DirectoryURLWithInnerDirectoryComponents:@[projectDirectoryName]];
	
	NSURL *fileURL = [directoryURL URLByAppendingPathComponent:@"collections-list.json"];
	
	return fileURL;
}

- (NSURL *)filesListJSONFileURLForCollectionID:(NSUUID *)collectionUUID
{
	NSString *collectionDirectoryName = [NSString stringWithFormat:@"collection-%@", (collectionUUID.UUIDString)];
	NSURL *directoryURL = [self version1DirectoryURLWithInnerDirectoryComponents:@[collectionDirectoryName]];
	
	NSURL *fileURL = [directoryURL URLByAppendingPathComponent:@"files-list.json"];
	
	return fileURL;
}

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
	
	NSLog(@"background_processLoadedAllProjects: %@", allProjectsSorted);
	
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
{NSLog(@"matchNowProjectFromAllProjectsUsingUUID");
	GLAProjectManagerStoreState *backgroundState = (self.backgroundState);
	NSArray *allProjects = (backgroundState.allProjectsSortedByDateCreatedNewestToOldest);
	if (!allProjects) {
		NSLog(@"NO ALL PROJECTS");
		[self requestAllProjects];
		return;
	}
	
	NSUUID *nowProjectUUID = (backgroundState.nowProjectUUID);
	if (!nowProjectUUID) {
		NSLog(@"NO NOW PROJECT");
		return;
	}
	
	NSDictionary *allProjectUUIDsToProjects = (backgroundState.allProjectUUIDsToProjects);
	GLAProject *nowProject = allProjectUUIDsToProjects[nowProjectUUID];
	
	NSAssert(nowProject != nil, @"Could not find project to match now project's UUID %@", nowProjectUUID);
	
	(self.backgroundState.nowProject) = nowProject;
	
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		NSLog(@"GOT NOW PROJECT");
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

- (void)requestCollectionsForProject:(GLAProject *)project
{
	if ((self.projectIDsNeedingCollectionsLoaded) == nil) {
		(self.projectIDsNeedingCollectionsLoaded) = [NSMutableSet set];
	}
	
	NSUUID *projectUUID = (project.UUID);
	if ([(self.projectIDsNeedingCollectionsLoaded) containsObject:projectUUID]) {
		return;
	}
	
	[(self.projectIDsNeedingCollectionsLoaded) addObject:projectUUID];
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Load Collections for Project \"%@\"", (project.name)];
	
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[store loadCollectionsForProject:project completionBlock:actionTracker];
	}];
}

- (void)loadCollectionsForProject:(GLAProject *)project completionBlock:(dispatch_block_t)completionBlock
{
	NSURL *fileURL = [self collectionsListJSONFileURLForProjectID:(project.UUID)];
	
	BOOL loadTestContent = (self.shouldLoadTestProjects);
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState) {
		NSArray *collectionList = nil;
		
		if (loadTestContent) {
			collectionList = [GLAProjectManager collectionListDummyContent];
		}
		else {
			collectionList = [store background_readCollectionListFromJSONFileURL:fileURL];
		}
		
		if (!collectionList) {
			collectionList = @[];
		}
		
		[store background_processLoadedCollectionList:collectionList forProject:project];
		
		completionBlock();
	}];
}

- (NSArray *)background_readCollectionListFromJSONFileURL:(NSURL *)fileURL
{
	return [self background_readModelsOfClass:[GLACollection class] atDictionaryKey:GLAProjectManagerJSONCollectionsListKey fromJSONFileURL:fileURL];
}

- (void)background_processLoadedCollectionList:(NSArray *)collectionList forProject:(GLAProject *)project
{
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		NSMutableDictionary *projectIDsToCollectionLists = (self.projectIDsToCollectionLists);
		if (!projectIDsToCollectionLists) {
			projectIDsToCollectionLists = [NSMutableDictionary new];
			(self.projectIDsToCollectionLists) = projectIDsToCollectionLists;
		}
		
		GLAArrayEditor *collectionEditor = [[GLAArrayEditor alloc] initWithObjects:collectionList];
		projectIDsToCollectionLists[project.UUID] = collectionEditor;
		
		[projectManager collectionListForProjectDidChange:project];
		
		[(self.projectIDsNeedingCollectionsLoaded) removeObject:(project.UUID)];
	}];
}

- (GLAArrayEditor *)collectionEditorForProject:(GLAProject *)project
{
	NSMutableDictionary *projectIDsToCollectionLists = (self.projectIDsToCollectionLists);
	if (projectIDsToCollectionLists) {
		GLAArrayEditor *collectionEditor = projectIDsToCollectionLists[project.UUID];
		return collectionEditor;
	}
	else {
		return nil;
	}
}

- (NSArray *)copyCollectionsForProject:(GLAProject *)project
{
	GLAArrayEditor *collectionEditor = [self collectionEditorForProject:project];
	if (collectionEditor) {
		return [collectionEditor copyChildren];
	}
	else {
		return nil;
	}
}

#pragma mark Load Files List

- (void)requestFilesListForCollection:(GLACollection *)filesListCollection
{
	NSAssert([(filesListCollection.type) isEqualToString:GLACollectionTypeFilesList], @"Collection must be of files list type.");
	
	if ((self.collectionIDsNeedingFilesListsLoaded) == nil) {
		(self.collectionIDsNeedingFilesListsLoaded) = [NSMutableSet set];
	}
	
	NSUUID *collectionUUID = (filesListCollection.UUID);
	if ([(self.collectionIDsNeedingFilesListsLoaded) containsObject:collectionUUID]) {
		return;
	}
	
	[(self.collectionIDsNeedingFilesListsLoaded) addObject:collectionUUID];
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Load Files List for Collection \"%@\"", (filesListCollection.name)];
	
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[store loadFilesListForCollections:filesListCollection completionBlock:actionTracker];
	}];
}

- (void)loadFilesListForCollections:(GLACollection *)collection completionBlock:(dispatch_block_t)completionBlock
{
	NSURL *fileURL = [self filesListJSONFileURLForCollectionID:(collection.UUID)];
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState) {
		NSArray *filesList = [store background_readFilesListFromJSONFileURL:fileURL];
		
		if (!filesList) {
			filesList = @[];
		}
		
		[store background_processLoadedFilesList:filesList forCollection:collection];
		
		completionBlock();
	}];
}

- (NSArray *)background_readFilesListFromJSONFileURL:(NSURL *)fileURL
{
	return [self background_readModelsOfClass:[GLACollectedFile class] atDictionaryKey:GLAProjectManagerJSONFilesListKey fromJSONFileURL:fileURL];
}

- (void)background_processLoadedFilesList:(NSArray *)filesListArray forCollection:(GLACollection *)collection
{
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		NSMutableDictionary *collectionIDsToFilesLists = (self.collectionIDsToFilesLists);
		if (!collectionIDsToFilesLists) {
			collectionIDsToFilesLists = [NSMutableDictionary new];
			(self.collectionIDsToFilesLists) = collectionIDsToFilesLists;
		}
		
		GLAArrayEditor *filesListEditor = [[GLAArrayEditor alloc] initWithObjects:filesListArray];
		collectionIDsToFilesLists[collection.UUID] = filesListEditor;
		
		[projectManager filesListForCollectionDidChange:collection];
		
		[(self.collectionIDsNeedingFilesListsLoaded) removeObject:(collection.UUID)];
	}];
}

- (GLAArrayEditor *)filesListEditorForCollection:(GLACollection *)filesListCollection
{
	NSAssert([(filesListCollection.type) isEqualToString:GLACollectionTypeFilesList], @"Collection must be of files list type.");

	NSMutableDictionary *collectionIDsToFilesLists = (self.collectionIDsToFilesLists);
	if (collectionIDsToFilesLists) {
		GLAArrayEditor *filesListEditor = collectionIDsToFilesLists[filesListCollection.UUID];
		return filesListEditor;
	}
	else {
		return nil;
	}
}

- (NSArray *)copyFilesListForCollection:(GLACollection *)filesListCollection
{
	GLAArrayEditor *filesListEditor = [self filesListEditorForCollection:filesListCollection];
	if (filesListEditor) {
		return [filesListEditor copyChildren];
	}
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
		NSLog(@"NEW ALL PROJECTS %@", allProjects);
		[store background_processLoadedAllProjects:allProjects];
		
		[store runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			NSLog(@"SAVING ADDED PROJECTS");
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
		NSLog(@"SAVING THESE PROJECTS %@", allProjectsSorted);
		
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

#pragma mark Save Project Collection List

- (void)requestSaveCollectionsForProject:(GLAProject *)project
{
	if ((self.projectIDsNeedingCollectionsSaved) == nil) {
		(self.projectIDsNeedingCollectionsSaved) = [NSMutableSet set];
	}
	
	NSUUID *projectUUID = (project.UUID);
	if ([(self.projectIDsNeedingCollectionsSaved) containsObject:projectUUID]) {
		return;
	}
	
	[(self.projectIDsNeedingCollectionsSaved) addObject:projectUUID];
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Save Collections for Project \"%@\"", (project.name)];
	[self writeCollectionsForProject:project completionBlock:actionTracker];
}

- (void)writeCollectionsForProject:(GLAProject *)project completionBlock:(dispatch_block_t)completionBlock
{
	NSURL *fileURL = [self collectionsListJSONFileURLForProjectID:(project.UUID)];
	
	NSArray *collectionList = [self copyCollectionsForProject:project];
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState) {
		NSArray *JSONArray = [MTLJSONAdapter JSONArrayFromModels:collectionList];
		
		NSDictionary *JSONDictionary =
		@{
		  GLAProjectManagerJSONCollectionsListKey: JSONArray
		  };
		
		[store writeJSONDictionary:JSONDictionary toFileURL:fileURL];
		
		completionBlock();
		
		[store runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			[(store.projectIDsNeedingCollectionsSaved) removeObject:(project.UUID)];
		}];
	}];
}

#pragma mark Save Collection Content

- (void)requestSaveFilesListForCollection:(GLACollection *)filesListCollection
{
	if ((self.collectionIDsNeedingFilesListsSaved) == nil) {
		(self.collectionIDsNeedingFilesListsSaved) = [NSMutableSet set];
	}
	
	NSUUID *collectionUUID = (filesListCollection.UUID);
	if ([(self.collectionIDsNeedingFilesListsSaved) containsObject:collectionUUID]) {
		return;
	}
	
	[(self.collectionIDsNeedingFilesListsSaved) addObject:collectionUUID];
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Save Files List for Collection \"%@\"", (filesListCollection.name)];
	[self writeFilesListForCollection:filesListCollection completionBlock:actionTracker];
}

- (void)writeFilesListForCollection:(GLACollection *)collection completionBlock:(dispatch_block_t)completionBlock
{
	NSURL *fileURL = [self filesListJSONFileURLForCollectionID:(collection.UUID)];
	
	NSArray *filesList = [self copyFilesListForCollection:collection];
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManagerStoreState *backgroundState) {
		NSArray *JSONArray = [MTLJSONAdapter JSONArrayFromModels:filesList];
		
		NSDictionary *JSONDictionary =
		@{
		  GLAProjectManagerJSONFilesListKey: JSONArray
		  };
		
		[store writeJSONDictionary:JSONDictionary toFileURL:fileURL];
		
		completionBlock();
		
		[store runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			[(store.collectionIDsNeedingFilesListsSaved) removeObject:(collection.UUID)];
		}];
	}];
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

NSString *GLACollectionFilesListDidChangeNotification = @"GLACollectionFilesListDidChangeNotification";

NSString *GLAProjectManagerNotificationProjectKey = @"GLAProjectManagerNotificationProjectKey";
NSString *GLAProjectManagerNotificationCollectionKey = @"GLAProjectManagerNotificationCollectionKey";
