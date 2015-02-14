//
//  GLAStatusItemController.m
//  Blik
//
//  Created by Patrick Smith on 27/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAStatusItemController.h"


NSString *GLAStatusItemShowsItem = @"statusItem.showsItem";


@interface GLAStatusItemController ()

@property(readwrite, nonatomic) BOOL showsItem;

@end

@implementation GLAStatusItemController

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
	static GLAStatusItemController *sharedStatusItemController;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedStatusItemController = [[super allocWithZone:zone] initProper];
	});
	return sharedStatusItemController;
}

- (instancetype)init
{
	return self;
}

+ (instancetype)sharedStatusItemController
{
	return [self allocWithZone:nil];
}

- (instancetype)initProper
{
    self = [super init];
    if (self) {
		_showsItem = NO;
		
		[self loadSettings];
    }
    return self;
}

- (void)loadSettings
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud registerDefaults:
	 @{
	   GLAStatusItemShowsItem: @YES
	   }
	 ];
	
	BOOL showsItem = [ud boolForKey:GLAStatusItemShowsItem];
	if (showsItem) {
		[self showItem];
	}
}

- (void)saveSettings
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	
	[ud setBool:(self.showsItem) forKey:GLAStatusItemShowsItem];
}

- (void)setUpStatusItemIfNeeded
{
	if (self.statusItem) {
		return;
	}
	
	NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
	CGFloat statusItemLength = 27.0;
	NSStatusItem *statusItem = [statusBar statusItemWithLength:statusItemLength];
	
	NSImage *symbolImage = [NSImage imageNamed:@"Status Item"];
	[symbolImage setTemplate:YES];
	(statusItem.image) = symbolImage;
	
	(statusItem.target) = self;
	(statusItem.action) = @selector(toggleAppIsActive:);
	[statusItem sendActionOn:NSLeftMouseUpMask];
	
	(self.statusItem) = statusItem;
}

- (void)showItem
{
	if (self.showsItem) {
		return;
	}
	
	(self.showsItem) = YES;
	
	[self setUpStatusItemIfNeeded];
	
	[self saveSettings];
	[self notifyShowsItemChanged];
}

- (void)hideItem
{
	if (! self.showsItem) {
		return;
	}
	
	(self.showsItem) = NO;
	
	NSStatusItem *statusItem = (self.statusItem);
	[(statusItem.statusBar) removeStatusItem:statusItem];
	(self.statusItem) = nil;
	
	[self saveSettings];
	[self notifyShowsItemChanged];
}

- (void)notifyShowsItemChanged
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAStatusItemControllerItemShowsItemChangedNotification object:self];
}

- (void)toggleShowingItem:(id)sender
{
	if (self.showsItem) {
		[self hideItem];
	}
	else {
		[self showItem];
	}
}

- (IBAction)toggleAppIsActive:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAStatusItemControllerItemWasClickedNotification object:self];
}

@end

NSString *GLAStatusItemControllerItemShowsItemChangedNotification = @"GLAStatusItemControllerItemShowsItemChangedNotification";
NSString *GLAStatusItemControllerItemWasClickedNotification = @"GLAStatusItemControllerToggleNotification";
