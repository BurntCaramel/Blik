//
//  GLAUIStyle.h
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
@import QuartzCore;
#import "GLACollection.h"


@interface GLAUIStyle : NSObject

+ (instancetype)activeStyle;


#pragma mark Colors

@property (nonatomic) NSColor *barBackgroundColor;
@property (nonatomic) NSColor *contentBackgroundColor;

@property (nonatomic) NSColor *activeBarBackgroundColor;
@property (nonatomic) NSColor *activeBarTextColor;

@property (nonatomic) NSColor *activeButtonHighlightColor;
@property (nonatomic) NSColor *activeButtonDisabledHighlightColor;

@property (nonatomic) NSColor *lightTextColor;
@property (nonatomic) NSColor *lightTextDisabledColor;
@property (strong, nonatomic) NSColor *(^lightTextColorAtLevelBlock)(GLAUIStyle *style, NSUInteger level);
- (NSColor *)lightTextColorAtLevel:(NSUInteger)level;

@property (nonatomic) NSColor *activeTextColor;
@property (nonatomic) NSColor *activeTextDisabledColor;

@property (nonatomic) NSColor *editedTextColor;
@property (nonatomic) NSColor *editedTextBackgroundColor;

@property (nonatomic) NSColor *toggleBorderColor;
@property (nonatomic) NSColor *toggleInsideColor;

@property (nonatomic) NSColor *projectTableRowHoverBackgroundColor;
@property (nonatomic) NSColor *projectTableDividerColor;

@property (nonatomic) NSColor *deleteProjectButtonColor;

@property (nonatomic) NSColor *contentTableSelectionColor;

@property (nonatomic) NSColor *splitViewDividerColor;


@property (nonatomic) NSColor *lightBlueItemColor;
@property (nonatomic) NSColor *greenItemColor;
@property (nonatomic) NSColor *pinkyPurpleItemColor;
@property (nonatomic) NSColor *reddishItemColor;
@property (nonatomic) NSColor *yellowItemColor;

- (NSColor *)colorForProjectItemColorIdentifier:(GLACollectionColor)colorIdentifier;


#pragma mark Fonts

@property (nonatomic) NSFont *projectTitleFont;

@property (nonatomic) NSFont *collectionFont;

@property (nonatomic) NSFont *smallReminderFont;
@property (nonatomic) NSFont *smallReminderDueDateFont;

@property (nonatomic) NSFont *highlightedReminderFont;
@property (nonatomic) NSFont *highlightedReminderDueDateFont;

@property (nonatomic) NSFont *buttonFont;


#pragma mark Preparing Views

- (void)prepareContentTextField:(NSTextField *)textField;
- (void)prepareContentTableView:(NSTableView *)tableView;


#pragma mark Drawing

- (CGRect)drawingRectOfActiveHighlightForBounds:(CGRect)bounds time:(CGFloat)t;
- (void)drawActiveHighlightForBounds:(CGRect)bounds withColor:(NSColor *)color time:(CGFloat)t;

@end
