//
//  GLAProjectsListMenuController.h
//  Blik
//
//  Created by Patrick Smith on 8/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;


@interface GLAProjectsListMenuController : NSObject <NSMenuDelegate>

- (instancetype)initWithMenu:(NSMenu *)menu;

@property(readonly, nonatomic) NSMenu *menu;

@end
