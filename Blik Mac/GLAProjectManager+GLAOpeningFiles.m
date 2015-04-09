//
//  GLAProjectManager+GLAOpeningFiles.m
//  Blik
//
//  Created by Patrick Smith on 9/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAProjectManager+GLAOpeningFiles.h"
#import "GLAFileOpenerApplicationCombiner.h"


@implementation GLAProjectManager (GLAOpeningFiles)

- (BOOL)openHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile
{
	GLACollectedFile *collectedFile = [self collectedFileForHighlightedCollectedFile:highlightedCollectedFile loadIfNeeded:NO];
	if (!collectedFile) {
		return NO;
	}
	
	// Stays accessed as long as this exists.
	// So (accessedFileInfo.filePathURL) is used below, to have a reference.
	GLAAccessedFileInfo *accessedFileInfo = [collectedFile accessFile];
	
	NSURL *applicationURL = nil;
	GLACollectedFile *applicationToOpenFileCollected = (highlightedCollectedFile.applicationToOpenFile);
	if (applicationToOpenFileCollected) {
		GLAAccessedFileInfo *preferredApplicationAccessedFile = [applicationToOpenFileCollected accessFile];
		applicationURL = (preferredApplicationAccessedFile.filePathURL);
	}
	
	if (!applicationURL) {
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		applicationURL = [workspace URLForApplicationToOpenURL:(accessedFileInfo.filePathURL)];
	}
	
	[GLAFileOpenerApplicationCombiner openFileURLs:@[(accessedFileInfo.filePathURL)] withApplicationURL:applicationURL useSecurityScope:YES];
	
	return YES;
}

@end
