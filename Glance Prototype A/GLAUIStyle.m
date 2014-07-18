//
//  GLAUIStyle.m
//  Blik
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
		
		NSColor *grayDark = [NSColor colorWithSRGBRed:43.0/255.0 green:43.0/255.0 blue:43.0/255.0 alpha:1.0];
		//NSColor *grayMid = [NSColor colorWithSRGBRed:58.0/255.0 green:58.0/255.0 blue:58.0/255.0 alpha:1.0];
		NSColor *grayMid = [NSColor colorWithSRGBRed:46.0/255.0 green:46.0/255.0 blue:46.0/255.0 alpha:1.0];
		NSColor *whiteAlmost = [NSColor colorWithSRGBRed:252.0/255.0 green:252.0/255.0 blue:252.0/255.0 alpha:1.0];
		NSColor *activeYellow = [NSColor colorWithSRGBRed:236.0/255.0 green:206.0/255.0 blue:4.0/255.0 alpha:1.0];
		NSColor *activeYellowText = [NSColor colorWithSRGBRed:255.0/255.0 green:222.0/255.0 blue:0.0/255.0 alpha:1.0];
		NSColor *deleteRed = [NSColor colorWithCalibratedHue:0.059 saturation:1 brightness:0.983 alpha:1];
		
		NSColor *whiteAlmost30 = [whiteAlmost colorWithAlphaComponent:0.3];
		
		
		//(style.barBackgroundColor) = grayDark;
		//(style.contentBackgroundColor) = grayMid;
		(style.barBackgroundColor) = grayMid;
		(style.contentBackgroundColor) = grayMid;
		
		(style.activeBarBackgroundColor) = activeYellow;
		(style.activeBarTextColor) = grayDark;
		
		(style.activeButtonHighlightColor) = [activeYellow colorWithAlphaComponent:0.91];
		(style.activeButtonDisabledHighlightColor) = whiteAlmost30;
		
		(style.lightTextColor) =  whiteAlmost;
		(style.lightTextDisabledColor) = whiteAlmost30;
		(style.activeTextColor) =  activeYellowText;
		(style.activeTextDisabledColor) = whiteAlmost30;
		
		(style.editedTextColor) = grayDark;
		(style.editedTextBackgroundColor) = whiteAlmost;
		
		(style.toggleBorderColor) = whiteAlmost;
		(style.toggleInsideColor) = whiteAlmost;
		
		(style.projectTableRowHoverBackgroundColor) = [whiteAlmost colorWithAlphaComponent:0.04];
		(style.deleteProjectButtonColor) = deleteRed;
		
		(style.smallReminderFont) = [NSFont fontWithName:@"AvenirNext-MediumItalic" size:13.0];
		(style.highlightedReminderFont) = [NSFont fontWithName:@"AvenirNext-MediumItalic" size:16.0];
	});
	
	return style;
}

@end
