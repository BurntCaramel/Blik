//
//  GLAPreferencesWindowController.h
//  Blik
//
//  Created by Patrick Smith on 6/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAViewController.h"
#import "GLAPreferencesSectionNavigator.h"
#import "GLAPreferencesNavigationViewController.h"
#import "GLAPreferencesMainViewController.h"


@interface GLAPreferencesWindowController : NSWindowController

+ (instancetype)sharedPreferencesWindowController;


@property(nonatomic) GLAPreferencesSectionNavigator *sectionNavigator;

@property(nonatomic) IBOutlet GLAPreferencesNavigationViewController *navigationViewController;
@property(nonatomic) IBOutlet GLAPreferencesMainViewController *mainViewController;

@end
