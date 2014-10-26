//
//  GLAAddNewProjectViewController.m
//  Blik
//
//  Created by Patrick Smith on 14/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAAddNewProjectViewController.h"
#import "GLAUIStyle.h"
#import "GLAProjectManager.h"


@interface GLAAddNewProjectViewController ()

@end

@implementation GLAAddNewProjectViewController

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	[uiStyle prepareTextLabel:(self.nameLabel)];
	[uiStyle prepareOutlinedTextField:(self.nameTextField)];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(nameTextFieldTextDidChange:) name:NSControlTextDidChangeNotification object:(self.nameTextField)];
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	[self resetAndFocus];
}

- (void)checkNameTextFieldIsValid
{
	NSString *stringValue = (self.nameTextField.stringValue);
	
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	(self.confirmCreateButton.enabled) = [projectManager nameIsValid:stringValue];
}

- (void)resetAndFocus
{
	(self.nameTextField.stringValue) = @"";
	[self checkNameTextFieldIsValid];
	
	[(self.view.window) makeFirstResponder:(self.nameTextField)];
}

- (void)nameTextFieldTextDidChange:(NSNotification *)note
{
	[self checkNameTextFieldIsValid];
}

- (IBAction)confirmCreate:(id)sender
{
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	NSString *name = [projectManager normalizeName:(self.nameTextField.stringValue)];
	if (![projectManager nameIsValid:name]) {
		return;
	}
	
	GLAProject *project = [projectManager createNewProjectWithName:name];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAAddNewProjectViewControllerDidConfirmCreatingNotification object:self userInfo:@{@"project": project}];
}

@end

NSString *GLAAddNewProjectViewControllerDidConfirmCreatingNotification = @"GLAAddNewProjectViewControllerDidConfirmCreatingNotification";
