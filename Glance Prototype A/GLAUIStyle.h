//
//  GLAUIStyle.h
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;

@interface GLAUIStyle : NSObject

+ (instancetype)styleA;


#pragma mark Colors

@property (nonatomic) NSColor *barBackgroundColor;
@property (nonatomic) NSColor *contentBackgroundColor;

@property (nonatomic) NSColor *activeBarBackgroundColor;
@property (nonatomic) NSColor *activeBarTextColor;

@property (nonatomic) NSColor *activeButtonHighlightColor;
@property (nonatomic) NSColor *activeButtonDisabledHighlightColor;

@property (nonatomic) NSColor *lightTextColor;
@property (nonatomic) NSColor *lightTextDisabledColor;
@property (nonatomic) NSColor *activeTextColor;
@property (nonatomic) NSColor *activeTextDisabledColor;

@property (nonatomic) NSColor *editedTextColor;
@property (nonatomic) NSColor *editedTextBackgroundColor;

@property (nonatomic) NSColor *toggleBorderColor;
@property (nonatomic) NSColor *toggleInsideColor;

@property (nonatomic) NSColor *projectTableRowHoverBackgroundColor;

@property (nonatomic) NSColor *deleteProjectButtonColor;


@property (nonatomic) NSColor *lightBlueItemColor;
@property (nonatomic) NSColor *greenItemColor;
@property (nonatomic) NSColor *pinkyPurpleItemColor;
@property (nonatomic) NSColor *reddishItemColor;
@property (nonatomic) NSColor *yellowItemColor;

#pragma mark Fonts

@property (nonatomic) NSFont *smallReminderFont;
@property (nonatomic) NSFont *highlightedReminderFont;

@property (nonatomic) NSFont *itemFont;
@property (nonatomic) NSFont *projectTitleFont;

@property (nonatomic) NSFont *buttonFont;

@end
