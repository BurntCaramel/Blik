//
//  GLAProjectManager+GLAOpeningFiles.m
//  Blik
//
//  Created by Patrick Smith on 9/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAProjectManager+GLAOpeningFiles.h"
#import "GLAFileOpenerApplicationFinder.h"


@implementation GLAProjectManager (GLAOpeningFiles)

- (void)openCollectedFile:(GLACollectedFile *)collectedFile behaviour:(GLAOpenBehaviour)behaviour
{
	// Stays accessed as long as this exists.
	// So (accessedFileInfo.filePathURL) is used below, to have a reference.
	GLAAccessedFileInfo *accessedFileInfo = [collectedFile accessFile];
	
	// Command shows the file in the Finder
	if (behaviour == GLAOpenBehaviourShowInFinder) {
		[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[(accessedFileInfo.filePathURL)]];
		return;
	}
	
	if (behaviour == GLAOpenBehaviourDefault) {
		// Check for Automator applets.
		NSBundle *bundle = [NSBundle bundleWithURL:(accessedFileInfo.filePathURL)];
		if (bundle) {
			NSDictionary *infoDictionary = (bundle.infoDictionary);
			
			BOOL isApplication = [@"APPL" isEqual:infoDictionary[@"CFBundlePackageType"]];
			//BOOL isAutomatorApplet = [@YES isEqual:infoDictionary[@"AMIsApplet"]];
			// if (isAutomatorApplet) {
			if (isApplication) {
				[[NSWorkspace sharedWorkspace] openURL:(accessedFileInfo.filePathURL)];
				return;
			}
		}
	}
	
	// GLAOpenBehaviourDefault or GLAOpenBehaviourAllowEditingApplications
	[GLAFileOpenerApplicationFinder openFileURLs:@[(accessedFileInfo.filePathURL)] withApplicationURL:nil useSecurityScope:YES];
}

- (void)openCollectedFile:(GLACollectedFile *)collectedFile modifierFlags:(NSEventModifierFlags)modifierFlags
{
	GLAOpenBehaviour behaviour = [self openBehaviourForModifierFlags:modifierFlags];
	
	[self openCollectedFile:collectedFile behaviour:behaviour];
}


- (BOOL)openHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile behaviour:(GLAOpenBehaviour)behaviour
{
	GLACollectedFile *collectedFile = [self collectedFileForHighlightedCollectedFile:highlightedCollectedFile loadIfNeeded:NO];
	if (!collectedFile || (collectedFile.empty)) {
		return NO;
	}
	
	// Stays accessed as long as this exists.
	// So (accessedFileInfo.filePathURL) is used below, to have a reference.
	GLAAccessedFileInfo *accessedFileInfo = [collectedFile accessFile];
	
	// Command shows the file in the Finder
	if (behaviour == GLAOpenBehaviourShowInFinder) {
		[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[(accessedFileInfo.filePathURL)]];
		return YES;
	}
	
	// Option key will open with editor, no option key will open using default.
	if (behaviour == GLAOpenBehaviourDefault) {
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
	
	[GLAFileOpenerApplicationFinder openFileURLs:@[(accessedFileInfo.filePathURL)] withApplicationURL:applicationURL useSecurityScope:YES];
	
	return YES;
}

- (BOOL)openHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile modifierFlags:(NSEventModifierFlags)modifierFlags
{
	GLAOpenBehaviour behaviour = [self openBehaviourForModifierFlags:modifierFlags];
	
	return [self openHighlightedCollectedFile:highlightedCollectedFile behaviour:behaviour];
}


- (GLAOpenBehaviour)openBehaviourForModifierFlags:(NSEventModifierFlags)modifierFlags
{
	GLAOpenBehaviour behaviour = GLAOpenBehaviourDefault;
	
	if (modifierFlags & NSCommandKeyMask) {
		behaviour = GLAOpenBehaviourShowInFinder;
	}
	else if (modifierFlags & NSAlternateKeyMask) {
		behaviour = GLAOpenBehaviourAllowEditingApplications;
	}
	
	return behaviour;
}

@end
