//
//  GLAUIStyle.h
//  Glance Prototype A
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLAUIStyle : NSObject

+ (instancetype)styleA;

@property (nonatomic) NSColor *barBackgroundColor;
@property (nonatomic) NSColor *contentBackgroundColor;

@property (nonatomic) NSColor *activeBarColor;

@property (nonatomic) NSColor *lightTextColor;
@property (nonatomic) NSColor *activeTextColor;

@property (nonatomic) NSFont *smallReminderFont;
@property (nonatomic) NSFont *highlightedReminderFont;

@property (nonatomic) NSFont *itemFont;
@property (nonatomic) NSFont *projectTitleFont;

@property (nonatomic) NSFont *buttonFont;

@end
