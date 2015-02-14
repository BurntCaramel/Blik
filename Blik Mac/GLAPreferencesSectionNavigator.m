//
//  GLAPreferencesSectionNavigator.m
//  Blik
//
//  Created by Patrick Smith on 10/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAPreferencesSectionNavigator.h"


@interface GLAPreferencesSectionNavigator ()

@property(readwrite, copy, nonatomic) NSString *currentSectionIdentifier;
@property(readwrite, copy, nonatomic) NSString *previousSectionIdentifier;

@end

@implementation GLAPreferencesSectionNavigator

- (void)goToSectionWithIdentifier:(NSString *)newSectionIdentifier
{
	NSString *previousSectionIdentifier = (self.currentSectionIdentifier);
	
	if ((previousSectionIdentifier != nil) && [newSectionIdentifier isEqualToString:previousSectionIdentifier]) {
		return;
	}
	
	(self.previousSectionIdentifier) = previousSectionIdentifier;
	(self.currentSectionIdentifier) = newSectionIdentifier;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAPreferencesSectionNavigatorCurrentSectionDidChangeNotificiation object:self];
}

@end

NSString *GLAPreferencesSectionNavigatorCurrentSectionDidChangeNotificiation = @"GLAPreferencesSectionNavigatorCurrentSectionDidChangeNotificiation";
