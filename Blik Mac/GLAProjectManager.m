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
#import "GLACollectionFilesListContent.h"
#import "GLAArrayEditor.h"


@interface GLAProjectManagerStore : NSObject

- (instancetype)initWithProjectManager:(GLAProjectManager *)projectManager;

@property(weak, nonatomic) GLAProjectManager *projectManager;

@property(readonly, nonatomic) NSOperationQueue *receivingOperationQueue;
@property(nonatomic) NSOperationQueue *backgroundOperationQueue;

@property(readonly, nonatomic) NSURL *version1DirectoryURL;


#pragma mark Loading

- (void)requestAllProjects;
//- (void)requestPlannedProjects;
- (void)requestNowProject;
- (void)requestCollectionsForProject:(GLAProject *)project;

@property(readonly, nonatomic) NSArray *allProjectsSortedByDateCreatedNewestToOldest;
@property(readonly, nonatomic) NSArray *plannedProjectsSortedByDateNextPlanned;
@property(readonly, nonatomic) GLAProject *nowProject;

- (GLAArrayEditor *)collectionEditorForProject:(GLAProject *)project;
- (NSArray *)copyCollectionsForProject:(GLAProject *)project;

//- (NSSet *)loadedProjectUUIDsContainingCollection:(GLACollection *)collection;

#pragma mark Editing

- (void)addProjects:(NSArray *)projects;

#pragma mark Saving

- (void)requestSaveAllProjects;
//- (void)requestSavePlannedProjects;
- (void)requestSaveNowProject;
- (void)requestSaveCollectionsForProject:(GLAProject *)project;

@end


NSString *GLAProjectManagerJSONAllProjectsKey = @"allProjects";
NSString *GLAProjectManagerJSONNowProjectKey = @"nowProject";
NSString *GLAProjectManagerJSONCollectionsListKey = @"collectionsList";


@interface GLAProjectManager ()

@property(nonatomic) GLAProjectManagerStore *store;

@property(nonatomic) NSOperationQueue *backgroundOperationQueue;
@property(nonatomic) NSBlockOperation *operationToFetchContent;

@property(nonatomic) NSBlockOperation *operationToFetchAllProjects;
@property(nonatomic) NSArray *allProjects;

@property(nonatomic) NSBlockOperation *operationToFetchPlannedProjects;
@property(nonatomic) NSArray *plannedProjects;

@property(nonatomic) GLAProject *nowProject;


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
		_backgroundOperationQueue = [NSOperationQueue new];
		(_backgroundOperationQueue.maxConcurrentOperationCount) = 1;
		
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
		// TODO something a bit more elegant?
		[NSApp presentError:error];
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

#pragma mark -

- (NSOperation *)operationToFetchContentSetUpIfNeeded
{
	if (!(self.operationToFetchContent)) {
		__weak GLAProjectManager *weakSelf = self;
		NSBlockOperation *operationToFetchContent = [NSBlockOperation blockOperationWithBlock:^{
			GLAProjectManager *self = weakSelf;
			
			[self loadAllProjects];
		}];
		
		(operationToFetchContent.queuePriority) = NSOperationQueuePriorityHigh;
		[(self.backgroundOperationQueue) addOperation:operationToFetchContent];
		
		(self.operationToFetchContent) = operationToFetchContent;
	}
	
	return (self.operationToFetchContent);
}

#pragma mark Editing

- (void)changeNowProject:(GLAProject *)project
{
	(self.nowProject) = project;
	
	[self nowProjectDidChange];
	
	[(self.store) requestSaveNowProject];
}

- (GLAProject *)createNewProjectWithName:(NSString *)name
{
	GLAProject *project = [[GLAProject alloc] initWithUUID:nil name:name dateCreated:nil];
	
	GLAProjectManagerStore *store = (self.store);
	[store addProjects:@[project]];
	
	[store requestSaveAllProjects];
	
	return project;
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

- (GLACollection *)createNewCollectionWithName:(NSString *)name content:(GLACollectionContent *)content inProject:(GLAProject *)project
{
	GLACollection *collection = [GLACollection newWithCreationFromEditing:^(id<GLACollectionEditing> collectionEditor) {
		(collectionEditor.name) = name;
		(collectionEditor.content) = content;
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
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerNowProjectDidChangeNotification object:self];
}

- (void)collectionListForProjectDidChange:(GLAProject *)project
{
	NSDictionary *noteInfo =
	@{GLAProjectManagerNotificationProjectKey: project};
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerProjectCollectionsDidChangeNotification object:self userInfo:noteInfo];
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

- (void)saveAllProjects
{
	[(self.store) requestSaveAllProjects];
}

#pragma mark Dummy

- (GLAProject *)newDummyProjectWithName:(NSString *)name
{
	GLAProject *project = [[GLAProject alloc] initWithUUID:[NSUUID UUID] name:name dateCreated:[NSDate date]];
	
	return project;
}

- (NSArray *)allProjectsDummyContent
{
	return @[
			 [self newDummyProjectWithName:@"Project With Big Long Name That Goes On"],
			 [self newDummyProjectWithName:@"Eat a thousand muffins in one day"],
			 [self newDummyProjectWithName:@"Another, yet another project"],
			 [self newDummyProjectWithName:@"The one that just won’t die"],
			 [self newDummyProjectWithName:@"Could this be my favourite project ever?"],
			 [self newDummyProjectWithName:@"Freelance project #82"]
			 ];
}

- (GLAProject *)nowProjectDummyContent
{
	return (self.allProjectsDummyContent)[0];
}

- (NSArray *)plannedProjectsDummyContent
{
	return @[
			 [self newDummyProjectWithName:@"Eat a thousand muffins in one day"],
			 [self newDummyProjectWithName:@"Another, yet another project"],
			 [self newDummyProjectWithName:@"The one that just won’t die"],
			 [self newDummyProjectWithName:@"Could this be my favourite project ever?"],
			 [self newDummyProjectWithName:@"Freelance project #82"]
			 ];
}

- (NSArray *)collectionListDummyContent
{
	GLACollectionFilesListContent *filesListContent = [GLACollectionFilesListContent new];
	
	return
	@[
	  [GLACollection dummyCollectionWithName:@"Working Files" color:[GLACollectionColor lightBlue] content:filesListContent],
	  [GLACollection dummyCollectionWithName:@"Briefs" color:[GLACollectionColor green] content:filesListContent],
	  [GLACollection dummyCollectionWithName:@"Contacts" color:[GLACollectionColor pinkyPurple] content:filesListContent],
	  [GLACollection dummyCollectionWithName:@"Apps" color:[GLACollectionColor red] content:filesListContent],
	  [GLACollection dummyCollectionWithName:@"Research" color:[GLACollectionColor yellow] content:filesListContent]
	  ];
}

@end


#pragma mark -


@interface GLAProjectManagerStore ()

@property(readwrite, nonatomic) NSArray *allProjectsSortedByDateCreatedNewestToOldest;
@property(readwrite, nonatomic) NSArray *plannedProjectsSortedByDateNextPlanned;
@property(readwrite, nonatomic) GLAProject *nowProject;

@property(nonatomic) NSMutableDictionary *projectIDsToCollectionLists;
@property(nonatomic) NSMutableDictionary *collectionIdentifiersToProjectIDSets;

@property(readonly, nonatomic) NSURL *allProjectsJSONFileURL;
@property(readonly, nonatomic) NSURL *nowProjectJSONFileURL;

@property(nonatomic) BOOL needsToLoadAllProjects;
@property(nonatomic) BOOL needsToLoadPlannedProjects;
@property(nonatomic) BOOL needsToLoadNowProject;
@property(nonatomic) NSMutableSet *projectIDsNeedingCollectionsLoaded;

- (void)loadAllProjects;
//- (void)loadPlannedProjects;
- (void)loadNowProject;

- (void)loadCollectionsForProject:(GLAProject *)project;

@property(nonatomic) BOOL needsToSaveAllProjects;
@property(nonatomic) BOOL needsToSavePlannedProjects;
@property(nonatomic) BOOL needsToSaveNowProject;
@property(nonatomic) NSMutableSet *projectIDsNeedingCollectionsSaved;

- (void)writeAllProjects;
//- (void)writePlannedProjects;
- (void)writeNowProject;

@end


@implementation GLAProjectManagerStore

- (instancetype)initWithProjectManager:(GLAProjectManager *)projectManager;
{
    self = [super init];
    if (self) {
		(self.projectManager) = projectManager;
		
		_backgroundOperationQueue = [NSOperationQueue new];
		(_backgroundOperationQueue.maxConcurrentOperationCount) = 1;
		
#if 0
		NSError *testError = [GLAModelErrors errorForMissingRequiredKey:GLAProjectManagerJSONAllProjectsKey inJSONFileAtURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
		[projectManager handleError:testError];
#endif
    }
    return self;
}

#pragma mark Queuing Work

- (NSOperationQueue *)receivingOperationQueue
{
	GLAProjectManager *projectManager = (self.projectManager);
	if (projectManager) {
		return (projectManager.receivingOperationQueue);
	}
	else {
		return nil;
	}
}

- (void)runBlock:(void (^)(GLAProjectManagerStore *store, GLAProjectManager *projectManager))block onOperationQueue:(NSOperationQueue *)queue
{
	__weak GLAProjectManagerStore *weakStore = self;
	
	[queue addOperationWithBlock:^{
		GLAProjectManagerStore *store = weakStore;
		GLAProjectManager *projectManager = (store.projectManager);
		
		block(store, projectManager);
	}];
}

- (void)runInBackground:(void (^)(GLAProjectManagerStore *store, GLAProjectManager *projectManager))block
{
	[self runBlock:block onOperationQueue:(self.backgroundOperationQueue)];
}

- (void)runInForeground:(void (^)(GLAProjectManagerStore *store, GLAProjectManager *projectManager))block
{
	[self runBlock:block onOperationQueue:(self.receivingOperationQueue)];
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

- (NSDictionary *)readJSONDictionaryFromFileURL:(NSURL *)fileURL
{
	GLAProjectManager *projectManager = (self.projectManager);
	NSError *error = nil;
	
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
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[store loadAllProjects];
	}];
}

- (void)loadAllProjects
{
	NSURL *fileURL = (self.allProjectsJSONFileURL);
	if (!fileURL) {
		return;
	}
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		NSArray *allProjects = nil;
		
		if (projectManager.shouldLoadTestProjects) {
			allProjects = (projectManager.allProjectsDummyContent);
		}
		else {
			allProjects = [store background_readAllProjectsFromJSONFileURL:fileURL];
		}
		
		if (allProjects) {
			[store background_processLoadedAllProjects:allProjects];
		}
		
	}];
}

- (NSArray *)background_readAllProjectsFromJSONFileURL:(NSURL *)fileURL
{
	GLAProjectManager *projectManager = (self.projectManager);
	NSError *error = nil;
	
	NSDictionary *JSONDictionary = [self readJSONDictionaryFromFileURL:fileURL];
	if (!JSONDictionary) {
		return nil;
	}
	
	NSArray *JSONArray = JSONDictionary[GLAProjectManagerJSONAllProjectsKey];
	if (!JSONArray) {
		error = [GLAModelErrors errorForMissingRequiredKey:GLAProjectManagerJSONAllProjectsKey inJSONFileAtURL:fileURL];
		[projectManager handleError:error];
		return nil;
	}
	
	NSArray *allProjects = [MTLJSONAdapter modelsOfClass:[GLAProject class] fromJSONArray:JSONArray error:&error];
	if (!allProjects) {
		[projectManager handleError:error];
		return nil;
	}
	
	return allProjects;
}

- (void)background_processLoadedAllProjects:(NSArray *)allProjectsUnsorted
{
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
	NSArray *allProjectsSorted = [allProjectsUnsorted sortedArrayUsingDescriptors:@[sortDescriptor]];
	
	NSLog(@"background_processLoadedAllProjects: %@", allProjectsSorted);
	
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		(store.allProjectsSortedByDateCreatedNewestToOldest) = allProjectsSorted;
		[projectManager allProjectsDidChange];
		
		(self.needsToLoadAllProjects) = NO;
	}];
}

- (void)loadPlannedProjects
{
	
}

#pragma mark Load Now Project

- (void)requestNowProject
{
	if (self.needsToLoadNowProject) {
		return;
	}
	if (self.needsToSaveNowProject) {
		return;
	}
	
	(self.needsToLoadNowProject) = YES;
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[store loadNowProject];
	}];
}

- (void)loadNowProject
{
	NSURL *fileURL = (self.nowProjectJSONFileURL);
	if (!fileURL) {
		return;
	}
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		GLAProject *project = nil;
		
		if (projectManager.shouldLoadTestProjects) {
			project = (projectManager.nowProjectDummyContent);
		}
		else {
			project = [store background_readNowProjectFromJSONFileURL:fileURL];
		}
		
		if (project) {
			[store background_processLoadedNowProject:project];
		}
	}];
}

- (GLAProject *)background_readNowProjectFromJSONFileURL:(NSURL *)fileURL
{
	GLAProjectManager *projectManager = (self.projectManager);
	NSError *error = nil;
	
	NSDictionary *JSONDictionary = [self readJSONDictionaryFromFileURL:fileURL];
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
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		(store.nowProject) = project;
		[projectManager nowProjectDidChange];
		
		(self.needsToLoadNowProject) = NO;
	}];
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
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[store loadCollectionsForProject:project];
	}];
}

- (void)loadCollectionsForProject:(GLAProject *)project
{
	NSURL *fileURL = [self collectionsListJSONFileURLForProjectID:(project.UUID)];
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		NSArray *collectionList = nil;
		
		if (projectManager.shouldLoadTestProjects) {
			collectionList = (projectManager.collectionListDummyContent);
		}
		else {
			collectionList = [store background_readCollectionListFromJSONFileURL:fileURL];
		}
		
		if (collectionList) {
			[store background_processLoadedCollectionList:collectionList forProject:project];
		}
	}];
}

- (NSArray *)background_readCollectionListFromJSONFileURL:(NSURL *)fileURL
{
	GLAProjectManager *projectManager = (self.projectManager);
	NSError *error = nil;
	
	NSDictionary *JSONDictionary = [self readJSONDictionaryFromFileURL:fileURL];
	if (!JSONDictionary) {
		return nil;
	}
	
	NSArray *JSONArray = JSONDictionary[GLAProjectManagerJSONCollectionsListKey];
	if (!JSONArray) {
		error = [GLAModelErrors errorForMissingRequiredKey:GLAProjectManagerJSONCollectionsListKey inJSONFileAtURL:fileURL];
		[projectManager handleError:error];
		return nil;
	}
	
	NSArray *collections = [MTLJSONAdapter modelsOfClass:[GLACollection class] fromJSONArray:JSONArray error:&error];
	if (!collections) {
		[projectManager handleError:error];
		return nil;
	}
	
	return collections;
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
	//projectIDsToCollectionLists
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

#pragma mark - Editing

- (void)addProjects:(NSArray *)projects
{NSLog(@"addProjects: %@", projects);
	NSArray *allProjectsBefore = [(self.allProjectsSortedByDateCreatedNewestToOldest) copy];
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		NSArray *allProjects = [allProjectsBefore arrayByAddingObjectsFromArray:projects];
		NSLog(@"NEW ALL PROJECTS %@", allProjects);
		[self background_processLoadedAllProjects:allProjects];
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
	
	// Queue so this is done after the current run loop.
	// Multiple calls to -requestSaveAllProjects will be coalsced.
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[store writeAllProjects];
	}];
}

- (void)writeAllProjects
{
	NSURL *fileURL = (self.allProjectsJSONFileURL);
	if (!fileURL) {
		return;
	}
	
	NSArray *allProjectsSorted = (self.allProjectsSortedByDateCreatedNewestToOldest);
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		NSArray *JSONArray = [MTLJSONAdapter JSONArrayFromModels:allProjectsSorted];
		
		NSDictionary *JSONDictionary =
		@{
		  GLAProjectManagerJSONAllProjectsKey: JSONArray
		  };
		
		[store writeJSONDictionary:JSONDictionary toFileURL:fileURL];
		
		[store runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			(store.needsToSaveAllProjects) = NO;
		}];
	}];
}

#pragma mark Save Now Project

- (void)requestSaveNowProject
{
	if (self.needsToSaveNowProject) {
		return;
	}
	
	(self.needsToSaveNowProject) = YES;
	
	// Queue so this is done after the current run loop.
	// Multiple calls to -requestSaveNowProject will be coalsced.
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[store writeNowProject];
	}];
}

- (void)writeNowProject
{
	NSURL *fileURL = (self.nowProjectJSONFileURL);
	if (!fileURL) {
		return;
	}
	
	GLAProject *project = (self.nowProject);
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		NSDictionary *JSONProject = [MTLJSONAdapter JSONDictionaryFromModel:project];
		
		NSDictionary *JSONDictionary =
		@{GLAProjectManagerJSONNowProjectKey: JSONProject};
		
		[store writeJSONDictionary:JSONDictionary toFileURL:fileURL];
		
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
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[store writeCollectionsForProject:project];
	}];
}

- (void)writeCollectionsForProject:(GLAProject *)project
{
	NSURL *fileURL = [self collectionsListJSONFileURLForProjectID:(project.UUID)];
	
	NSArray *collectionList = [self copyCollectionsForProject:project];
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		NSArray *JSONArray = [MTLJSONAdapter JSONArrayFromModels:collectionList];
		
		NSDictionary *JSONDictionary =
		@{
		  GLAProjectManagerJSONCollectionsListKey: JSONArray
		  };
		
		[store writeJSONDictionary:JSONDictionary toFileURL:fileURL];
		
		[store runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			[(store.projectIDsNeedingCollectionsSaved) removeObject:(project.UUID)];
		}];
	}];
	
}

#pragma mark Save Collection Content

@end


NSString *GLAProjectManagerAllProjectsDidChangeNotification = @"GLAProjectManagerAllProjectsDidChangeNotification";
NSString *GLAProjectManagerPlannedProjectsDidChangeNotification = @"GLAProjectManagerPlannedProjectsDidChangeNotification";
NSString *GLAProjectManagerNowProjectDidChangeNotification = @"GLAProjectManagerNowProjectDidChangeNotification";

NSString *GLAProjectManagerProjectCollectionsDidChangeNotification = @"GLAProjectManagerProjectCollectionsDidChangeNotification";
NSString *GLAProjectManagerProjectRemindersDidChangeNotification = @"GLAProjectManagerProjectRemindersDidChangeNotification";
NSString *GLAProjectManagerNotificationProjectKey = @"GLAProjectManagerNotificationProjectKey";
