//
//  GLAPreferencesSectionNavigator.h
//  Blik
//
//  Created by Patrick Smith on 10/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLAPreferencesSection.h"


@interface GLAPreferencesSectionNavigator : NSObject

@property(readonly, copy, nonatomic) NSString *currentSectionIdentifier;
@property(readonly, copy, nonatomic) NSString *previousSectionIdentifier;

- (void)goToSectionWithIdentifier:(NSString *)newSectionIdentifier;

@end

extern NSString *GLAPreferencesSectionNavigatorCurrentSectionDidChangeNotificiation;
