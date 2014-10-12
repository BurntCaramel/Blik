//
//  GLACollectionColorPicker.m
//  Blik
//
//  Created by Patrick Smith on 1/10/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
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
		(colorChoicePopover.contentViewController) = colorPickerViewController;
		(colorChoicePopover.appearance) = NSPopoverAppearanceHUD;
		(colorChoicePopover.behavior) = NSPopoverBehaviorSemitransient;
	});
	
	return colorChoicePopover;
}

- (void)setContentViewController:(NSViewController *)contentViewController
{
	[self endObservingContentViewController];
	
	[super setContentViewController:contentViewController];
	
	[self beginObservingContentViewController];
}

- (GLACollectionColorPickerViewController *)colorPickerViewController
{
	NSViewController *contentViewController = (self.contentViewController);
	if (contentViewController && [contentViewController isKindOfClass:[GLACollectionColorPickerViewController class]]) {
		return (GLACollectionColorPickerViewController *)contentViewController;
	}
	else {
		return nil;
	}
}

- (void)viewControllerChosenColorDidChangeNotification:(NSNotification *)note
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLACollectionColorPickerPopoverChosenColorDidChangeNotification object:self userInfo:(note.userInfo)];
}

- (void)beginObservingContentViewController
{
	GLACollectionColorPickerViewController *colorPickerViewController = (self.colorPickerViewController);
	if (colorPickerViewController) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewControllerChosenColorDidChangeNotification:) name:GLACollectionColorPickerViewControllerChosenColorDidChangeNotification object:colorPickerViewController];
	}
}

- (void)endObservingContentViewController
{
	GLACollectionColorPickerViewController *colorPickerViewController = (self.colorPickerViewController);
	if (colorPickerViewController) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:GLACollectionColorPickerViewControllerChosenColorDidChangeNotification object:colorPickerViewController];
	}
}

- (GLACollectionColor *)chosenCollectionColor
{
	GLACollectionColorPickerViewController *colorPickerViewController = (self.colorPickerViewController);
	if (colorPickerViewController) {
		return (colorPickerViewController.chosenCollectionColor);
	}
	else {
		return nil;
	}
}

- (void)setChosenCollectionColor:(GLACollectionColor *)color
{
	GLACollectionColorPickerViewController *colorPickerViewController = (self.colorPickerViewController);
	if (colorPickerViewController) {
		[colorPickerViewController selectCollectionColorInUI:color];
		//(colorPickerViewController.chosenCollectionColor) = color;
	}
}

@end

NSString *GLACollectionColorPickerPopoverChosenColorDidChangeNotification = @"GLACollectionColorPickerPopoverChosenColorDidChangeNotification";
