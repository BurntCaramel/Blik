//
//  GLACollectionColorPicker.m
//  Blik
//
//  Created by Patrick Smith on 1/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLACollectionColorPickerPopover.h"


@implementation GLACollectionColorPickerPopover

+ (instancetype)sharedColorPickerPopover
{
	static GLACollectionColorPickerPopover *colorChoicePopover;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		colorChoicePopover = [GLACollectionColorPickerPopover new];
		GLACollectionColorPickerViewController *colorPickerViewController = [[GLACollectionColorPickerViewController alloc] initWithNibName:@"GLACollectionColorPickerViewController" bundle:nil];
		(colorChoicePopover.colorPickerViewController) = colorPickerViewController;
		(colorChoicePopover.contentViewController) = colorPickerViewController;
		//(colorChoicePopover.appearance) = NSPopoverAppearanceHUD;
		(colorChoicePopover.behavior) = NSPopoverBehaviorSemitransient;
	});
	
	return colorChoicePopover;
}

- (void)dealloc
{
	[self endObservingContentViewController];
}

- (void)setContentViewController:(NSViewController *)contentViewController
{
	[self endObservingContentViewController];
	
	[super setContentViewController:contentViewController];
	
	[self beginObservingContentViewController];
}

#pragma mark -

- (void)viewControllerChosenColorDidChangeNotification:(NSNotification *)note
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLACollectionColorPickerPopoverChosenColorDidChangeNotification object:self userInfo:(note.userInfo)];
}

- (void)beginObservingContentViewController
{
	GLACollectionColorPickerViewController *colorPickerViewController = (self.colorPickerViewController);
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewControllerChosenColorDidChangeNotification:) name:GLACollectionColorPickerViewControllerChosenColorDidChangeNotification object:colorPickerViewController];
}

- (void)endObservingContentViewController
{
	GLACollectionColorPickerViewController *colorPickerViewController = (self.colorPickerViewController);
	[[NSNotificationCenter defaultCenter] removeObserver:self name:GLACollectionColorPickerViewControllerChosenColorDidChangeNotification object:colorPickerViewController];
}

#pragma mark -

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

@end

NSString *GLACollectionColorPickerPopoverChosenColorDidChangeNotification = @"GLACollectionColorPickerPopoverChosenColorDidChangeNotification";
