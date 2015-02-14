//
//  GLAPreferencesNavigationViewController.h
//  Blik
//
//  Created by Patrick Smith on 10/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAPreferencesSectionNavigator.h"
#import "GLAButton.h"


@interface GLAPreferencesNavigationViewController : GLAViewController

@property(nonatomic) GLAPreferencesSectionNavigator *sectionNavigator;

@property(nonatomic) IBOutlet GLAButton *templateButton;

@end
