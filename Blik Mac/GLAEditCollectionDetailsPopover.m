//
//  GLAEditCollectionDetailsPopover.m
//  Blik
//
//  Created by Patrick Smith on 20/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAEditCollectionDetailsPopover.h"
#import "NSObject+PGWSNotificationObserving.h"


@implementation GLAEditCollectionDetailsPopover

+ (instancetype)sharedEditCollectionDetailsPopover
{
	static GLAEditCollectionDetailsPopover *popover;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		popover = [GLAEditCollectionDetailsPopover new];
		GLAEditCollectionDetailsViewController *editCollectionDetailsViewController = [[GLAEditCollectionDetailsViewController alloc] initWithNibName:NSStringFromClass([GLAEditCollectionDetailsViewController class]) bundle:nil];
		
		(popover.editCollectionDetailsViewController) = editCollectionDetailsViewController;
		(popover.contentViewController) = editCollectionDetailsViewController;
		//(popover.appearance) = NSPopoverAppearanceHUD;
		(popover.appearance) = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
		(popover.behavior) = NSPopoverBehaviorSemitransient;
	});
	
	return popover;
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

- (void)viewControllerChosenNameDidChangeNotification:(NSNotification *)note
{
	[self pgws_postNotificationName:GLAEditCollectionDetailsPopoverChosenNameDidChangeNotification userInfo:(note.userInfo)];
}

- (void)viewControllerChosenColorDidChangeNotification:(NSNotification *)note
{
	[self pgws_postNotificationName:GLAEditCollectionDetailsPopoverChosenColorDidChangeNotification userInfo:(note.userInfo)];
}

- (void)beginObservingContentViewController
{
	GLAEditCollectionDetailsViewController *editCollectionDetailsViewController = (self.editCollectionDetailsViewController);
	if (editCollectionDetailsViewController) {
		[editCollectionDetailsViewController addObserver:self forChosenNameDidChangeNotificationWithSelector:@selector(viewControllerChosenNameDidChangeNotification:)];
		[editCollectionDetailsViewController addObserver:self forChosenColorDidChangeNotificationWithSelector:@selector(viewControllerChosenColorDidChangeNotification:)];
	}
}

- (void)endObservingContentViewController
{
	GLAEditCollectionDetailsViewController *editCollectionDetailsViewController = (self.editCollectionDetailsViewController);
	if (editCollectionDetailsViewController) {
		[editCollectionDetailsViewController pgws_removeObserver:self];
	}
}

#pragma mark -

- (void)setUpWithCollection:(GLACollection *)collection
{
	(void)(self.editCollectionDetailsViewController.view);
	
	(self.chosenName) = (collection.name);
	(self.chosenCollectionColor) = (collection.color);
}

- (NSString *)chosenName
{
	return (self.editCollectionDetailsViewController.chosenName);
}

- (void)setChosenName:(NSString *)name
{
	(self.editCollectionDetailsViewController.chosenName) = name;
}

- (GLACollectionColor *)chosenCollectionColor
{
	return (self.editCollectionDetailsViewController.chosenCollectionColor);
}

- (void)setChosenCollectionColor:(GLACollectionColor *)color
{
	(self.editCollectionDetailsViewController.chosenCollectionColor) = color;
}

@end

NSString *GLAEditCollectionDetailsPopoverChosenNameDidChangeNotification = @"GLAEditCollectionDetailsPopoverChosenNameDidChangeNotification";
NSString *GLAEditCollectionDetailsPopoverChosenColorDidChangeNotification = @"GLAEditCollectionDetailsPopoverChosenColorDidChangeNotification";
