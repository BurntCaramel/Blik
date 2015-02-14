//
//  GLAPreferencesMainViewController.h
//  Blik
//
//  Created by Patrick Smith on 9/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAPreferencesSection.h"
#import "GLAPreferencesSectionNavigator.h"
#import "GLAPreferencesChooseSectionViewController.h"
#import "GLAEditPermittedApplicationFoldersViewController.h"


@interface GLAPreferencesMainViewController : GLAViewController

@property(nonatomic) GLAPreferencesSectionNavigator *sectionNavigator;

@property(nonatomic) IBOutlet GLAPreferencesChooseSectionViewController *chooseSectionViewController;

@property(nonatomic) GLAEditPermittedApplicationFoldersViewController *editPermittedApplicationFoldersViewController;

@end
