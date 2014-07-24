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
		
		// COLORS
		
		//NSColor *grayDark = [NSColor colorWithSRGBRed:43.0/255.0 green:43.0/255.0 blue:43.0/255.0 alpha:1.0];
		NSColor *grayDark = [NSColor colorWithSRGBRed:50.0/255.0 green:50.0/255.0 blue:50.0/255.0 alpha:1.0];
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
		(style.contentBackgroundColor) = grayDark;
		
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
		
		// Item colors
		(style.lightBlueItemColor) = [NSColor colorWithSRGBRed:168.0/255.0 green:227.0/255.0 blue:255.0/255.0 alpha:1.0];
		(style.greenItemColor) = [NSColor colorWithSRGBRed:191.0/255.0 green:218.0/255.0 blue:126.0/255.0 alpha:1.0];
		(style.pinkyPurpleItemColor) = [NSColor colorWithSRGBRed:228.0/255.0 green:203.0/255.0 blue:255.0/255.0 alpha:1.0];
		(style.reddishItemColor) = [NSColor colorWithSRGBRed:255.0/255.0 green:197.0/255.0 blue:132.0/255.0 alpha:1.0];
		(style.yellowItemColor) = [NSColor colorWithSRGBRed:255.0/255.0 green:211.0/255.0 blue:18.0/255.0 alpha:1.0];
		
		// FONTS
		
		(style.smallReminderFont) = [NSFont fontWithName:@"AvenirNext-MediumItalic" size:13.0];
		(style.highlightedReminderFont) = [NSFont fontWithName:@"AvenirNext-MediumItalic" size:16.0];
	});
	
	return style;
}


- (NSColor *)colorForProjectItemColorIdentifier:(GLACollectionColor)colorIdentifier
{
	switch (colorIdentifier) {
		case GLACollectionColorLightBlue:
			return (self.lightBlueItemColor);
		
		case GLACollectionColorGreen:
			return (self.greenItemColor);
		
		case GLACollectionColorPinkyPurple:
			return (self.pinkyPurpleItemColor);
		
		case GLACollectionColorRed:
			return (self.reddishItemColor);
		
		case GLACollectionColorYellow:
			return (self.yellowItemColor);
			
		default:
			return (self.lightTextColor);
	}
}

@end
