//
//  GLAStatusItemController.h
//  Blik
//
//  Created by Patrick Smith on 27/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;


@interface GLAStatusItemController : NSObject

+ (instancetype)sharedStatusItemController;

@property(nonatomic) NSStatusItem *statusItem;
@property(readonly, nonatomic) BOOL showsItem;

- (void)showItem;
- (void)hideItem;
- (IBAction)toggleShowingItem:(id)sender;

- (void)loadSettings;
- (void)saveSettings;

- (IBAction)toggleAppIsActive:(id)sender;

@end

extern NSString *GLAStatusItemControllerItemShowsItemChangedNotification;
extern NSString *GLAStatusItemControllerItemWasClickedNotification;