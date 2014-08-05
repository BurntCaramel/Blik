//
//  GLAProjectManager.m
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAProjectManager.h"


@interface GLAProjectManager ()

@property(nonatomic) NSOperationQueue *backgroundOperationQueue;
@property(nonatomic) NSBlockOperation *operationToFetchContent;

@property(nonatomic) NSBlockOperation *operationToFetchAllProjects;
@property(nonatomic) NSArray *allProjects;

@property(nonatomic) NSBlockOperation *operationToFetchPlannedProjects;
@property(nonatomic) NSArray *plannedProjects;

@property(nonatomic) GLAProject *nowProject;

//- (void)connectCollections:(NSArray *)collections withProjects:(NSArray *)projects;
//- (void)connectReminders:(NSArray *)collections withProjects:(NSArray *)projects;

//- (void)scheduleSavingProjects;
//- (void)processProjectsNeedingSaving;

@end

@implementation GLAProjectManager

- (instancetype)init
{
    self = [super init];
    if (self) {
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

- (NSOperation *)operationToFetchContentSetUpIfNeeded
{
	if (!(self.operationToFetchContent)) {
		__weak GLAProjectManager *weakSelf = self;
		NSBlockOperation *operationToFetchContent = [NSBlockOperation blockOperationWithBlock:^{
			GLAProjectManager *self = weakSelf;
			
			
		}];
		
		(operationToFetchContent.queuePriority) = NSOperationQueuePriorityHigh;
		[(self.backgroundOperationQueue) addOperation:operationToFetchContent];
		
		(self.operationToFetchContent) = operationToFetchContent;
	}
	
	return (self.operationToFetchContent);
}

- (void)useAllProjects:(void (^)(NSArray *))allProjectsReceiver
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		allProjectsReceiver([self allProjectsDummyContent]);
	}];
}

- (void)usePlannedProjects:(void (^)(NSArray *))plannedProjectsReceiver
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		plannedProjectsReceiver([self plannedProjectsDummyContent]);
	}];
}

- (void)useNowProject:(void (^)(GLAProject *))nowProjectReceiver
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		if (!(self.nowProject)) {
			(self.nowProject) = [self allProjectsDummyContent][0];
		}
		nowProjectReceiver(self.nowProject);
	}];
}

- (void)changeNowProject:(GLAProject *)project
{
	(self.nowProject) = project;
}

#pragma mark

- (GLAProject *)dummyProjectWithName:(NSString *)name
{
	GLAProject *project = [GLAProject new];
	
	(project.name) = name;
	
	return project;
}

- (NSArray *)allProjectsDummyContent
{
	return @[
			 [self dummyProjectWithName:@"Project With Big Long Name That Goes On"],
			 [self dummyProjectWithName:@"Eat a thousand muffins in one day"],
			 [self dummyProjectWithName:@"Another, yet another project"],
			 [self dummyProjectWithName:@"The one that just won’t die"],
			 [self dummyProjectWithName:@"Could this be my favourite project ever?"],
			 [self dummyProjectWithName:@"Freelance project #82"]
			 ];
}

- (NSArray *)plannedProjectsDummyContent
{
	return @[
			 [self dummyProjectWithName:@"Eat a thousand muffins in one day"],
			 [self dummyProjectWithName:@"Another, yet another project"],
			 [self dummyProjectWithName:@"The one that just won’t die"],
			 [self dummyProjectWithName:@"Could this be my favourite project ever?"],
			 [self dummyProjectWithName:@"Freelance project #82"]
			 ];
}

@end
