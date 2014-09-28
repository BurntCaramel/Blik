//
//  GLAAddNewCollectionViewController.m
//  Blik
//
//  Created by Patrick Smith on 27/09/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAAddNewCollectionViewController.h"
#import "GLAUIStyle.h"
#import "GLAProjectManager.h"
#import "GLACollectionFilesListContent.h"


@interface GLAAddNewCollectionViewController ()

@end

@implementation GLAAddNewCollectionViewController

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
	GLAProject *project = (self.project);
	GLAProjectManager *projectManager = [GLAProjectManager sharedProjectManager];
	
	NSString *name = [projectManager normalizeName:(self.nameLabel.stringValue)];
	if (![projectManager nameIsValid:name]) {
		return;
	}
	
	GLACollectionContent *collectionContent = [GLACollectionFilesListContent new];
	
	GLACollection *collection = [projectManager createNewCollectionWithName:name content:collectionContent inProject:project];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAAddNewCollectionViewControllerDidConfirmCreatingNotification object:self userInfo:@{@"collection": collection}];
}

@end

NSString *GLAAddNewCollectionViewControllerDidConfirmCreatingNotification = @"GLAAddNewCollectionViewControllerDidConfirmCreatingNotification";
