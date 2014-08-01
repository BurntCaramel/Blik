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

//- (void)connectCollections:(NSArray *)collections withProjects:(NSArray *)projects;
//- (void)connectReminders:(NSArray *)collections withProjects:(NSArray *)projects;

//- (void)scheduleSavingProjects;
//- (void)processProjectsNeedingSaving;

@end

@implementation GLAProjectManager

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

@end
