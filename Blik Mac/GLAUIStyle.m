//
//  GLAUIStyle.m
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAUIStyle.h"
#import "NSColor+GLAExtras.h"


#define SRGB255(r255, g255, b255) [NSColor colorWithSRGBRed:((CGFloat)(r255))/255.0 green:((CGFloat)(g255))/255.0 blue:((CGFloat)(b255))/255.0 alpha:1.0]


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
		NSColor *whiteAlmost = [NSColor gla_colorWithSRGBGray:252.0/255.0 alpha:1.0];
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
		
		(style.activeButtonHighlightColor) = activeYellow;
		(style.activeButtonBarColor) = [activeYellow colorWithAlphaComponent:0.91];
		(style.activeButtonDisabledHighlightColor) = whiteAlmost30;
		
		(style.primaryButtonBackgroundColor) = activeYellow;
		(style.primaryButtonTextColor) = grayExtraDark;
		
		//(style.secondaryButtonBackgroundColor) = [whiteAlmost colorWithAlphaComponent:0.075];
		(style.secondaryButtonBackgroundColor) = [whiteAlmost colorWithAlphaComponent:0.0695];
		(style.secondaryButtonTextColor) = whiteAlmost;
		
		(style.lightTextColor) =  whiteAlmost;
		(style.lightTextDisabledColor) = whiteAlmost30;
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
		
		(style.instructionsTextColor) = whiteAlmost;
		(style.instructionsHeadingColor) = activeYellow;
		
		(style.roundedToggleBorderColor) = whiteAlmost;
		(style.roundedToggleInsideColor) = whiteAlmost;
		
		(style.projectTableRowHoverBackgroundColor) = [whiteAlmost colorWithAlphaComponent:0.026];
		(style.projectTableDividerColor) = [whiteAlmost colorWithAlphaComponent:0.057];
		
		(style.deleteProjectButtonColor) = deleteRed;
		
		//(style.contentTableSelectionColor) = activeYellow;
		(style.contentTableSelectionColor) = whiteAlmost30;
		
		(style.splitViewDividerColor) = [whiteAlmost colorWithAlphaComponent:0.057];
		
		
		// Item colors
		(style.pastelLightBlueItemColor) = SRGB255(168, 227, 255);
		(style.pastelGreenItemColor) = SRGB255(191, 218, 126);
		(style.pastelPinkyPurpleItemColor) = SRGB255(228, 203, 255);
		(style.pastelRedItemColor) = SRGB255(255, 197, 132);
		//(style.pastelYellowItemColor) = SRGB255(255, 211, 18);
		(style.pastelYellowItemColor) = SRGB255(255, 227, 102);
		(style.pastelFullRedItemColor) = SRGB255(255, 144, 123);
		(style.pastelPurplyBlueItemColor) = SRGB255(147, 180, 224);
		
		(style.strongRedItemColor) = SRGB255(255, 107, 61);
		(style.strongYellowItemColor) = SRGB255(255, 213, 78);
		(style.strongPurpleItemColor) = SRGB255(204, 142, 255);
		(style.strongBlueItemColor) = SRGB255(49, 187, 255);
		(style.strongPinkItemColor) = SRGB255(255, 109, 180);
		(style.strongOrangeItemColor) = SRGB255(255, 146, 61);
		(style.strongGreenItemColor) = SRGB255(70, 227, 105);
		
		(style.chooseColorBackgroundColor) = grayExtraDark;
		
		// FONTS
		
		NSString *fontNameAvenirNextRegular = @"AvenirNext-Regular";
		NSString *fontNameAvenirNextMedium = @"AvenirNext-Medium";
		NSString *fontNameAvenirNextMediumItalic = @"AvenirNext-MediumItalic";
		NSString *fontNameAvenirNextItalic = @"AvenirNext-Italic";
		
		//(style.projectTitleFont) = [NSFont fontWithName:fontNameAvenirNextItalic size:22.0];
		//(style.projectTitleFont) = [NSFont fontWithName:fontNameAvenirNextMediumItalic size:16.0];
		(style.projectTitleFont) = [NSFont fontWithName:fontNameAvenirNextMediumItalic size:17.0];
		//(style.projectTitleFont) = [NSFont fontWithName:fontNameAvenirNextMedium size:17.0];
		
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
		
		(style.buttonFont) = [NSFont fontWithName:fontNameAvenirNextMedium size:13.0];
		(style.labelFont) = [NSFont fontWithName:fontNameAvenirNextMediumItalic size:13.0];
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

- (NSColor *)colorForCollectionColor:(GLACollectionColor *)color
{
	NSDictionary *colorIdentifierToDisplayColorTable =
	@{
	  GLACollectionColorIdentifierPastelLightBlue: (self.pastelLightBlueItemColor),
	  GLACollectionColorIdentifierPastelGreen: (self.pastelGreenItemColor),
	  GLACollectionColorIdentifierPastelPinkyPurple: (self.pastelPinkyPurpleItemColor),
	  GLACollectionColorIdentifierPastelRed: (self.pastelRedItemColor),
	  GLACollectionColorIdentifierPastelYellow: (self.pastelYellowItemColor),
	  
	  GLACollectionColorIdentifierStrongBlue: (self.strongBlueItemColor),
	  GLACollectionColorIdentifierStrongGreen: (self.strongGreenItemColor),
	  GLACollectionColorIdentifierStrongPurple: (self.strongPurpleItemColor),
	  GLACollectionColorIdentifierStrongRed: (self.strongRedItemColor),
	  GLACollectionColorIdentifierStrongYellow: (self.strongYellowItemColor),
	  GLACollectionColorIdentifierStrongPink: (self.strongPinkItemColor),
	  GLACollectionColorIdentifierStrongOrange: (self.strongOrangeItemColor)
	  };
	
	if (color) {
		NSString *colorIdentifier = (color.identifier);
		NSColor *displayColor = colorIdentifierToDisplayColorTable[colorIdentifier];
		if (displayColor) {
			return displayColor;
		}
	}
	
	return (self.lightTextColor);
}


#pragma mark Preparing Views

- (void)prepareContentTextField:(NSTextField *)textField
{
	(textField.textColor) = (self.lightTextColor);
}

- (void)prepareTextLabel:(NSTextField *)textField
{
	(textField.textColor) = (self.lightTextColor);
}

- (void)prepareProjectNameField:(NSTextField *)projectNameField
{
	(projectNameField.font) = (self.projectTitleFont);
}

- (void)prepareInstructionalTextLabel:(NSTextField *)textField
{
	(textField.textColor) = (self.instructionsTextColor);
	
	NSMutableAttributedString *mutableAttributedString = [(textField.attributedStringValue) mutableCopy];
	NSParagraphStyle *paragraphStyle = [mutableAttributedString attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
	if (paragraphStyle) {
		NSMutableParagraphStyle *mutableParagraphStyle = [paragraphStyle mutableCopy];
		(mutableParagraphStyle.maximumLineHeight) = 19.0;
		[mutableAttributedString addAttribute:NSParagraphStyleAttributeName value:mutableParagraphStyle range:NSMakeRange(0, (mutableAttributedString.length))];
	}
	
	(textField.attributedStringValue) = mutableAttributedString;
}

- (void)prepareInstructionalHeadingLabel:(NSTextField *)textField
{
	(textField.textColor) = (self.instructionsHeadingColor);
}

- (void)prepareOutlinedTextField:(NSTextField *)textField
{
	(textField.wantsLayer) = YES;
	CALayer *layer = (textField.layer);
	
	(layer.borderWidth) = 0.5;
	(layer.borderColor) = [NSColor colorWithCalibratedWhite:0.32 alpha:1.0].CGColor;
	(layer.cornerRadius) = 4.0;
	//[textField noteFocusRingMaskChanged];
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
	
	CGFloat timeWeight = 3.0/16.0;
    CGFloat alphaFraction = (1.0 - timeWeight) + (t * timeWeight);
	color = [color colorWithAlphaComponent:alphaFraction * (color.alphaComponent)];
    
	[color setFill];
	
	NSRectFill(topBarRect);
}

@end
