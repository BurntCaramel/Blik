//
//  GLAMainSectionNavigator.m
//  Blik
//
//  Created by Patrick Smith on 11/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAMainSectionNavigator.h"
#import "GLAProjectManager.h"


@interface GLAMainSectionNavigator ()

@property(readwrite, nonatomic) GLAMainSection *currentSection;

- (void)registerForProjectManagerNotifications;
- (void)unregisterForProjectManagerNotifications;

- (void)registerForNotificationsForCurrentSection;
- (void)unregisterForNotificationsForCurrentSection;

@end

@implementation GLAMainSectionNavigator

- (instancetype)initWithProjectManager:(GLAProjectManager *)projectManager
{
	self = [super init];
	if (self) {
		_projectManager = projectManager;
		
		[self registerForProjectManagerNotifications];
	}
	return self;
}

- (instancetype)init
{
	self = nil;
	
	[NSException raise:NSGenericException format:@"GLAMainSectionNavigator -init cannot be called, use -initWithProjectManager: instead."];
	
	return nil;
}

-(void)dealloc
{
	[self unregisterForProjectManagerNotifications];
	[self unregisterForNotificationsForCurrentSection];
}

#pragma mark -

- (void)goToSection:(GLAMainSection *)newSection
{
	GLAMainSection *previousSection = (self.currentSection);
	if ([newSection isEqual:previousSection]) {
		return;
	}
	
	[self unregisterForNotificationsForCurrentSection];
	
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	if (previousSection) {
		userInfo[GLAMainSectionNavigatorNotificationUserInfoPreviousSection] = previousSection;
	}
	
	(self.currentSection) = newSection;
	
	[self registerForNotificationsForCurrentSection];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:GLAMainSectionNavigatorDidChangeCurrentSectionNotification object:self userInfo:userInfo];
}

- (void)goToPreviousSection
{
	GLAMainSection *previousSection = (self.currentSection.previousSection);
	
	if (!previousSection) {
		previousSection = [GLAMainSection allProjectsSection];
	}
	
	[self goToSection:previousSection];
}

- (void)goToAllProjects
{
	[self goToSection:[GLAMainSection allProjectsSection]];
}

- (void)goToNowProject
{
	GLAProjectManager *projectManager = (self.projectManager);
	
	[projectManager loadNowProjectIfNeeded];
	GLAProject *nowProject = (projectManager.nowProject);
	
	[self goToSection:[GLAEditProjectSection nowProjectSectionWithProject:nowProject]];
}

- (void)goToProject:(GLAProject *)project
{
	NSParameterAssert(project != nil);
	
	GLAMainSection *previousSection = (self.currentSection);
	if (previousSection.isAddNewProject) {
		previousSection = nil;
	}
	
	[self goToSection:[GLAEditProjectSection editProjectSectionWithProject:project previousSection:previousSection]];
}

- (void)editPrimaryFoldersOfProject:(GLAProject *)project
{
	NSParameterAssert(project != nil);
	
	GLAMainSection *previousSection = (self.currentSection);
	if (!((previousSection.isEditProject) || (previousSection.isNow))) {
		previousSection = nil;
	}
	
	[self goToSection:[GLAEditProjectPrimaryFoldersSection editProjectPrimaryFoldersSectionWithProject:project previousSection:previousSection]];
}

- (void)addNewProject
{
	GLAMainSection *previousSection = (self.currentSection);
	if (!(previousSection.isAllProjects) || !(previousSection.isNow)) {
		previousSection = [GLAMainSection allProjectsSection];
	}
	
	[self goToSection:[GLAMainSection addNewProjectSectionWithPreviousSection:previousSection]];
}

- (void)goToCollection:(GLACollection *)collection
{
	NSParameterAssert(collection != nil);
	
	GLAEditProjectSection *editProjectSection;
	GLAMainSection *currentSection = (self.currentSection);
	if ((currentSection.isEditProject) || (currentSection.isNow)) {
		editProjectSection = (GLAEditProjectSection *)currentSection;
	}
	else {
		GLAProjectManager *projectManager = (self.projectManager);
		NSUUID *projectUUID = (collection.projectUUID);
		GLAProject *project = [projectManager projectWithUUID:projectUUID];
		GLAProject *nowProject = (projectManager.nowProject);
		
		if ((projectManager.nowProject) && [(nowProject.UUID) isEqual:projectUUID]) {
			editProjectSection = [GLAEditProjectSection nowProjectSectionWithProject:project];
		}
		else {
			editProjectSection = [GLAEditProjectSection editProjectSectionWithProject:project previousSection:nil];
		}
	}
	
	[self goToSection:[GLAEditCollectionSection editCollectionSectionWithCollection:collection previousSection:editProjectSection]];
}

- (void)addNewCollectionToProject:(GLAProject *)project
{
	[self goToSection:[GLAAddNewCollectionSection addNewCollectionSectionToProject:project previousSection:(self.currentSection)]];
}

- (void)addNewCollectionToProject:(GLAProject *)project pendingCollectedFilesInfo:(GLAPendingAddedCollectedFilesInfo *)pendingCollectedFilesInfo
{
	[self goToSection:[GLAAddNewCollectionSection addNewCollectionSectionToProject:project pendingAddedCollectedFilesInfo:pendingCollectedFilesInfo previousSection:(self.currentSection)]];
}

#pragma mark - Project Manager Notifications

- (void)registerForProjectManagerNotifications
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	GLAProjectManager *pm = (self.projectManager);
	
	[nc addObserver:self selector:@selector(projectManagerNowProjectDidChangeNotification:) name:GLAProjectManagerNowProjectDidChangeNotification object:pm];
}

- (void)unregisterForProjectManagerNotifications
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	GLAProjectManager *pm = (self.projectManager);
	
	[nc removeObserver:self name:nil object:pm];
}

- (void)projectManagerNowProjectDidChangeNotification:(NSNotification *)note
{
	if (self.currentSection.isNow) {
		[self goToNowProject];
	}
}

#pragma mark - Section-Specific Notifications

- (GLAProject *)projectToObserveForNotificationsForCurrentSection
{
	GLAMainSection *currentSection = (self.currentSection);
	if ([currentSection isKindOfClass:[GLAEditProjectSection class]]) {
		GLAEditProjectSection *editProjectSection = (id)currentSection;
		return (editProjectSection.project);
	}
	
	return nil;
}

- (void)registerForNotificationsForCurrentSection
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	GLAProjectManager *pm = (self.projectManager);
	
	if ( ! self.currentSection ) {
		return;
	}
	
	GLAProject *project = [self projectToObserveForNotificationsForCurrentSection];
	if (project) {
		[nc addObserver:self selector:@selector(projectForCurrentSectionWasDeletedNotification:) name:GLAProjectWasDeletedNotification object:[pm notificationObjectForProject:project]];
	}
}

- (void)unregisterForNotificationsForCurrentSection
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	GLAProjectManager *pm = (self.projectManager);
	
	if ( ! self.currentSection ) {
		return;
	}
	
	GLAProject *project = [self projectToObserveForNotificationsForCurrentSection];
	if (project) {
		[nc removeObserver:self name:nil object:[pm notificationObjectForProject:project]];
	}
}

//TODO: set this up to be observed.
- (void)projectForCurrentSectionWasDeletedNotification:(NSNotification *)note
{
	[self goToAllProjects];
}

@end

NSString *GLAMainSectionNavigatorDidChangeCurrentSectionNotification = @"GLAMainSectionNavigatorDidChangeCurrentSectionNotification";
NSString *GLAMainSectionNavigatorNotificationUserInfoPreviousSection = @"GLAMainSectionNavigatorNotificationUserInfoPreviousSection";
