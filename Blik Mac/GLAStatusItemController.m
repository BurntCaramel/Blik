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

- (instancetype)init
{
    self = [super init];
    if (self) {
		_showsItem = YES;
		
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
	
	(self.showsItem) = [ud boolForKey:GLAStatusItemShowsItem];
	
	if (self.showsItem) {
		[self show];
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
	(statusItem.action) = @selector(toggle:);
	[statusItem sendActionOn:NSLeftMouseDownMask];
	
	(self.statusItem) = statusItem;
}

- (void)show
{
	(self.showsItem) = YES;
	
	[self setUpStatusItemIfNeeded];
}

- (void)hide
{
	(self.showsItem) = NO;
	
	NSStatusItem *statusItem = (self.statusItem);
	[(statusItem.statusBar) removeStatusItem:statusItem];
	(self.statusItem) = nil;
}

- (void)toggleShowing:(id)sender
{
	(self.showsItem) ? [self hide] : [self show];
	[self saveSettings];
}

- (IBAction)toggle:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAStatusItemControllerToggleNotification object:self];
}

@end

NSString *GLAStatusItemControllerToggleNotification = @"GLAStatusItemControllerToggleNotification";
