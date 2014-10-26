//
//  GLAStatusItemController.h
//  Blik
//
//  Created by Patrick Smith on 27/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;


@interface GLAStatusItemController : NSObject

@property(nonatomic) NSStatusItem *statusItem;
@property(readonly, nonatomic) BOOL showsItem;

- (void)show;
- (void)hide;
- (IBAction)toggleShowing:(id)sender;

- (void)loadSettings;
- (void)saveSettings;

@end

extern NSString *GLAStatusItemControllerToggleNotification;