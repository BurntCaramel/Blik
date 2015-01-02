//
//  GLAEditCollectionDetailsViewController.m
//  Blik
//
//  Created by Patrick Smith on 20/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAEditCollectionDetailsViewController.h"
#import "GLAUIStyle.h"


@interface GLAEditCollectionDetailsViewController ()

@end

@implementation GLAEditCollectionDetailsViewController

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	[uiStyle prepareTextLabel:(self.nameLabel)];
	[uiStyle prepareOutlinedTextField:(self.nameTextField)];
	[uiStyle prepareTextLabel:(self.colorLabel)];
	
	GLACollectionColorPickerViewController *colorPickerViewController = [[GLACollectionColorPickerViewController alloc] initWithNibName:@"GLACollectionColorPickerViewController" bundle:nil];
	(self.colorPickerViewController) = colorPickerViewController;
	
	(self.colorPickerHolderViewController) = [[GLAViewController alloc] initWithHolderView:(self.colorPickerHolderView) filledWithView:(colorPickerViewController.view)];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(chosenColorDidChange:) name:GLACollectionColorPickerViewControllerChosenColorDidChangeNotification object:colorPickerViewController];
}

- (NSString *)chosenName
{
	return (self.nameTextField.stringValue);
}

- (void)setChosenName:(NSString *)chosenName
{
	(self.nameTextField.stringValue) = chosenName;
}

- (GLACollectionColor *)chosenCollectionColor
{
	GLACollectionColorPickerViewController *colorPickerViewController = (self.colorPickerViewController);
	return (colorPickerViewController.chosenCollectionColor);
}

- (void)setChosenCollectionColor:(GLACollectionColor *)color
{
	GLACollectionColorPickerViewController *colorPickerViewController = (self.colorPickerViewController);
	[colorPickerViewController selectCollectionColorInUI:color];
}

- (IBAction)nameChanged:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAEditCollectionDetailsViewControllerChosenNameDidChangeNotification object:self];
}

- (void)chosenColorDidChange:(NSNotification *)note
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAEditCollectionDetailsViewControllerChosenColorDidChangeNotification object:self userInfo:(note.userInfo)];
}

- (void)addObserver:(id)observer forChosenNameDidChangeNotificationWithSelector:(SEL)aSelector
{
	[self addObserver:observer forNotificationWithName:GLAEditCollectionDetailsViewControllerChosenNameDidChangeNotification selector:aSelector];
}

- (void)addObserver:(id)observer forChosenColorDidChangeNotificationWithSelector:(SEL)aSelector
{
	[self addObserver:observer forNotificationWithName:GLAEditCollectionDetailsViewControllerChosenColorDidChangeNotification selector:aSelector];
}

@end

NSString *GLAEditCollectionDetailsViewControllerChosenNameDidChangeNotification = @"GLAEditCollectionDetailsViewControllerChosenNameDidChangeNotification";
NSString *GLAEditCollectionDetailsViewControllerChosenColorDidChangeNotification = @"GLAEditCollectionDetailsViewControllerChosenColorDidChangeNotification";
