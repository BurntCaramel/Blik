//
//  GLAApplicationSettingsManager.m
//  Blik
//
//  Created by Patrick Smith on 7/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAApplicationSettingsManager.h"
#import "GLACollectedFile.h"
#import "GLAArrayEditor.h"
#import "GLAArrayMantleJSONStore.h"
#import "GLAModelUUIDMap.h"
#import "GLAArrayEditorUser.h"
#import "GLACollectedFilesSetting.h"
#import "GLAWorkingFoldersManager.h"


NSString *GLAMainWindowHidesWhenInactive = @"mainWindow.hidesWhenInactive";


@interface GLAApplicationSettingsManager () <GLAArrayMantleJSONStoreErrorHandler>

@property(nonatomic) NSOperationQueue *backgroundOperationQueue;
@property(nonatomic) GLAArrayEditor *permittedApplicationFoldersArrayEditor;

@property(nonatomic) GLACollectedFilesSetting *permittedApplicationFoldersSetting;

@end

@implementation GLAApplicationSettingsManager

+ (instancetype)sharedApplicationSettingsManager
{
	static GLAApplicationSettingsManager *sharedApplicationSettingsManager;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedApplicationSettingsManager = [GLAApplicationSettingsManager new];
	});
	
	return sharedApplicationSettingsManager;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		NSOperationQueue *backgroundOperationQueue = [NSOperationQueue new];
		(backgroundOperationQueue.maxConcurrentOperationCount) = 1;
		_backgroundOperationQueue = backgroundOperationQueue;
		
		[self loadUserDefaults];
	}
	return self;
}

- (void)loadUserDefaults
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud registerDefaults:
	 @{
	   GLAMainWindowHidesWhenInactive: @YES
	   }
	 ];
	
	_hidesMainWindowWhenInactive = [ud boolForKey:GLAMainWindowHidesWhenInactive];
}

#pragma mark -

- (NSURL *)permittedApplicationFoldersJSONFileURL
{
	NSURL *folderURL = ([GLAWorkingFoldersManager sharedWorkingFoldersManager].version1DirectoryURL);
	return [folderURL URLByAppendingPathComponent:@"permitted-application-folders.json" isDirectory:NO];
}

- (GLAArrayEditor *)permittedApplicationFoldersArrayEditorCreateIfNeeded:(BOOL)create loadIfNeeded:(BOOL)load
{
	GLAArrayEditor *permittedApplicationFoldersArrayEditor = (self.permittedApplicationFoldersArrayEditor);
	
	if (!permittedApplicationFoldersArrayEditor) {
		if (!create) {
			return nil;
		}
		
		NSURL *JSONFileURL = [self permittedApplicationFoldersJSONFileURL];
		Class modelClass = [GLACollectedFile class];
		
		GLAArrayEditorOptions *arrayEditorOptions = [GLAArrayEditorOptions new];
		(arrayEditorOptions.store) = [[GLAArrayMantleJSONStore alloc] initWithModelClass:modelClass JSONFileURL:JSONFileURL JSONDictionaryKey:nil freshlyMade:NO operationQueue:(self.backgroundOperationQueue) errorHandler:self];
		[arrayEditorOptions setPrimaryIndexer:[GLAModelUUIDMap new]];
		
		permittedApplicationFoldersArrayEditor = [[GLAArrayEditor alloc] initWithObjects:@[] options:arrayEditorOptions];
		
		(self.permittedApplicationFoldersArrayEditor) = permittedApplicationFoldersArrayEditor;
	}
	
	if (load && (permittedApplicationFoldersArrayEditor.needsLoadingFromStore)) {
		id<GLAArrayStoring> editorStore = (permittedApplicationFoldersArrayEditor.store);
		NSAssert(editorStore != nil, @"Permitted application folders array editor must have a store");
		
		__weak GLAApplicationSettingsManager *weakSelf = self;
		
		[editorStore
		 loadIfNeededWithChildProcessor:nil
		 completionBlock:^(NSArray *loadedItems) {
			 __strong GLAApplicationSettingsManager *self = weakSelf;
			 if (!self) {
				 return;
			 }
			 
			 [[NSOperationQueue mainQueue] addOperationWithBlock:^{
				 [self permittedApplicationFoldersDidChange];
			 }];
		 }];
	}
	
	return permittedApplicationFoldersArrayEditor;
}

- (BOOL)hasLoadedPermittedApplicationFolders
{
	GLAArrayEditor *arrayEditor = [self permittedApplicationFoldersArrayEditorCreateIfNeeded:NO loadIfNeeded:NO];
	if (!arrayEditor) {
		return NO;
	}
	
	return (arrayEditor.finishedLoadingFromStore);
}

- (void)loadPermittedApplicationFolders
{
	[self permittedApplicationFoldersArrayEditorCreateIfNeeded:YES loadIfNeeded:YES];
}

- (NSArray *)copyPermittedApplicationFolders
{
	GLAArrayEditor *permittedApplicationFoldersArrayEditor = [self permittedApplicationFoldersArrayEditorCreateIfNeeded:NO loadIfNeeded:NO];
	
	if (permittedApplicationFoldersArrayEditor) {
		return [permittedApplicationFoldersArrayEditor copyChildren];
	}
	else {
		return nil;
	}
}

- (void)editPermittedApplicationFoldersUsingBlock:(void (^)(id<GLAArrayEditing>))block
{
	GLAArrayEditor *arrayEditor = [self permittedApplicationFoldersArrayEditorCreateIfNeeded:NO loadIfNeeded:NO];
	NSAssert(arrayEditor != nil && (arrayEditor.finishedLoadingFromStore), @"Permitted applications folders list must have been loaded before editing.");
	
	if (arrayEditor) {
		GLAArrayEditorChanges *changes = [arrayEditor changesMadeInBlock:block];
		if (changes.hasChanges) {
			[self permittedApplicationFoldersDidChange];
		}
	}
}

- (id<GLALoadableArrayUsing>)usePermittedApplicationFolders
{
	GLAArrayEditorUser *arrayEditorUser = [[GLAArrayEditorUser alloc] initWithLoadingBlock:^GLAArrayEditor *(BOOL createAndLoadIfNeeded) {
		return [self permittedApplicationFoldersArrayEditorCreateIfNeeded:createAndLoadIfNeeded loadIfNeeded:createAndLoadIfNeeded];
	} makeEditsBlock:^(GLAArrayEditingBlock editingBlock) {
		[self editPermittedApplicationFoldersUsingBlock:editingBlock];
	}];
	
	[arrayEditorUser makeObserverOfObject:self forChangeNotificationWithName:GLAApplicationSettingsManagerPermittedApplicationFoldersDidChangeNotification];
	
	return arrayEditorUser;
}

- (void)permittedApplicationFoldersDidChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAApplicationSettingsManagerPermittedApplicationFoldersDidChangeNotification object:self];
}

- (void)ensureAccessToPermittedApplicationsFolders
{
	if (_permittedApplicationFoldersSetting) {
		return;
	}
	
	GLACollectedFilesSetting *permittedApplicationFoldersSetting = [GLACollectedFilesSetting new];
	(permittedApplicationFoldersSetting.sourceCollectedFilesLoadableArray) = [self usePermittedApplicationFolders];
	_permittedApplicationFoldersSetting = permittedApplicationFoldersSetting;
}

#pragma mark -

- (void)setHidesMainWindowWhenInactive:(BOOL)hidesMainWindowWhenInactive
{
	_hidesMainWindowWhenInactive = hidesMainWindowWhenInactive;
	
	[[NSUserDefaults standardUserDefaults] setBool:hidesMainWindowWhenInactive forKey:GLAMainWindowHidesWhenInactive];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAApplicationSettingsManagerHideMainWindowWhenInactiveDidChangeNotification object:self];
}

- (IBAction)toggleHidesMainWindowWhenInactive:(id)sender
{
	(self.hidesMainWindowWhenInactive) = !(self.hidesMainWindowWhenInactive);
}

#pragma mark -

- (void)arrayMantleJSONStore:(GLAArrayMantleJSONStore *)store handleError:(NSError *)error
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		//TODO: something a bit more elegant?
		//[NSApp presentError:error];
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}];
}

@end

NSString *GLAApplicationSettingsManagerPermittedApplicationFoldersDidChangeNotification = @"GLAApplicationSettingsManagerPermittedApplicationFoldersDidChangeNotification";
NSString *GLAApplicationSettingsManagerHideMainWindowWhenInactiveDidChangeNotification = @"GLAApplicationSettingsManagerHideMainWindowWhenInactiveDidChangeNotification";
