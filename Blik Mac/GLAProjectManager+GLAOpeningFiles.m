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
	
	NSEventModifierFlags modifierFlags = [NSEvent modifierFlags];
	// Command shows the file in the Finder
	if (modifierFlags & NSCommandKeyMask) {
		[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[(accessedFileInfo.filePathURL)]];
		return YES;
	}
	
	if ((modifierFlags & NSAlternateKeyMask) == 0) {
		// Check for Automator applets.
		NSBundle *bundle = [NSBundle bundleWithURL:(accessedFileInfo.filePathURL)];
		if (bundle) {
			NSDictionary *infoDictionary = (bundle.infoDictionary);
			
			BOOL isApplication = [@"APPL" isEqual:infoDictionary[@"CFBundlePackageType"]];
			//BOOL isAutomatorApplet = [@YES isEqual:infoDictionary[@"AMIsApplet"]];
			// if (isAutomatorApplet) {
			if (isApplication) {
				[[NSWorkspace sharedWorkspace] openURL:(accessedFileInfo.filePathURL)];
				return YES;
			}
		}
	}
	
	
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
