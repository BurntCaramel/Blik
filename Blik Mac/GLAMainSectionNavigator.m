//
//  GLAMainSectionNavigator.m
//  Blik
//
//  Created by Patrick Smith on 11/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAMainSectionNavigator.h"
#import "GLAProjectManager.h"
#import "GLAEnabledFeatures.h"


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
	NSParameterAssert(projectManager != nil);
	
	self = [super init];
	if (self) {
		_projectManager = projectManager;
		
		[self registerForProjectManagerNotifications];
	}
	return self;
}

- (instancetype)init __unavailable
{
	[NSException raise:NSGenericException format:@"GLAMainSectionNavigator -init cannot be called, use -initWithProjectManager: instead."];
	
	return nil;
}

-(void)dealloc
{
	[self unregisterForProjectManagerNotifications];
	[self unregisterForNotificationsForCurrentSection];
}

+ (instancetype)sharedMainSectionNavigator
{
	static GLAMainSectionNavigator *sharedInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[GLAMainSectionNavigator alloc] initWithProjectManager:[GLAProjectManager sharedProjectManager]];
	});
	return sharedInstance;
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

- (GLAMainSection *)defaultSection
{
	return [GLAMainSection allProjectsSection];
}

- (void)goToPreviousSection
{
	GLAMainSection *previousSection = (self.currentSection.previousSection);
	
	if (!previousSection) {
		previousSection = (self.defaultSection);
	}
	
	[self goToSection:previousSection];
}

- (void)goToPreviousUnrelatedSection
{
	GLAMainSection *previousSection = (self.currentSection.previousUnrelatedSection);
	
	if (!previousSection) {
		previousSection = (self.defaultSection);
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
	
#if 0
	GLAMainSection *currentSection = (self.currentSection);
	GLAMainSection *previousSection = (self.currentSection);
	if (previousSection.isAddNewProject) {
		previousSection = nil;
	}
#else
	GLAMainSection *previousSection = nil;
#endif
	
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
	
	NSUUID *projectUUIDForCollection = (collection.projectUUID);
	
	GLAEditProjectSection *previousProjectSection = nil;
	GLAMainSection *currentSection = (self.currentSection);
	// Use current section if it has the same project.
	if ((currentSection.isEditProject) || (currentSection.isNow)) {
		GLAEditProjectSection *currentProjectSection = (GLAEditProjectSection *)currentSection;
		if ([(currentProjectSection.project.UUID) isEqual:projectUUIDForCollection]) {
			previousProjectSection = currentProjectSection;
		}
	}
	
	// Otherwise make a new section with the project.
	if (previousProjectSection == nil) {
		GLAProjectManager *projectManager = (self.projectManager);
		GLAProject *project = [projectManager projectWithUUID:projectUUIDForCollection];
		GLAProject *nowProject = (projectManager.nowProject);
		
		if ((projectManager.nowProject) && [(nowProject.UUID) isEqual:projectUUIDForCollection]) {
			previousProjectSection = [GLAEditProjectSection nowProjectSectionWithProject:project];
		}
		else {
			previousProjectSection = [GLAEditProjectSection editProjectSectionWithProject:project previousSection:nil];
		}
	}
	
	[self goToSection:
	 [GLAEditCollectionSection editCollectionSectionWithCollection:collection previousSection:previousProjectSection]
	 ];
}

- (GLACollection *)collectionMakeViewMode:(NSString *)viewMode
{
	GLAEditCollectionSection *currentSection = (id)(self.currentSection);
	NSAssert([currentSection isKindOfClass:[GLAEditCollectionSection class]], @"Current section must be collection.");
	
	GLACollection *collection = (currentSection.collection);
	GLAProjectManager *pm = (self.projectManager);
	GLAProject *project = [pm projectWithUUID:(collection.projectUUID)];
	return [pm editCollection:collection inProject:project usingBlock:^(id<GLACollectionEditing> collectionEditor) {
		(collectionEditor.viewMode) = viewMode;
	}];
}

- (void)collectionMakeViewModeList
{
	[self goToCollection:[self collectionMakeViewMode:GLACollectionViewModeList]];
}

- (void)collectionMakeViewModeExpanded
{
	[self goToCollection:[self collectionMakeViewMode:GLACollectionViewModeExpanded]];
}

- (void)addNewCollectionToProject:(GLAProject *)project
{
#if GLA_ENABLE_CREATE_FILTERED_COLLECTION
	[self goToSection:
	 [GLAAddNewCollectionSection addNewCollectionSectionToProject:project previousSection:(self.currentSection)]
	 ];
#else
	[self addNewCollectedFilesCollectionToProject:project];
#endif
}

- (void)addNewCollectionGoToCollectedFilesSection
{
	GLAAddNewCollectionSection *currentSection = (GLAAddNewCollectionSection *)(self.currentSection);
	NSAssert(currentSection != nil && [currentSection isKindOfClass:[GLAAddNewCollectionSection class]], @"There must be a section to go from.");
	
	GLAProject *project = (currentSection.project);
	[self addNewCollectedFilesCollectionToProject:project];
}

- (void)addNewCollectedFilesCollectionToProject:(GLAProject *)project
{
	[self goToSection:
	 [GLAAddNewCollectedFilesCollectionSection addNewCollectionChooseNameAndColorSectionWithProject:project pendingAddedCollectedFilesInfo:nil previousSection:(self.currentSection)]
	 ];
}

- (void)addNewCollectedFilesCollectionToProject:(GLAProject *)project pendingCollectedFilesInfo:(GLAPendingAddedCollectedFilesInfo *)pendingCollectedFilesInfo
{
	[self goToSection:
	 [GLAAddNewCollectedFilesCollectionSection addNewCollectionChooseNameAndColorSectionWithProject:project pendingAddedCollectedFilesInfo:pendingCollectedFilesInfo previousSection:(self.currentSection)]
	 ];
}

- (void)addNewCollectionGoToFilteredFolderSection
{
	GLAAddNewCollectionSection *currentSection = (GLAAddNewCollectionSection *)(self.currentSection);
	NSAssert(currentSection != nil && [currentSection isKindOfClass:[GLAAddNewCollectionSection class]], @"There must be a section to go from.");
	
	GLAProject *project = (currentSection.project);
	[self addNewFilteredFolderCollectionToProject:project];
}

- (void)addNewFilteredFolderCollectionToProject:(GLAProject *)project
{
	[self goToSection:
	 [GLAAddNewFilteredFolderCollectionSection addNewFilteredFolderCollectionChooseFolderSectionWithProject:project previousSection:(self.currentSection)]
	 ];
}

- (void)addNewFilteredFolderCollectionGoToChooseNameAndColorWithChosenFolder:(NSURL *)folderURL chosenTagName:(NSString *)tagName
{
	GLAAddNewFilteredFolderCollectionSection *currentSection = (GLAAddNewFilteredFolderCollectionSection *)(self.currentSection);
	NSAssert(currentSection != nil && [currentSection isKindOfClass:[GLAAddNewFilteredFolderCollectionSection class]], @"There must be a section to go from.");
	
	[self goToSection:
	 [GLAAddNewFilteredFolderCollectionSection addNewCollectionChooseNameAndColorSectionWithProject:(currentSection.project) chosenFolderURL:folderURL chosenTagName:tagName previousSection:(self.currentSection)]
	 ];
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
