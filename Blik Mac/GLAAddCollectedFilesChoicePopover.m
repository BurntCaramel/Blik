//
//  GLAAddCollectedFilesChoicePopover.m
//  Blik
//
//  Created by Patrick Smith on 9/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAAddCollectedFilesChoicePopover.h"
#import "NSObject+PGWSNotificationObserving.h"


@interface GLAAddCollectedFilesChoicePopover (GLAAddCollectedFilesChoiceActionsDelegate) <GLAAddCollectedFilesChoiceActionsDelegate>

@end

@implementation GLAAddCollectedFilesChoicePopover

+ (instancetype)sharedAddCollectedFilesChoicePopover
{
	static GLAAddCollectedFilesChoicePopover *popover;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		popover = [GLAAddCollectedFilesChoicePopover new];
		GLAAddCollectedFilesChoiceViewController *addCollectedFilesChoiceViewController = [[GLAAddCollectedFilesChoiceViewController alloc] initWithNibName:NSStringFromClass([GLAAddCollectedFilesChoiceViewController class]) bundle:nil];
		
		(popover.addCollectedFilesChoiceViewController) = addCollectedFilesChoiceViewController;
		(popover.contentViewController) = addCollectedFilesChoiceViewController;
		//(popover.appearance) = NSPopoverAppearanceHUD;
		(popover.appearance) = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
		(popover.behavior) = NSPopoverBehaviorSemitransient;
	});
	
	return popover;
}

@synthesize addCollectedFilesChoiceViewController = _addCollectedFilesChoiceViewController;

- (void)setAddCollectedFilesChoiceViewController:(GLAAddCollectedFilesChoiceViewController *)addCollectedFilesChoiceViewController
{
	_addCollectedFilesChoiceViewController = addCollectedFilesChoiceViewController;
	if (addCollectedFilesChoiceViewController) {
		(addCollectedFilesChoiceViewController.actionsDelegate) = self;
	}
}

@synthesize info = _info;

- (void)setInfo:(GLAPendingAddedCollectedFilesInfo *)info
{
	_info = [info copy];
	(self.addCollectedFilesChoiceViewController.info) = info;
}

@synthesize actionsDelegate = _actionsDelegate;

@end

@implementation GLAAddCollectedFilesChoicePopover (GLAAddCollectedFilesChoiceActionsDelegate)

- (void)performAddCollectedFilesToExistingCollection:(NSResponder *)responder info:(GLAPendingAddedCollectedFilesInfo *)info
{
	id<GLAAddCollectedFilesChoiceActionsDelegate> actionsDelegate = (self.actionsDelegate);
	if ((actionsDelegate) && [actionsDelegate respondsToSelector:_cmd]) {
		[actionsDelegate performAddCollectedFilesToExistingCollection:self info:info];
	}
}

- (void)performAddCollectedFilesToNewCollection:(NSResponder *)responder info:(GLAPendingAddedCollectedFilesInfo *)info
{
	id<GLAAddCollectedFilesChoiceActionsDelegate> actionsDelegate = (self.actionsDelegate);
	if ((actionsDelegate) && [actionsDelegate respondsToSelector:_cmd]) {
		[actionsDelegate performAddCollectedFilesToNewCollection:self info:info];
	}
	
	[self close];
}

@end
