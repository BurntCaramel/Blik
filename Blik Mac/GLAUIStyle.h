//
//  GLAUIStyle.h
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;
@import QuartzCore;
#import "GLACollection.h"
#import "GLACollectionColor.h"


@interface GLAUIStyle : NSObject

+ (instancetype)activeStyle;


#pragma mark Colors

@property(nonatomic) NSColor *barBackgroundColor;
@property(nonatomic) NSColor *contentBackgroundColor;
@property(nonatomic) NSColor *overlaidBarBackgroundColor;

@property(nonatomic) NSColor *activeBarBackgroundColor;
@property(nonatomic) NSColor *activeBarTextColor;

@property(nonatomic) NSColor *activeButtonHighlightColor;
@property(nonatomic) NSColor *activeButtonBarColor;
@property(nonatomic) NSColor *activeButtonDisabledHighlightColor;

@property(nonatomic) NSColor *primaryButtonBackgroundColor;
@property(nonatomic) NSColor *primaryButtonTextColor;

@property(nonatomic) NSColor *secondaryButtonBackgroundColor;
@property(nonatomic) NSColor *secondaryButtonTextColor;

@property(nonatomic) NSColor *disabledButtonBackgroundColor;

@property(nonatomic) NSColor *lightTextColor;
@property(nonatomic) NSColor *lightTextDisabledColor;
@property(strong, nonatomic) NSColor *(^lightTextColorAtLevelBlock)(GLAUIStyle *style, NSUInteger level);
- (NSColor *)lightTextColorAtLevel:(NSUInteger)level;

@property(nonatomic) NSColor *activeTextColor;
@property(nonatomic) NSColor *activeTextDisabledColor;

@property(nonatomic) NSColor *editedTextColor;
@property(nonatomic) NSColor *editedTextBackgroundColor;

@property(nonatomic) NSColor *instructionsTextColor;
@property(nonatomic) NSColor *instructionsSecondaryTextColor;
@property(nonatomic) NSColor *instructionsHeadingColor;

@property(nonatomic) NSColor *roundedToggleBorderColor;
@property(nonatomic) NSColor *roundedToggleInsideColor;

@property(nonatomic) NSColor *projectTableRowHoverBackgroundColor;
@property(nonatomic) NSColor *projectTableDividerColor;

@property(nonatomic) NSColor *deleteProjectButtonColor;

@property(nonatomic) NSColor *contentTableSelectionColor;

@property(nonatomic) NSColor *splitViewDividerColor;
@property(nonatomic) NSColor *mainDividerColor;


@property(nonatomic) NSColor *pastelLightBlueItemColor;
@property(nonatomic) NSColor *pastelGreenItemColor;
@property(nonatomic) NSColor *pastelPinkyPurpleItemColor;
@property(nonatomic) NSColor *pastelRedItemColor;
@property(nonatomic) NSColor *pastelYellowItemColor;
@property(nonatomic) NSColor *pastelFullRedItemColor;
@property(nonatomic) NSColor *pastelPurplyBlueItemColor;

@property(nonatomic) NSColor *strongRedItemColor;
@property(nonatomic) NSColor *strongYellowItemColor;
@property(nonatomic) NSColor *strongPurpleItemColor;
@property(nonatomic) NSColor *strongBlueItemColor;
@property(nonatomic) NSColor *strongPinkItemColor;
@property(nonatomic) NSColor *strongOrangeItemColor;
@property(nonatomic) NSColor *strongGreenItemColor;

- (NSColor *)colorForCollectionColor:(GLACollectionColor *)color;


@property(nonatomic) NSColor *chooseColorBackgroundColor;


#pragma mark Fonts

@property(nonatomic) NSFont *projectTitleFont;

@property(nonatomic) NSFont *collectionFont;

@property(nonatomic) NSFont *smallReminderFont;
@property(nonatomic) NSFont *smallReminderDueDateFont;

@property(nonatomic) NSFont *highlightedReminderFont;
@property(nonatomic) NSFont *highlightedReminderDueDateFont;

@property(nonatomic) NSFont *buttonFont;
@property(nonatomic) NSFont *labelFont;


#pragma mark Preparing Views

- (void)prepareContentTextField:(NSTextField *)textField;
- (void)prepareTextLabel:(NSTextField *)textField;
- (void)prepareTableTextLabel:(NSTextField *)textField;

- (void)prepareProjectNameField:(NSTextField *)projectNameField;

- (void)prepareInstructionalHeadingLabel:(NSTextField *)textField;
- (void)prepareInstructionalTextLabel:(NSTextField *)textField;
- (void)prepareSecondaryInstructionalTextLabel:(NSTextField *)textField;

- (void)prepareOutlinedTextField:(NSTextField *)textField;
- (void)prepareContentTableView:(NSTableView *)tableView;
- (void)prepareContentStackView:(NSStackView *)stackView;

- (void)prepareCheckButton:(NSButton *)checkButton;

#pragma mark Drawing

- (CGRect)drawingRectOfActiveHighlightForBounds:(CGRect)bounds time:(CGFloat)t;
- (void)drawActiveHighlightForBounds:(CGRect)bounds withColor:(NSColor *)color time:(CGFloat)t;

#pragma mark Windows

- (void)primaryWindowDidBecomeMain:(NSWindow *)window;
- (void)primaryWindowDidResignMain:(NSWindow *)window;

- (void)secondaryWindowDidBecomeMain:(NSWindow *)window;
- (void)secondaryWindowDidResignMain:(NSWindow *)window;

@end
