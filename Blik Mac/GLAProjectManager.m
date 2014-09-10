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

@property(readonly, nonatomic) NSArray *allProjectsSortedByDateCreatedNewestToOldest;
@property(readonly, nonatomic) NSArray *plannedProjectsSortedByDateNextPlanned;
@property(readonly, nonatomic) GLAProject *nowProject;

#pragma mark Editing

- (void)addProjects:(NSArray *)projects;

#pragma mark Saving

- (void)requestSaveAllProjects;
//- (void)requestSavePlannedProjects;
- (void)requestSaveNowProject;

@end


NSString *GLAProjectManagerJSONAllProjectsKey = @"allProjects";
NSString *GLAProjectManagerJSONNowProjectKey = @"nowProject";


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

- (void)allProjectsDidLoad;
- (void)plannedProjectsDidLoad;
- (void)nowProjectDidLoad;

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
	[(self.store) requestAllProjects];
}

- (NSArray *)allProjectsSortedByDateCreatedNewestToOldest
{
	return (self.store.allProjectsSortedByDateCreatedNewestToOldest);
}

- (void)requestNowProject
{
	[(self.store) requestNowProject];
}

- (GLAProject *)nowProject
{
	return (self.store.nowProject);
}


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

- (void)useAllProjects:(void (^)(NSArray *))allProjectsReceiver
{
	[(self.receivingOperationQueue) addOperationWithBlock:^{
		allProjectsReceiver([self allProjectsDummyContent]);
	}];
}

- (void)usePlannedProjects:(void (^)(NSArray *))plannedProjectsReceiver
{
	[(self.receivingOperationQueue) addOperationWithBlock:^{
		plannedProjectsReceiver([self plannedProjectsDummyContent]);
	}];
}

- (void)useNowProject:(void (^)(GLAProject *))nowProjectReceiver
{
	[(self.receivingOperationQueue) addOperationWithBlock:^{
		if (!(self.nowProject)) {
			(self.nowProject) = [self allProjectsDummyContent][0];
		}
		nowProjectReceiver(self.nowProject);
	}];
}

- (void)changeNowProject:(GLAProject *)project
{
	(self.nowProject) = project;
	
	[self nowProjectDidLoad];
	
	[(self.store) requestSaveNowProject];
}

- (GLAProject *)createNewProjectWithName:(NSString *)name
{
	GLAProject *project = [[GLAProject alloc] initWithUUID:nil name:name dateCreated:nil];
	
	[(self.store) addProjects:@[project]];
	
	return project;
}

- (void)allProjectsDidLoad
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerAllProjectsDidChangeNotification object:self];
}

- (void)plannedProjectsDidLoad
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerPlannedProjectsDidChangeNotification object:self];
}

- (void)nowProjectDidLoad
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerNowProjectDidChangeNotification object:self];
}

#pragma mark Saving and Loading

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

@end


#pragma mark -


@interface GLAProjectManagerStore ()

@property(readwrite, nonatomic) NSArray *allProjectsSortedByDateCreatedNewestToOldest;
@property(readwrite, nonatomic) NSArray *plannedProjectsSortedByDateNextPlanned;
@property(readwrite, nonatomic) GLAProject *nowProject;

@property(readonly, nonatomic) NSURL *allProjectsJSONFileURL;
@property(readonly, nonatomic) NSURL *nowProjectJSONFileURL;

@property(nonatomic) BOOL needsToLoadAllProjects;
@property(nonatomic) BOOL needsToLoadPlannedProjects;
@property(nonatomic) BOOL needsToLoadNowProject;

- (void)loadAllProjects;
- (void)loadPlannedProjects;
- (void)loadNowProject;

@property(nonatomic) BOOL needsToSaveAllProjects;
@property(nonatomic) BOOL needsToSavePlannedProjects;
@property(nonatomic) BOOL needsToSaveNowProject;

- (void)writeAllProjects;
- (void)writePlannedProjects;
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

- (NSURL *)version1DirectoryURL
{
	GLAProjectManager *projectManager = (self.projectManager);
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	NSURL *directoryURL = [fm URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
	
	if (!directoryURL) {
		[projectManager handleError:error];
		return nil;
	}
	
	NSString *appBundleID = [[NSBundle mainBundle] bundleIdentifier];
	directoryURL = [directoryURL URLByAppendingPathComponent:appBundleID isDirectory:YES];
	directoryURL = [directoryURL URLByAppendingPathComponent:@"v1" isDirectory:YES];
	
	BOOL directorySuccess = [fm createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
	if (!directorySuccess) {
		[projectManager handleError:error];
		return nil;
	}
	
	return directoryURL;
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
	
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		(store.allProjectsSortedByDateCreatedNewestToOldest) = allProjectsSorted;
		[projectManager allProjectsDidLoad];
		
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
	
	(self.needsToLoadNowProject) = YES;
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[store loadNowProject];
	}];
}

- (void)loadNowProject
{NSLog(@"loadNowProject");
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
		[projectManager nowProjectDidLoad];
		
		(self.needsToLoadNowProject) = NO;
	}];
}

#pragma mark - Editing

- (void)addProjects:(NSArray *)projects
{
	NSArray *allProjectsBefore = (self.allProjectsSortedByDateCreatedNewestToOldest);
	
	[self runInBackground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		NSArray *allProjects = [allProjectsBefore arrayByAddingObjectsFromArray:projects];
		
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
		@{
		  GLAProjectManagerJSONNowProjectKey: JSONProject
		  };
		
		[store writeJSONDictionary:JSONDictionary toFileURL:fileURL];
		
		[store runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			(store.needsToSaveAllProjects) = NO;
		}];
	}];
}

@end


NSString *GLAProjectManagerAllProjectsDidChangeNotification = @"GLAProjectManagerAllProjectsDidChangeNotification";
NSString *GLAProjectManagerPlannedProjectsDidChangeNotification = @"GLAProjectManagerPlannedProjectsDidChangeNotification";
NSString *GLAProjectManagerNowProjectDidChangeNotification = @"GLAProjectManagerNowProjectDidChangeNotification";

NSString *GLAProjectManagerProjectCollectionsDidChangeNotification = @"GLAProjectManagerProjectCollectionsDidChangeNotification";
NSString *GLAProjectManagerProjectRemindersDidChangeNotification = @"GLAProjectManagerProjectRemindersDidChangeNotification";
NSString *GLAProjectManagerNotificationProjectKey = @"GLAProjectManagerNotificationProjectKey";
