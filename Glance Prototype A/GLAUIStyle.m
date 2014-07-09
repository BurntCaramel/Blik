//
//  GLAUIStyle.m
//  Glance Prototype A
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAUIStyle.h"

@implementation GLAUIStyle

+ (instancetype)styleA
{
	static GLAUIStyle *style;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		style = [self new];
		
		(style.barBackgroundColor) = [NSColor colorWithCalibratedWhite:0.168 alpha:1];
		(style.contentBackgroundColor) = [NSColor colorWithCalibratedWhite:0.227 alpha:1];
		
		(style.activeBarColor) = [NSColor colorWithCalibratedHue:0.14 saturation:0.804 brightness:0.921 alpha:1];
		
		(style.lightTextColor) = [NSColor colorWithCalibratedHue:0.323 saturation:0 brightness:0.988 alpha:1];
		(style.activeTextColor) =  [NSColor colorWithCalibratedHue:0.146 saturation:1 brightness:1 alpha:1];
		
		(style.smallReminderFont) = [NSFont fontWithName:@"AvenirNext-MediumItalic" size:13.0];
		(style.highlightedReminderFont) = [NSFont fontWithName:@"AvenirNext-MediumItalic" size:16.0];
	});
	
	return style;
}

@end
