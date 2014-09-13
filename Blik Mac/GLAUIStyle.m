//
//  GLAUIStyle.m
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAUIStyle.h"
#import "NSColor+GLAExtras.h"


@implementation GLAUIStyle

+ (instancetype)activeStyle
{
	static GLAUIStyle *style;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		style = [self new];
		
		// COLORS
		
#if 0
		//NSColor *grayDark = [NSColor colorWithSRGBRed:43.0/255.0 green:43.0/255.0 blue:43.0/255.0 alpha:1.0];
		NSColor *grayDark = [NSColor gla_colorWithSRGBGray:50.0/255.0 alpha:1.0];
		//NSColor *grayExtraDark = [NSColor colorWithSRGBRed:58.0/255.0 green:58.0/255.0 blue:58.0/255.0 alpha:1.0];
		NSColor *grayExtraDark = [NSColor gla_colorWithSRGBGray:46.0/255.0 alpha:1.0];
#else
		NSColor *grayDark = [NSColor gla_colorWithSRGBGray:43.0/255.0 alpha:1.0];
		NSColor *grayExtraDark = [NSColor gla_colorWithSRGBGray:41.0/255.0 alpha:1.0];
#endif
		NSColor *whiteAlmost = [NSColor colorWithSRGBRed:252.0/255.0 green:252.0/255.0 blue:252.0/255.0 alpha:1.0];
		NSColor *activeYellow = [NSColor colorWithSRGBRed:236.0/255.0 green:206.0/255.0 blue:4.0/255.0 alpha:1.0];
		NSColor *activeYellowText = [NSColor colorWithSRGBRed:255.0/255.0 green:222.0/255.0 blue:0.0/255.0 alpha:1.0];
		NSColor *deleteRed = [NSColor colorWithCalibratedHue:0.059 saturation:1 brightness:0.983 alpha:1];
		
		NSColor *whiteAlmost30 = [whiteAlmost colorWithAlphaComponent:0.3];
		
		
		//(style.barBackgroundColor) = grayDark;
		//(style.contentBackgroundColor) = grayExtraDark;
		(style.barBackgroundColor) = grayExtraDark;
		(style.contentBackgroundColor) = grayDark;
		
		(style.activeBarBackgroundColor) = activeYellow;
		(style.activeBarTextColor) = grayDark;
		
		(style.activeButtonHighlightColor) = [activeYellow colorWithAlphaComponent:0.91];
		(style.activeButtonDisabledHighlightColor) = whiteAlmost30;
		
		(style.lightTextColor) =  whiteAlmost;
		(style.lightTextDisabledColor) = whiteAlmost30;
		//(style.lightTextSecondaryColor) = [whiteAlmost colorWithAlphaComponent:0.77];
		(style.lightTextColorAtLevelBlock) = ^ (GLAUIStyle *style, NSUInteger level) {
			// Reduce by 1/10 for each level
			CGFloat reduction = 1.0/8.0 * (CGFloat)level;
			CGFloat minAlpha = 0.5;
			CGFloat alpha = fmax(1.0 - reduction, minAlpha);
			
			return [(style.lightTextColor) colorWithAlphaComponent:alpha];
		};
		
		(style.activeTextColor) =  activeYellowText;
		(style.activeTextDisabledColor) = whiteAlmost30;
		
		(style.editedTextColor) = grayDark;
		(style.editedTextBackgroundColor) = whiteAlmost;
		
		(style.toggleBorderColor) = whiteAlmost;
		(style.toggleInsideColor) = whiteAlmost;
		
		(style.projectTableRowHoverBackgroundColor) = [whiteAlmost colorWithAlphaComponent:0.026];
		(style.projectTableDividerColor) = [whiteAlmost colorWithAlphaComponent:0.057];
		
		(style.deleteProjectButtonColor) = deleteRed;
		
		//(style.contentTableSelectionColor) = activeYellow;
		(style.contentTableSelectionColor) = whiteAlmost30;
		
		(style.splitViewDividerColor) = [whiteAlmost colorWithAlphaComponent:0.057];
		
		// Item colors
		(style.lightBlueItemColor) = [NSColor colorWithSRGBRed:168.0/255.0 green:227.0/255.0 blue:255.0/255.0 alpha:1.0];
		(style.greenItemColor) = [NSColor colorWithSRGBRed:191.0/255.0 green:218.0/255.0 blue:126.0/255.0 alpha:1.0];
		(style.pinkyPurpleItemColor) = [NSColor colorWithSRGBRed:228.0/255.0 green:203.0/255.0 blue:255.0/255.0 alpha:1.0];
		(style.reddishItemColor) = [NSColor colorWithSRGBRed:255.0/255.0 green:197.0/255.0 blue:132.0/255.0 alpha:1.0];
		//(style.yellowItemColor) = [NSColor colorWithSRGBRed:255.0/255.0 green:211.0/255.0 blue:18.0/255.0 alpha:1.0];
		(style.yellowItemColor) = [NSColor colorWithSRGBRed:255.0/255.0 green:227.0/255.0 blue:102.0/255.0 alpha:1.0];
		
		// FONTS
		
		NSString *fontNameAvenirNextRegular = @"AvenirNext-Regular";
		NSString *fontNameAvenirNextMedium = @"AvenirNext-Medium";
		NSString *fontNameAvenirNextMediumItalic = @"AvenirNext-MediumItalic";
		NSString *fontNameAvenirNextItalic = @"AvenirNext-Italic";
		
		(style.projectTitleFont) = [NSFont fontWithName:fontNameAvenirNextMediumItalic size:18.0];
		
#if 0
		(style.smallReminderFont) = [NSFont fontWithName:fontNameAvenirNextMedium size:13.0];
		(style.smallReminderDueDateFont) = [NSFont fontWithName:fontNameAvenirNextRegular size:13.0];
		
		(style.highlightedReminderFont) = [NSFont fontWithName:fontNameAvenirNextMedium size:16.0];
		(style.highlightedReminderDueDateFont) = [NSFont fontWithName:fontNameAvenirNextRegular size:16.0];
#elif 1
		(style.smallReminderFont) = [NSFont fontWithName:fontNameAvenirNextMedium size:13.0];
		(style.smallReminderDueDateFont) = [NSFont fontWithName:fontNameAvenirNextMedium size:11.0];
		
		(style.highlightedReminderFont) = [NSFont fontWithName:fontNameAvenirNextMedium size:16.0];
		(style.highlightedReminderDueDateFont) = [NSFont fontWithName:fontNameAvenirNextMedium size:11.0];
#else
		(style.smallReminderFont) = [NSFont fontWithName:fontNameAvenirNextMedium size:13.0];
		(style.smallReminderDueDateFont) = [NSFont fontWithName:fontNameAvenirNextMediumItalic size:13.0];
		
		(style.highlightedReminderFont) = [NSFont fontWithName:fontNameAvenirNextMedium size:16.0];
		(style.highlightedReminderDueDateFont) = [NSFont fontWithName:fontNameAvenirNextMediumItalic size:16.0];
#endif
	});
	
	return style;
}


#pragma mark Colors

- (NSColor *)lightTextColorAtLevel:(NSUInteger)level
{
	NSColor *(^lightTextColorAtLevelBlock)(GLAUIStyle *style, NSUInteger level) = (self.lightTextColorAtLevelBlock);
	if (lightTextColorAtLevelBlock) {
		return lightTextColorAtLevelBlock(self, level);
	}
	else {
		return (self.lightTextColor);
	}
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


#pragma mark Preparing Views

- (void)prepareContentTextField:(NSTextField *)textField
{
	(textField.textColor) = (self.lightTextColor);
}

- (void)prepareContentTableView:(NSTableView *)tableView
{
	NSColor *backgroundColor = (self.contentBackgroundColor);
	(tableView.backgroundColor) = backgroundColor;
	(tableView.enclosingScrollView.backgroundColor) = backgroundColor;
}


#pragma mark Drawing

- (CGRect)rectOfActiveHighlightForBounds:(CGRect)bounds time:(CGFloat)t
{
	CGFloat height = 6.0 * t;
	CGRect topBarRect, elseRect;
	CGRectDivide(bounds, &topBarRect, &elseRect, height, CGRectMinYEdge);
	
	return topBarRect;
}

- (CGRect)drawingRectOfActiveHighlightForBounds:(CGRect)bounds time:(CGFloat)t
{
	return [self rectOfActiveHighlightForBounds:bounds time:t];
}

- (void)drawActiveHighlightForBounds:(CGRect)bounds withColor:(NSColor *)color time:(CGFloat)t
{
	CGRect topBarRect = [self rectOfActiveHighlightForBounds:bounds time:t];
	
	//color = [color colorWithAlphaComponent:t * (color.alphaComponent)];
	[color setFill];
	
	NSRectFill(topBarRect);
}

@end
