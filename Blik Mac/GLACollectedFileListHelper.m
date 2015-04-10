//
//  GLACollectedFileTableViewHelper.m
//  Blik
//
//  Created by Patrick Smith on 18/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLACollectedFileListHelper.h"
#import "GLAProjectManager.h"


@interface GLACollectedFileListHelper ()

@end

@implementation GLACollectedFileListHelper

+ (NSArray *)defaultURLResourceKeysToRequest
{
	return
  @[
	NSURLLocalizedNameKey,
	NSURLEffectiveIconKey
	];
}

- (instancetype)initWithDelegate:(id<GLACollectedFileListHelperDelegate>)delegate
{
	NSParameterAssert(delegate != nil);
	
	self = [super init];
	if (self) {
		_delegate = delegate;
		
		GLACollectedFilesSetting *collectedFilesSetting = [GLACollectedFilesSetting new];
		(collectedFilesSetting.defaultURLResourceKeysToRequest) = (self.class.defaultURLResourceKeysToRequest);
		_collectedFilesSetting = collectedFilesSetting;
		
		[self startObservingCollectedFilesSetting];
	}
	return self;
}

- (void)dealloc
{
	[self stopWatchingProjectPrimaryFolders];
	[self stopObservingProject];
	[self stopObservingCollectedFilesSetting];
}

- (GLAProjectManager *)projectManager
{
	return [GLAProjectManager sharedProjectManager];
}

- (void)invalidate
{
	id<GLACollectedFileListHelperDelegate> delegate = (self.delegate);
	[delegate collectedFileListHelperDidInvalidate:self];
}

- (void)setProject:(GLAProject *)project
{
	[self stopObservingProject];
	[self stopWatchingProjectPrimaryFolders];
	
	_project = project;
	
	[self startObservingProject];
	[self updateWatchedProjectPrimaryFolders];
}

- (void)startObservingProject
{
	GLAProject *project = (self.project);
	if (!project) {
		return;
	}
	
	GLAProjectManager *pm = (self.projectManager);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if (project) {
		id projectNotifier = [pm notificationObjectForProject:project];
		[nc addObserver:self selector:@selector(projectPrimaryFoldersDidChangeNotification:) name:GLAProjectPrimaryFoldersDidChangeNotification object:projectNotifier];
	}
}

- (void)stopObservingProject
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:GLAProjectPrimaryFoldersDidChangeNotification object:nil];
}

- (void)startObservingCollectedFilesSetting
{
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self selector:@selector(collectedFilesSettingLoadedFileInfoDidChangeNotification:) name:GLACollectedFilesSettingLoadedFileInfoDidChangeNotification object:collectedFilesSetting];
	[nc addObserver:self selector:@selector(watchedDirectoriesDidChangeNotification:) name:GLACollectedFilesSettingDirectoriesDidChangeNotification object:collectedFilesSetting];
}

- (void)stopObservingCollectedFilesSetting
{
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc removeObserver:self name:nil object:collectedFilesSetting];
}

- (void)updateWatchedProjectPrimaryFolders
{
	GLAProjectManager *pm = (self.projectManager);
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
#if DEBUG && 0
	NSLog(@"updateWatchedProjectPrimaryFolders %@", collectedFilesSetting);
#endif
	NSArray *projectFolders = [pm copyPrimaryFoldersForProject:(self.project)];
	NSMutableSet *directoryURLs = [NSMutableSet new];
	for (GLACollectedFile *collectedFile in projectFolders) {
		GLAAccessedFileInfo *accessedFileInfo = [collectedFile accessFile];
		NSURL *directoryURL = (accessedFileInfo.filePathURL);
		[directoryURLs addObject:directoryURL];
	}
	(collectedFilesSetting.directoryURLsToWatch) = directoryURLs;
}

- (void)stopWatchingProjectPrimaryFolders
{
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	(collectedFilesSetting.directoryURLsToWatch) = nil;
}

- (void)projectPrimaryFoldersDidChangeNotification:(NSNotification *)note
{
	[self updateWatchedProjectPrimaryFolders];
	[self invalidate];
}

- (void)watchedDirectoriesDidChangeNotification:(NSNotification *)note
{
	[(self.collectedFilesSetting) invalidateAllAccessedFiles];
	
	[self invalidate];
}

- (void)collectedFilesSettingLoadedFileInfoDidChangeNotification:(NSNotification *)note
{
	[self invalidate];
}

- (void)setCollectedFiles:(NSArray *)collectedFiles
{
	_collectedFiles = [collectedFiles copy];
	
	[(self.collectedFilesSetting) startAccessingCollectedFilesStoppingRemainders:collectedFiles];
	//[self invalidate];
}

- (id<GLAFileAccessing>)accessFileForCollectedFile:(GLACollectedFile *)collectedFile
{
	return [(self.collectedFilesSetting) accessedFileInfoForCollectedFile:collectedFile];
}

#pragma mark -

- (void)setUpTableCellView:(NSTableCellView *)cellView forTableColumn:(NSTableColumn *)tableColumn collectedFile:(GLACollectedFile *)collectedFile
{
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	[collectedFilesSetting setUpTableCellView:cellView forTableColumn:tableColumn collectedFile:collectedFile];
}

#if 0

#pragma mark File Info Retriever Delegate

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didLoadResourceValuesForURL:(NSURL *)fileURL
{
	GLACollectedFilesSetting *collectedFilesSetting = (self.collectedFilesSetting);
	
	NSArray *allCollectedFiles = (self.collectedFiles);
	NSUInteger matchingIndex = [allCollectedFiles indexOfObjectPassingTest:^BOOL(GLACollectedFile *collectedFile, NSUInteger idx, BOOL *stop) {
		GLAAccessedFileInfo *accessedFile = [collectedFilesSetting accessedFileInfoForCollectedFile:collectedFile];
		return [fileURL isEqual:(accessedFile.filePathURL)];
	}];
	GLACollectedFile *matchingCollectedFile = allCollectedFiles[matchingIndex];
	
	id<GLACollectedFileListHelperDelegate> delegate = (self.delegate);
	if ([delegate respondsToSelector:@selector(collectedFileListHelper:didLoadInfoForCollectedFiles:)]) {
		[delegate collectedFileListHelper:self didLoadInfoForCollectedFiles:@[matchingCollectedFile]];
	}
	else {
		[self invalidate];
	}
}

- (void)fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever didFailWithError:(NSError *)error loadingResourceValuesForURL:(NSURL *)URL
{

}

#endif

@end
