//
//  GLAProjectItem.h
//  Blik
//
//  Created by Patrick Smith on 18/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;


typedef NS_ENUM(NSInteger, GLAProjectItemColor) {
	GLAProjectItemColorUnknown,
	GLAProjectItemColorLightBlue,
	GLAProjectItemColorGreen,
	GLAProjectItemColorPinkyPurple,
	GLAProjectItemColorRed,
	GLAProjectItemColorYellow
};


@interface GLAProjectItem : NSObject

@property(copy, nonatomic) NSString *title;

@property(nonatomic) GLAProjectItemColor colorIdentifier;


+ (instancetype)dummyItemWithTitle:(NSString *)title colorIdentifier:(GLAProjectItemColor)colorIdentifier;

@end
